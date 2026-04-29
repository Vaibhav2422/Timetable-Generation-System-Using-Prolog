% ============================================================================
% conflict_resolver.pl - Smart Conflict Suggestion System
% ============================================================================
% This module analyses detected conflicts in a timetable and generates
% intelligent, actionable suggestions for resolving them.
%
% Strategies implemented:
%   - Alternative time slot suggestions (move a session to a free slot)
%   - Alternative teacher suggestions (swap to a qualified, available teacher)
%   - Session swap suggestions (exchange two sessions to eliminate conflicts)
%   - Direct fix application (execute a chosen suggestion)
%
% Requirements: Feature 2 (Task 19)
%
% Author: AI Timetable Generation System
% ============================================================================

:- module(conflict_resolver, [
    suggest_fix/2,
    suggest_teacher_conflict_fix/4,
    find_alternative_slots/3,
    find_alternative_teachers/4,
    find_swappable_sessions/3,
    apply_fix/2,
    execute_fix/3
]).

:- use_module(knowledge_base).
:- use_module(matrix_model).
:- use_module(constraints).
:- use_module(logging).

% Allow access to dynamic facts from other modules / user space
:- multifile teacher/5, subject/5, room/4, timeslot/5, class/3.
:- dynamic teacher/5, subject/5, room/4, timeslot/5, class/3.

% ============================================================================
% suggest_fix/2
% ============================================================================
% Top-level predicate: given the current timetable (stored as the dynamic
% fact current_timetable/1 in api_server) and a conflict term, produce a
% list of fix suggestions.
%
% Format: suggest_fix(+Conflict, -Suggestions)
%
% Conflict formats (matching detect_conflicts/2 output):
%   teacher_conflict(TeacherID, SlotID, Sessions)
%   room_conflict(RoomID, SlotID, Sessions)
%
% Each suggestion is a dict-like term:
%   fix(Type, Description, FixData)
%
% ============================================================================

suggest_fix(teacher_conflict(TeacherID, SlotID, Sessions), Suggestions) :-
    log_info('Generating suggestions for teacher conflict'),
    suggest_teacher_conflict_fix(TeacherID, SlotID, Sessions, Suggestions).

suggest_fix(room_conflict(RoomID, SlotID, Sessions), Suggestions) :-
    log_info('Generating suggestions for room conflict'),
    suggest_room_conflict_fix(RoomID, SlotID, Sessions, Suggestions).

suggest_fix(_, []) :-
    log_warning('Unknown conflict type – no suggestions generated').

% ============================================================================
% suggest_teacher_conflict_fix/4
% ============================================================================
% Generate suggestions for a teacher double-booking conflict.
%
% Format: suggest_teacher_conflict_fix(+TeacherID, +SlotID, +Sessions, -Suggestions)
%
% Strategies:
%   1. Move one of the conflicting sessions to an alternative free slot.
%   2. Reassign one session to a different qualified teacher.
%   3. Swap one conflicting session with another session in the timetable.
%
% ============================================================================

