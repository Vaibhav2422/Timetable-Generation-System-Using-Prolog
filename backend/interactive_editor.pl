% ============================================================================
% interactive_editor.pl - Interactive Drag-and-Drop Timetable Editing
% ============================================================================
% This module supports manual editing of a generated timetable by validating
% proposed moves, applying them, detecting cascading effects, and
% automatically resolving any conflicts that arise.
%
% Key predicates:
%   validate_manual_change/4   - check if a proposed move is valid
%   apply_manual_change/4      - apply a validated move to the timetable
%   suggest_alternative_slots/3 - suggest valid drop targets when a move fails
%   check_cascading_effects/3  - detect knock-on effects of a move
%   auto_fix_conflicts/2       - automatically resolve conflicts after a move
%
% Requirements: Feature 12 (Task 28B)
%
% Author: AI Timetable Generation System
% ============================================================================

:- module(interactive_editor, [
    validate_manual_change/4,
    apply_manual_change/4,
    suggest_alternative_slots/3,
    check_cascading_effects/3,
    auto_fix_conflicts/2
]).

:- use_module(knowledge_base).
:- use_module(matrix_model).
:- use_module(constraints).
:- use_module(logging).

% Allow dynamic facts from api_server / user space
:- multifile teacher/5, subject/5, room/4, timeslot/5, class/3.
:- dynamic   teacher/5, subject/5, room/4, timeslot/5, class/3.

% ============================================================================
% validate_manual_change/4
% ============================================================================
% Check whether moving an assignment from one cell to another is valid.
%
% validate_manual_change(+Matrix, +Move, -IsValid, -Warnings)
%
%   Move = move(FromRoom, FromSlot, ToRoom, ToSlot)
%
%   IsValid = true | false
%   Warnings = list of atom messages (may be non-empty even when valid,
%              e.g. soft-constraint warnings)
%
% ============================================================================

validate_manual_change(Matrix, move(FromRoom, FromSlot, ToRoom, ToSlot),
                       IsValid, Warnings) :-
    log_info('Validating manual timetable change'),
    % Retrieve the assignment being moved
    (   find_assignment_at(Matrix, FromRoom, FromSlot, Assignment)
    ->  Assignment = assigned(FromRoom, ClassID, SubjectID, TeacherID, FromSlot),
        % Build the proposed new assignment
        NewAssignment = assigned(ToRoom, ClassID, SubjectID, TeacherID, ToSlot),
        % Temporarily remove the old assignment and check constraints
        remove_assignment_at(Matrix, FromRoom, FromSlot, TempMatrix),
        collect_hard_violations(NewAssignment, TempMatrix, HardViolations),
        collect_soft_warnings(NewAssignment, TempMatrix, SoftWarnings),
        append(HardViolations, SoftWarnings, AllWarnings),
        (HardViolations = [] -> IsValid = true ; IsValid = false),
        Warnings = AllWarnings
    ;   IsValid  = false,
        Warnings = ['No assignment found at the source cell']
    ).

% ============================================================================
% apply_manual_change/4
% ============================================================================
% Apply a validated move to the timetable matrix.
%
% apply_manual_change(+Matrix, +Move, -UpdatedMatrix, -Result)
%
%   Result = success | error(Reason)
%
% ============================================================================

apply_manual_change(Matrix, move(FromRoom, FromSlot, ToRoom, ToSlot),
                    UpdatedMatrix, Result) :-
    log_info('Applying manual timetable change'),
    (   find_assignment_at(Matrix, FromRoom, FromSlot, Assignment)
    ->  Assignment = assigned(FromRoom, ClassID, SubjectID, TeacherID, FromSlot),
        NewAssignment = assigned(ToRoom, ClassID, SubjectID, TeacherID, ToSlot),
        % Clear source cell
        remove_assignment_at(Matrix, FromRoom, FromSlot, TempMatrix),
        % Place assignment in destination cell
        place_assignment_at(TempMatrix, ToRoom, ToSlot, NewAssignment, UpdatedMatrix),
        log_info('Manual change applied successfully'),
        Result = success
    ;   UpdatedMatrix = Matrix,
        Result = error('No assignment found at source cell')
    ).