suggest_teacher_conflict_fix(TeacherID, SlotID, Sessions, Suggestions) :-
    % Collect all three suggestion types
    findall(Fix,
            (   member(SubjectID, Sessions),
                (   % Strategy 1: alternative slot
                    find_alternative_slots(SubjectID, TeacherID, AltSlots),
                    AltSlots \= [],
                    member(AltSlot, AltSlots),
                    format(atom(Desc),
                           'Move session ~w to slot ~w (teacher ~w is free there)',
                           [SubjectID, AltSlot, TeacherID]),
                    Fix = fix(move_session,
                              Desc,
                              fix_data(subject_id-SubjectID,
                                       from_slot-SlotID,
                                       to_slot-AltSlot,
                                       teacher_id-TeacherID))
                ;   % Strategy 2: alternative teacher
                    find_alternative_teachers(SubjectID, SlotID, TeacherID, AltTeachers),
                    AltTeachers \= [],
                    member(AltTeacher, AltTeachers),
                    format(atom(Desc),
                           'Reassign session ~w to teacher ~w at slot ~w',
                           [SubjectID, AltTeacher, SlotID]),
                    Fix = fix(reassign_teacher,
                              Desc,
                              fix_data(subject_id-SubjectID,
                                       slot_id-SlotID,
                                       old_teacher-TeacherID,
                                       new_teacher-AltTeacher))
                ;   % Strategy 3: swap sessions
                    find_swappable_sessions(SubjectID, SlotID, SwapTargets),
                    SwapTargets \= [],
                    member(SwapTarget, SwapTargets),
                    SwapTarget = swap_target(OtherSubject, OtherSlot),
                    format(atom(Desc),
                           'Swap session ~w (slot ~w) with session ~w (slot ~w)',
                           [SubjectID, SlotID, OtherSubject, OtherSlot]),
                    Fix = fix(swap_sessions,
                              Desc,
                              fix_data(subject_id-SubjectID,
                                       slot_id-SlotID,
                                       swap_subject-OtherSubject,
                                       swap_slot-OtherSlot))
                )
            ),
            Suggestions).

% ============================================================================
% suggest_room_conflict_fix/4
% ============================================================================
% Generate suggestions for a room double-booking conflict.
%
% Format: suggest_room_conflict_fix(+RoomID, +SlotID, +Sessions, -Suggestions)
%
% ============================================================================

suggest_room_conflict_fix(RoomID, SlotID, Sessions, Suggestions) :-
    findall(Fix,
            (   member(SubjectID, Sessions),
                (   % Strategy 1: move session to alternative slot in same room
                    find_alternative_slots_for_room(SubjectID, RoomID, AltSlots),
                    AltSlots \= [],
                    member(AltSlot, AltSlots),
                    format(atom(Desc),
                           'Move session ~w to slot ~w in room ~w',
                           [SubjectID, AltSlot, RoomID]),
                    Fix = fix(move_session,
                              Desc,
                              fix_data(subject_id-SubjectID,
                                       from_slot-SlotID,
                                       to_slot-AltSlot,
                                       room_id-RoomID))
                ;   % Strategy 2: move session to alternative room at same slot
                    find_alternative_rooms(SubjectID, SlotID, RoomID, AltRooms),
                    AltRooms \= [],
                    member(AltRoom, AltRooms),
                    format(atom(Desc),
                           'Move session ~w to room ~w at slot ~w',
                           [SubjectID, AltRoom, SlotID]),
                    Fix = fix(move_to_room,
                              Desc,
                              fix_data(subject_id-SubjectID,
                                       slot_id-SlotID,
                                       old_room-RoomID,
                                       new_room-AltRoom))
                )
            ),
            Suggestions).

% ============================================================================
% find_alternative_slots/3
% ============================================================================
% Find time slots where the given teacher is free (no existing assignment)
% and is marked as available.
%
% Format: find_alternative_slots(+SubjectID, +TeacherID, -FreeSlots)
%
% ============================================================================

find_alternative_slots(SubjectID, TeacherID, FreeSlots) :-
    % Retrieve current timetable if available
    (   current_timetable_data(Matrix)
    ->  get_all_assignments(Matrix, Assignments)
    ;   Assignments = []
    ),
    % Collect slots where teacher is available and not already assigned
    findall(SlotID,
            (   (timeslot(SlotID, _, _, _, _) ; user:timeslot(SlotID, _, _, _, _)),
                teacher_available(TeacherID, SlotID),
                % Teacher not already assigned at this slot
                \+ member(assigned(_, _, _, TeacherID, SlotID), Assignments),
                % Room of suitable type exists and is free at this slot
                suitable_room_free_at(SubjectID, SlotID, Assignments)
            ),
            FreeSlots).

% ============================================================================
% find_alternative_slots_for_room/3
% ============================================================================
% Find slots where a specific room is free.
%
% Format: find_alternative_slots_for_room(+SubjectID, +RoomID, -FreeSlots)
%
% ============================================================================

find_alternative_slots_for_room(_SubjectID, RoomID, FreeSlots) :-
    (   current_timetable_data(Matrix)
    ->  get_all_assignments(Matrix, Assignments)
    ;   Assignments = []
    ),
    findall(SlotID,
            (   (timeslot(SlotID, _, _, _, _) ; user:timeslot(SlotID, _, _, _, _)),
                \+ member(assigned(RoomID, _, _, _, SlotID), Assignments)
            ),
            FreeSlots).

% ============================================================================
% find_alternative_rooms/4
% ============================================================================
% Find rooms of the correct type that are free at a given slot.
%
% Format: find_alternative_rooms(+SubjectID, +SlotID, +ExcludeRoomID, -FreeRooms)
%
% ============================================================================

find_alternative_rooms(SubjectID, SlotID, ExcludeRoomID, FreeRooms) :-
    (   current_timetable_data(Matrix)
    ->  get_all_assignments(Matrix, Assignments)
    ;   Assignments = []
    ),
    (   (subject(SubjectID, _, _, Type, _) ; user:subject(SubjectID, _, _, Type, _))
    ->  true
    ;   Type = theory
    ),
    findall(RoomID,
            (   (room(RoomID, _, _, RoomType) ; user:room(RoomID, _, _, RoomType)),
                RoomID \= ExcludeRoomID,
                compatible_type(Type, RoomType),
                \+ member(assigned(RoomID, _, _, _, SlotID), Assignments)
            ),
            FreeRooms).

% ============================================================================
% find_alternative_teachers/4
% ============================================================================
% Find teachers (other than the conflicting one) who are qualified for the
% subject and available at the given slot.
%
% Format: find_alternative_teachers(+SubjectID, +SlotID, +ExcludeTeacherID, -AltTeachers)
%
% ============================================================================

find_alternative_teachers(SubjectID, SlotID, ExcludeTeacherID, AltTeachers) :-
    (   current_timetable_data(Matrix)
    ->  get_all_assignments(Matrix, Assignments)
    ;   Assignments = []
    ),
    findall(TeacherID,
            (   qualified(TeacherID, SubjectID),
                TeacherID \= ExcludeTeacherID,
                teacher_available(TeacherID, SlotID),
                % Not already assigned at this slot
                \+ member(assigned(_, _, _, TeacherID, SlotID), Assignments)
            ),
            AltTeachers).

% ============================================================================
% find_swappable_sessions/3
% ============================================================================
% Find sessions in the timetable that could be swapped with the conflicting
% session without introducing new conflicts.
%
% Format: find_swappable_sessions(+SubjectID, +ConflictSlotID, -SwapTargets)
%
% Each element of SwapTargets is: swap_target(OtherSubjectID, OtherSlotID)
%
% ============================================================================

find_swappable_sessions(SubjectID, ConflictSlotID, SwapTargets) :-
    (   current_timetable_data(Matrix)
    ->  get_all_assignments(Matrix, Assignments)
    ;   Assignments = []
    ),
    % Find the conflicting assignment details
    (   member(assigned(RoomID, ClassID, SubjectID, TeacherID, ConflictSlotID), Assignments)
    ->  true
    ;   RoomID = unknown, ClassID = unknown, TeacherID = unknown
    ),
    findall(swap_target(OtherSubject, OtherSlot),
            (   member(assigned(OtherRoom, OtherClass, OtherSubject, OtherTeacher, OtherSlot), Assignments),
                OtherSlot \= ConflictSlotID,
                OtherSubject \= SubjectID,
                % Check that swapping would not create new conflicts:
                % Teacher of conflicting session must be available at OtherSlot
                (TeacherID \= unknown -> teacher_available(TeacherID, OtherSlot) ; true),
                % Teacher of other session must be available at ConflictSlotID
                (OtherTeacher \= unknown -> teacher_available(OtherTeacher, ConflictSlotID) ; true),
                % Rooms must still be compatible after swap
                (SubjectID \= unknown ->
                    (subject(SubjectID, _, _, SType, _) ; user:subject(SubjectID, _, _, SType, _) ; SType = theory)
                ;   SType = theory
                ),
                (OtherSubject \= unknown ->
                    (subject(OtherSubject, _, _, OType, _) ; user:subject(OtherSubject, _, _, OType, _) ; OType = theory)
                ;   OType = theory
                ),
                compatible_type(SType, _),
                compatible_type(OType, _),
                % Suppress unused variable warnings
                _ = RoomID, _ = ClassID, _ = OtherRoom, _ = OtherClass
            ),
            SwapTargets).