% ============================================================================
% suggest_alternative_slots/3
% ============================================================================
% When a proposed move is invalid, suggest valid alternative (room, slot) pairs
% for the assignment being moved.
%
% suggest_alternative_slots(+Matrix, +FromRoom/+FromSlot, -Alternatives)
%
%   Alternatives = list of alt(RoomID, SlotID)
%
% ============================================================================

suggest_alternative_slots(Matrix, from(FromRoom, FromSlot), Alternatives) :-
    log_info('Generating alternative slot suggestions'),
    (   find_assignment_at(Matrix, FromRoom, FromSlot, Assignment)
    ->  Assignment = assigned(FromRoom, ClassID, SubjectID, TeacherID, FromSlot),
        remove_assignment_at(Matrix, FromRoom, FromSlot, TempMatrix),
        findall(alt(ToRoom, ToSlot),
                (   % Candidate room must be suitable for the subject type
                    (room(ToRoom, _, _, _) ; user:room(ToRoom, _, _, _)),
                    (subject(SubjectID, _, _, SType, _) ; user:subject(SubjectID, _, _, SType, _) ; SType = theory),
                    (room(ToRoom, _, _, RType) ; user:room(ToRoom, _, _, RType)),
                    compatible_type(SType, RType),
                    % Candidate slot must exist
                    (timeslot(ToSlot, _, _, _, _) ; user:timeslot(ToSlot, _, _, _, _)),
                    % Skip the original cell
                    \+ (ToRoom = FromRoom, ToSlot = FromSlot),
                    % Validate the proposed move
                    NewAssignment = assigned(ToRoom, ClassID, SubjectID, TeacherID, ToSlot),
                    collect_hard_violations(NewAssignment, TempMatrix, [])
                ),
                Alternatives)
    ;   Alternatives = []
    ).

% ============================================================================
% check_cascading_effects/3
% ============================================================================
% Detect whether applying a move would affect other assignments (e.g. a
% teacher now has a conflict elsewhere, or a room becomes double-booked).
%
% check_cascading_effects(+Matrix, +Move, -Effects)
%
%   Effects = list of effect(Type, Description)
%
% ============================================================================

check_cascading_effects(Matrix, move(FromRoom, FromSlot, ToRoom, ToSlot), Effects) :-
    log_info('Checking cascading effects of manual change'),
    (   find_assignment_at(Matrix, FromRoom, FromSlot, Assignment)
    ->  Assignment = assigned(FromRoom, ClassID, SubjectID, TeacherID, FromSlot),
        NewAssignment = assigned(ToRoom, ClassID, SubjectID, TeacherID, ToSlot),
        remove_assignment_at(Matrix, FromRoom, FromSlot, TempMatrix),
        place_assignment_at(TempMatrix, ToRoom, ToSlot, NewAssignment, NewMatrix),
        % Detect teacher conflicts in the new matrix
        findall(effect(teacher_conflict, Desc),
                (   get_all_assignments(NewMatrix, Assignments),
                    member(assigned(_, _, _, TeacherID, ToSlot), Assignments),
                    member(assigned(_, _, OtherSubj, TeacherID, ToSlot), Assignments),
                    OtherSubj \= SubjectID,
                    format(atom(Desc),
                           'Teacher ~w now has a conflict at slot ~w',
                           [TeacherID, ToSlot])
                ),
                TeacherEffects),
        % Detect room conflicts in the new matrix
        findall(effect(room_conflict, Desc),
                (   get_all_assignments(NewMatrix, Assignments2),
                    member(assigned(ToRoom, _, _, _, ToSlot), Assignments2),
                    member(assigned(ToRoom, _, OtherSubj2, _, ToSlot), Assignments2),
                    OtherSubj2 \= SubjectID,
                    format(atom(Desc),
                           'Room ~w now has a conflict at slot ~w',
                           [ToRoom, ToSlot])
                ),
                RoomEffects),
        append(TeacherEffects, RoomEffects, Effects)
    ;   Effects = []
    ).

% ============================================================================
% auto_fix_conflicts/2
% ============================================================================
% After a manual edit, automatically resolve any conflicts that were
% introduced by attempting to move conflicting assignments to free slots.
%
% auto_fix_conflicts(+Matrix, -FixedMatrix)
%
% ============================================================================