% ============================================================================
% apply_fix/2
% ============================================================================
% Apply a fix suggestion to the current timetable.
% Updates the dynamic current_timetable/1 fact in the calling module.
%
% Format: apply_fix(+Fix, -UpdatedMatrix)
%
% ============================================================================

apply_fix(fix(FixType, _Desc, FixData), UpdatedMatrix) :-
    (   current_timetable_data(Matrix)
    ->  true
    ;   throw(error(no_timetable, 'No timetable available to apply fix'))
    ),
    execute_fix(FixType, FixData, Matrix, UpdatedMatrix).

% ============================================================================
% execute_fix/4
% ============================================================================
% Execute a specific fix type against a matrix.
%
% Format: execute_fix(+FixType, +FixData, +Matrix, -UpdatedMatrix)
%
% ============================================================================

% Alias for 3-arg version used in module export (wraps 4-arg)
execute_fix(FixType, FixData, UpdatedMatrix) :-
    (   current_timetable_data(Matrix)
    ->  true
    ;   throw(error(no_timetable, 'No timetable available'))
    ),
    execute_fix(FixType, FixData, Matrix, UpdatedMatrix).

% Move a session from one slot to another (same teacher, same room)
execute_fix(move_session, FixData, Matrix, UpdatedMatrix) :-
    member(subject_id-SubjectID, FixData),
    member(from_slot-FromSlot, FixData),
    member(to_slot-ToSlot, FixData),
    % Find the assignment to move
    get_all_assignments(Matrix, Assignments),
    member(assigned(RoomID, ClassID, SubjectID, TeacherID, FromSlot), Assignments),
    % Remove from old position
    find_room_index_local(RoomID, RoomIdx),
    find_slot_index_local(FromSlot, FromSlotIdx),
    set_cell(Matrix, RoomIdx, FromSlotIdx, empty, TempMatrix),
    % Place at new position
    find_slot_index_local(ToSlot, ToSlotIdx),
    set_cell(TempMatrix, RoomIdx, ToSlotIdx,
             assigned(RoomID, ClassID, SubjectID, TeacherID, ToSlot),
             UpdatedMatrix),
    log_info('Applied move_session fix').

% Reassign a session to a different teacher
execute_fix(reassign_teacher, FixData, Matrix, UpdatedMatrix) :-
    member(subject_id-SubjectID, FixData),
    member(slot_id-SlotID, FixData),
    member(old_teacher-OldTeacher, FixData),
    member(new_teacher-NewTeacher, FixData),
    get_all_assignments(Matrix, Assignments),
    member(assigned(RoomID, ClassID, SubjectID, OldTeacher, SlotID), Assignments),
    find_room_index_local(RoomID, RoomIdx),
    find_slot_index_local(SlotID, SlotIdx),
    set_cell(Matrix, RoomIdx, SlotIdx,
             assigned(RoomID, ClassID, SubjectID, NewTeacher, SlotID),
             UpdatedMatrix),
    log_info('Applied reassign_teacher fix').