auto_fix_conflicts(Matrix, FixedMatrix) :-
    log_info('Auto-fixing conflicts after manual edit'),
    detect_conflicts_local(Matrix, Conflicts),
    (   Conflicts = []
    ->  FixedMatrix = Matrix,
        log_info('No conflicts to fix')
    ;   resolve_conflicts_iteratively(Matrix, Conflicts, FixedMatrix)
    ).

% ============================================================================
% Internal helpers
% ============================================================================

%% find_assignment_at(+Matrix, +RoomID, +SlotID, -Assignment)
%% Retrieve the assignment at a specific (room, slot) cell.
find_assignment_at(Matrix, RoomID, SlotID, Assignment) :-
    get_all_assignments(Matrix, Assignments),
    member(Assignment, Assignments),
    Assignment = assigned(RoomID, _, _, _, SlotID).

%% remove_assignment_at(+Matrix, +RoomID, +SlotID, -NewMatrix)
%% Set the cell at (RoomID, SlotID) to empty.
remove_assignment_at(Matrix, RoomID, SlotID, NewMatrix) :-
    find_room_index(RoomID, RoomIdx),
    find_slot_index(SlotID, SlotIdx),
    set_cell(Matrix, RoomIdx, SlotIdx, empty, NewMatrix).

%% place_assignment_at(+Matrix, +RoomID, +SlotID, +Assignment, -NewMatrix)
%% Write an assignment into the cell at (RoomID, SlotID).
place_assignment_at(Matrix, RoomID, SlotID, Assignment, NewMatrix) :-
    find_room_index(RoomID, RoomIdx),
    find_slot_index(SlotID, SlotIdx),
    set_cell(Matrix, RoomIdx, SlotIdx, Assignment, NewMatrix).

%% find_room_index(+RoomID, -Index)
find_room_index(RoomID, Index) :-
    get_all_rooms(Rooms),
    nth0(Index, Rooms, room(RoomID, _, _, _)).

%% find_slot_index(+SlotID, -Index)
find_slot_index(SlotID, Index) :-
    get_all_timeslots(Slots),
    nth0(Index, Slots, timeslot(SlotID, _, _, _, _)).

%% collect_hard_violations(+Assignment, +Matrix, -Violations)
%% Collect hard constraint violations for a proposed assignment.
collect_hard_violations(assigned(RoomID, ClassID, SubjectID, TeacherID, SlotID),
                        Matrix, Violations) :-
    findall(Msg,
            (   % Teacher double-booking
                (   get_all_assignments(Matrix, Assignments),
                    member(assigned(_, _, _, TeacherID, SlotID), Assignments),
                    format(atom(Msg), 'Teacher ~w is already assigned at slot ~w',
                           [TeacherID, SlotID])
                )
            ;   % Room double-booking
                (   get_all_assignments(Matrix, Assignments2),
                    member(assigned(RoomID, _, _, _, SlotID), Assignments2),
                    format(atom(Msg), 'Room ~w is already occupied at slot ~w',
                           [RoomID, SlotID])
                )
            ;   % Teacher not qualified
                (   \+ check_teacher_qualified(TeacherID, SubjectID),
                    format(atom(Msg), 'Teacher ~w is not qualified for subject ~w',
                           [TeacherID, SubjectID])
                )
            ;   % Room not suitable
                (   \+ check_room_suitable(RoomID, SubjectID),
                    format(atom(Msg), 'Room ~w is not suitable for subject ~w',
                           [RoomID, SubjectID])
                )
            ;   % Teacher not available
                (   \+ check_teacher_available(TeacherID, SlotID),
                    format(atom(Msg), 'Teacher ~w is not available at slot ~w',
                           [TeacherID, SlotID])
                )
            ;   % Room capacity
                (   \+ check_room_capacity(RoomID, ClassID),
                    format(atom(Msg), 'Room ~w capacity is insufficient for class ~w',
                           [RoomID, ClassID])
                )
            ),
            Violations).

%% collect_soft_warnings(+Assignment, +Matrix, -Warnings)
%% Collect soft constraint warnings for a proposed assignment.
collect_soft_warnings(assigned(_RoomID, _ClassID, SubjectID, _TeacherID, SlotID),
                      _Matrix, Warnings) :-
    findall(Msg,
            (   % Late theory class warning
                (subject(SubjectID, _, _, theory, _) ; user:subject(SubjectID, _, _, theory, _)),
                (timeslot(SlotID, _, Period, _, _) ; user:timeslot(SlotID, _, Period, _, _)),
                Period > 6,
                Msg = 'Warning: Theory class scheduled in a late period (soft constraint)'
            ),
            Warnings).

%% detect_conflicts_local(+Matrix, -Conflicts)
%% Detect teacher and room conflicts in a matrix.
detect_conflicts_local(Matrix, Conflicts) :-
    get_all_assignments(Matrix, Assignments),
    findall(teacher_conflict(TID, SID),
            (   member(assigned(_, _, _, TID, SID), Assignments),
                findall(1, member(assigned(_, _, _, TID, SID), Assignments), Cs),
                length(Cs, N), N > 1
            ),
            TC),
    findall(room_conflict(RID, SID),
            (   member(assigned(RID, _, _, _, SID), Assignments),
                findall(1, member(assigned(RID, _, _, _, SID), Assignments), Cs),
                length(Cs, N), N > 1
            ),
            RC),
    append(TC, RC, Conflicts).

%% resolve_conflicts_iteratively(+Matrix, +Conflicts, -FixedMatrix)
%% Attempt to resolve each conflict by moving one of the conflicting
%% assignments to a free slot.
resolve_conflicts_iteratively(Matrix, [], Matrix).
resolve_conflicts_iteratively(Matrix, [Conflict|Rest], FixedMatrix) :-
    (   resolve_single_conflict(Matrix, Conflict, TempMatrix)
    ->  resolve_conflicts_iteratively(TempMatrix, Rest, FixedMatrix)
    ;   % Could not resolve this conflict automatically; skip it
        log_warning('Could not auto-resolve conflict'),
        resolve_conflicts_iteratively(Matrix, Rest, FixedMatrix)
    ).

%% resolve_single_conflict(+Matrix, +Conflict, -NewMatrix)
%% Move one of the conflicting assignments to a free slot.
resolve_single_conflict(Matrix, teacher_conflict(TeacherID, SlotID), NewMatrix) :-
    get_all_assignments(Matrix, Assignments),
    % Pick the second occurrence to move
    findall(assigned(R, C, S, TeacherID, SlotID),
            member(assigned(R, C, S, TeacherID, SlotID), Assignments),
            [_Keep | [ToMove | _]]),
    ToMove = assigned(FromRoom, ClassID, SubjectID, TeacherID, SlotID),
    % Find a free slot for this assignment
    suggest_alternative_slots(Matrix, from(FromRoom, SlotID), [alt(ToRoom, ToSlot) | _]),
    remove_assignment_at(Matrix, FromRoom, SlotID, TempMatrix),
    NewAssignment = assigned(ToRoom, ClassID, SubjectID, TeacherID, ToSlot),
    place_assignment_at(TempMatrix, ToRoom, ToSlot, NewAssignment, NewMatrix).

resolve_single_conflict(Matrix, room_conflict(RoomID, SlotID), NewMatrix) :-
    get_all_assignments(Matrix, Assignments),
    findall(assigned(RoomID, C, S, T, SlotID),
            member(assigned(RoomID, C, S, T, SlotID), Assignments),
            [_Keep | [ToMove | _]]),
    ToMove = assigned(RoomID, ClassID, SubjectID, TeacherID, SlotID),
    suggest_alternative_slots(Matrix, from(RoomID, SlotID), [alt(ToRoom, ToSlot) | _]),
    remove_assignment_at(Matrix, RoomID, SlotID, TempMatrix),
    NewAssignment = assigned(ToRoom, ClassID, SubjectID, TeacherID, ToSlot),
    place_assignment_at(TempMatrix, ToRoom, ToSlot, NewAssignment, NewMatrix).

% ============================================================================
% END OF MODULE
% ============================================================================