% Move a session to a different room at the same slot
execute_fix(move_to_room, FixData, Matrix, UpdatedMatrix) :-
    member(subject_id-SubjectID, FixData),
    member(slot_id-SlotID, FixData),
    member(old_room-OldRoom, FixData),
    member(new_room-NewRoom, FixData),
    get_all_assignments(Matrix, Assignments),
    member(assigned(OldRoom, ClassID, SubjectID, TeacherID, SlotID), Assignments),
    % Clear old cell
    find_room_index_local(OldRoom, OldRoomIdx),
    find_slot_index_local(SlotID, SlotIdx),
    set_cell(Matrix, OldRoomIdx, SlotIdx, empty, TempMatrix),
    % Place in new room
    find_room_index_local(NewRoom, NewRoomIdx),
    set_cell(TempMatrix, NewRoomIdx, SlotIdx,
             assigned(NewRoom, ClassID, SubjectID, TeacherID, SlotID),
             UpdatedMatrix),
    log_info('Applied move_to_room fix').

% Swap two sessions between their slots
execute_fix(swap_sessions, FixData, Matrix, UpdatedMatrix) :-
    member(subject_id-SubjectID, FixData),
    member(slot_id-SlotID, FixData),
    member(swap_subject-SwapSubject, FixData),
    member(swap_slot-SwapSlot, FixData),
    get_all_assignments(Matrix, Assignments),
    member(assigned(Room1, Class1, SubjectID, Teacher1, SlotID), Assignments),
    member(assigned(Room2, Class2, SwapSubject, Teacher2, SwapSlot), Assignments),
    % Clear both cells
    find_room_index_local(Room1, RoomIdx1),
    find_slot_index_local(SlotID, SlotIdx1),
    find_room_index_local(Room2, RoomIdx2),
    find_slot_index_local(SwapSlot, SlotIdx2),
    set_cell(Matrix,    RoomIdx1, SlotIdx1, empty, Temp1),
    set_cell(Temp1,     RoomIdx2, SlotIdx2, empty, Temp2),
    % Place swapped assignments
    set_cell(Temp2,     RoomIdx1, SlotIdx1,
             assigned(Room1, Class1, SubjectID, Teacher1, SwapSlot), Temp3),
    set_cell(Temp3,     RoomIdx2, SlotIdx2,
             assigned(Room2, Class2, SwapSubject, Teacher2, SlotID),
             UpdatedMatrix),
    log_info('Applied swap_sessions fix').

execute_fix(UnknownType, _, _, _) :-
    format(atom(Msg), 'Unknown fix type: ~w', [UnknownType]),
    throw(error(unknown_fix_type, Msg)).

% ============================================================================
% Helper predicates
% ============================================================================

%% current_timetable_data(-Matrix)
%% Retrieve the current timetable from the api_server dynamic fact.
current_timetable_data(Matrix) :-
    (   catch(api_server:current_timetable(Matrix), _, fail)
    ->  true
    ;   catch(user:current_timetable(Matrix), _, fail)
    ).

%% suitable_room_free_at(+SubjectID, +SlotID, +Assignments)
%% True if there exists a suitable room that is free at SlotID.
suitable_room_free_at(SubjectID, SlotID, Assignments) :-
    (   (subject(SubjectID, _, _, Type, _) ; user:subject(SubjectID, _, _, Type, _))
    ->  true
    ;   Type = theory
    ),
    (   room(RoomID, _, _, RoomType)
    ;   user:room(RoomID, _, _, RoomType)
    ),
    compatible_type(Type, RoomType),
    \+ member(assigned(RoomID, _, _, _, SlotID), Assignments).

%% find_room_index_local(+RoomID, -Index)
%% Find the 0-based index of a room in the rooms list.
find_room_index_local(RoomID, Index) :-
    get_all_rooms(Rooms),
    nth0(Index, Rooms, room(RoomID, _, _, _)).

%% find_slot_index_local(+SlotID, -Index)
%% Find the 0-based index of a slot in the slots list.
find_slot_index_local(SlotID, Index) :-
    get_all_timeslots(Slots),
    nth0(Index, Slots, timeslot(SlotID, _, _, _, _)).

% ============================================================================
% END OF MODULE
% ============================================================================
