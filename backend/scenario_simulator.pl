% ============================================================================
% scenario_simulator.pl - Scenario Simulation Module
% ============================================================================
% This module implements "what-if" scenario simulation for the timetable.
% It allows administrators to explore how the schedule would change under
% different conditions without permanently modifying the live timetable.
%
% Supported scenarios:
%   teacher_absence  - Mark a teacher unavailable; reassign their sessions
%   room_maintenance - Mark a room unavailable; reassign its sessions
%   extra_class      - Add new sessions to the existing timetable
%   exam_week        - Adjust timetable to satisfy exam-week constraints
%
% Requirements: Feature 3 (Task 20)
%
% Author: AI Timetable Generation System
% ============================================================================

:- module(scenario_simulator, [
    simulate_scenario/3,
    compare_scenarios/3,
    mark_teacher_unavailable/4,
    reassign_sessions/3,
    find_alternative_assignment/2
]).

:- use_module(knowledge_base).
:- use_module(matrix_model).
:- use_module(constraints).
:- use_module(csp_solver).
:- use_module(probability_module).
:- use_module(logging).

:- multifile teacher/5, subject/5, room/4, timeslot/5, class/3.
:- dynamic teacher/5, subject/5, room/4, timeslot/5, class/3.

% ============================================================================
% simulate_scenario/3
% ============================================================================
% Main entry point for scenario simulation.
%
% Format: simulate_scenario(+ScenarioType, +Params, -Result)
%
% ScenarioType atoms:
%   teacher_absence  - Params: _{teacher_id: ID}
%   room_maintenance - Params: _{room_id: ID}
%   extra_class      - Params: _{class_id: ID, subject_id: SID}
%   exam_week        - Params: _{exam_slots: [SlotID, ...]}
%
% Result: _{timetable: Matrix, reliability: Float, changes: [Change, ...]}
%
% ============================================================================

simulate_scenario(extra_class, Params, Result) :-
    log_info('Simulating extra class scenario'),
    (get_dict(class_id, Params, ClassID) -> true ;
        throw(error(missing_param, 'extra_class scenario requires class_id'))),
    (get_dict(subject_id, Params, SubjectID) -> true ;
        throw(error(missing_param, 'extra_class scenario requires subject_id'))),
    get_current_timetable(OriginalMatrix),
    add_extra_session(ClassID, SubjectID, OriginalMatrix, SimMatrix, Changes),
    schedule_reliability(SimMatrix, Reliability),
    Result = _{
        scenario: extra_class,
        class_id: ClassID,
        subject_id: SubjectID,
        timetable: SimMatrix,
        reliability: Reliability,
        changes: Changes
    }.

simulate_scenario(teacher_absence, Params, Result) :-
    log_info('Simulating teacher absence scenario'),
    (get_dict(teacher_id, Params, TeacherID) -> true ;
        throw(error(missing_param, 'teacher_absence scenario requires teacher_id'))),
    get_current_timetable(OriginalMatrix),
    mark_teacher_unavailable(TeacherID, OriginalMatrix, SimMatrix, Changes),
    schedule_reliability(SimMatrix, Reliability),
    Result = _{
        scenario: teacher_absence,
        teacher_id: TeacherID,
        timetable: SimMatrix,
        reliability: Reliability,
        changes: Changes
    }.

simulate_scenario(room_maintenance, Params, Result) :-
    log_info('Simulating room maintenance scenario'),
    (get_dict(room_id, Params, RoomID) -> true ;
        throw(error(missing_param, 'room_maintenance scenario requires room_id'))),
    get_current_timetable(OriginalMatrix),
    mark_room_unavailable(RoomID, OriginalMatrix, SimMatrix, Changes),
    schedule_reliability(SimMatrix, Reliability),
    Result = _{
        scenario: room_maintenance,
        room_id: RoomID,
        timetable: SimMatrix,
        reliability: Reliability,
        changes: Changes
    }.

simulate_scenario(exam_week, Params, Result) :-
    log_info('Simulating exam week scenario'),
    (get_dict(exam_slots, Params, ExamSlots) -> true ;
        throw(error(missing_param, 'exam_week scenario requires exam_slots'))),
    get_current_timetable(OriginalMatrix),
    apply_exam_week_constraints(ExamSlots, OriginalMatrix, SimMatrix, Changes),
    schedule_reliability(SimMatrix, Reliability),
    Result = _{
        scenario: exam_week,
        exam_slots: ExamSlots,
        timetable: SimMatrix,
        reliability: Reliability,
        changes: Changes
    }.

simulate_scenario(Unknown, _, _) :-
    format(atom(Msg), 'Unknown scenario type: ~w', [Unknown]),
    throw(error(unknown_scenario, Msg)).

% ============================================================================
% mark_teacher_unavailable/4
% ============================================================================
% Remove all sessions assigned to TeacherID and attempt to reassign them
% to alternative teachers.
%
% Format: mark_teacher_unavailable(+TeacherID, +Matrix, -NewMatrix, -Changes)
%
% ============================================================================

mark_teacher_unavailable(TeacherID, Matrix, NewMatrix, Changes) :-
    get_all_assignments(Matrix, Assignments),
    % Collect all assignments belonging to this teacher
    findall(A,
            (member(A, Assignments),
             A = assigned(_, _, _, TeacherID, _)),
            TeacherAssignments),
    % Remove those assignments from the matrix
    remove_assignment_list(TeacherAssignments, Matrix, PartialMatrix),
    % Try to reassign each removed session
    reassign_sessions(TeacherAssignments, PartialMatrix, ReassignResult),
    ReassignResult = reassign_result(NewMatrix, Changes).

% ============================================================================
% mark_room_unavailable/4
% ============================================================================
% Remove all sessions in RoomID and attempt to reassign them to other rooms.
%
% Format: mark_room_unavailable(+RoomID, +Matrix, -NewMatrix, -Changes)
%
% ============================================================================

mark_room_unavailable(RoomID, Matrix, NewMatrix, Changes) :-
    get_all_assignments(Matrix, Assignments),
    findall(A,
            (member(A, Assignments),
             A = assigned(RoomID, _, _, _, _)),
            RoomAssignments),
    remove_assignment_list(RoomAssignments, Matrix, PartialMatrix),
    reassign_sessions(RoomAssignments, PartialMatrix, ReassignResult),
    ReassignResult = reassign_result(NewMatrix, Changes).

% ============================================================================
% add_extra_session/5
% ============================================================================
% Add a new session (ClassID, SubjectID) to the timetable using CSP.
%
% Format: add_extra_session(+ClassID, +SubjectID, +Matrix, -NewMatrix, -Changes)
%
% ============================================================================

add_extra_session(ClassID, SubjectID, Matrix, NewMatrix, Changes) :-
    NewSession = session(ClassID, SubjectID),
    (   solve_csp([NewSession], Matrix, NewMatrix)
    ->  Changes = [added_session(ClassID, SubjectID)]
    ;   NewMatrix = Matrix,
        Changes = [failed_to_add_session(ClassID, SubjectID)]
    ).

% ============================================================================
% apply_exam_week_constraints/4
% ============================================================================
% Remove all sessions scheduled in exam slots and return the modified matrix.
%
% Format: apply_exam_week_constraints(+ExamSlots, +Matrix, -NewMatrix, -Changes)
%
% ============================================================================

apply_exam_week_constraints(ExamSlots, Matrix, NewMatrix, Changes) :-
    get_all_assignments(Matrix, Assignments),
    % Collect assignments that fall in exam slots
    findall(A,
            (member(A, Assignments),
             A = assigned(_, _, _, _, SlotID),
             member(SlotID, ExamSlots)),
            ExamConflicts),
    remove_assignment_list(ExamConflicts, Matrix, NewMatrix),
    findall(removed_for_exam(CID, SID, SlotID),
            member(assigned(_, CID, SID, _, SlotID), ExamConflicts),
            Changes).

% ============================================================================
% reassign_sessions/3
% ============================================================================
% Attempt to reassign a list of removed assignments using the CSP solver.
%
% Format: reassign_sessions(+Assignments, +PartialMatrix, -ReassignResult)
%
% ReassignResult = reassign_result(NewMatrix, Changes)
%
% ============================================================================

reassign_sessions([], Matrix, reassign_result(Matrix, [])).
reassign_sessions([assigned(_, ClassID, SubjectID, _, _)|Rest], Matrix, reassign_result(FinalMatrix, AllChanges)) :-
    Session = session(ClassID, SubjectID),
    (   solve_csp([Session], Matrix, TempMatrix)
    ->  Change = reassigned(ClassID, SubjectID),
        reassign_sessions(Rest, TempMatrix, reassign_result(FinalMatrix, RestChanges)),
        AllChanges = [Change|RestChanges]
    ;   % Could not reassign – leave the slot empty and record failure
        Change = unassigned(ClassID, SubjectID),
        reassign_sessions(Rest, Matrix, reassign_result(FinalMatrix, RestChanges)),
        AllChanges = [Change|RestChanges]
    ).

% ============================================================================
% find_alternative_assignment/2
% ============================================================================
% Find a single alternative (TeacherID, RoomID, SlotID) for a session
% that does not conflict with the current matrix.
%
% Format: find_alternative_assignment(+Session, -Assignment)
%
% ============================================================================

find_alternative_assignment(session(ClassID, SubjectID), Assignment) :-
    get_current_timetable(Matrix),
    get_all_assignments(Matrix, Existing),
    (   subject(SubjectID, _, _, Type, _)
    ;   user:subject(SubjectID, _, _, Type, _)
    ),
    % Find a valid (teacher, room, slot) triple
    qualified(TeacherID, SubjectID),
    suitable_room(RoomID, Type),
    (timeslot(SlotID, _, _, _, _) ; user:timeslot(SlotID, _, _, _, _)),
    teacher_available(TeacherID, SlotID),
    % No teacher conflict
    \+ member(assigned(_, _, _, TeacherID, SlotID), Existing),
    % No room conflict
    \+ member(assigned(RoomID, _, _, _, SlotID), Existing),
    Assignment = assigned(RoomID, ClassID, SubjectID, TeacherID, SlotID),
    !.

% ============================================================================
% compare_scenarios/3
% ============================================================================
% Compare two scenario results and produce a diff summary.
%
% Format: compare_scenarios(+ResultA, +ResultB, -Comparison)
%
% Comparison: _{added: [...], removed: [...], moved: [...], reliability_delta: Float}
%
% ============================================================================

compare_scenarios(ResultA, ResultB, Comparison) :-
    get_dict(timetable, ResultA, MatrixA),
    get_dict(timetable, ResultB, MatrixB),
    get_dict(reliability, ResultA, RelA),
    get_dict(reliability, ResultB, RelB),
    get_all_assignments(MatrixA, AssignmentsA),
    get_all_assignments(MatrixB, AssignmentsB),
    % Assignments only in B (added)
    findall(A, (member(A, AssignmentsB), \+ member(A, AssignmentsA)), Added),
    % Assignments only in A (removed)
    findall(A, (member(A, AssignmentsA), \+ member(A, AssignmentsB)), Removed),
    ReliabilityDelta is RelB - RelA,
    Comparison = _{
        added: Added,
        removed: Removed,
        reliability_a: RelA,
        reliability_b: RelB,
        reliability_delta: ReliabilityDelta
    }.

% ============================================================================
% Helper predicates
% ============================================================================

%% get_current_timetable(-Matrix)
%% Retrieve the current timetable from api_server or user module.
get_current_timetable(Matrix) :-
    (   catch(api_server:current_timetable(Matrix), _, fail)
    ->  true
    ;   catch(user:current_timetable(Matrix), _, fail)
    ->  true
    ;   throw(error(no_timetable, 'No timetable available. Generate one first.'))
    ).

%% remove_assignment_list(+Assignments, +Matrix, -NewMatrix)
%% Remove a list of assignments from the matrix (set their cells to empty).
remove_assignment_list([], Matrix, Matrix).
remove_assignment_list([assigned(RoomID, _, _, _, SlotID)|Rest], Matrix, FinalMatrix) :-
    find_room_index_sim(RoomID, RoomIdx),
    find_slot_index_sim(SlotID, SlotIdx),
    set_cell(Matrix, RoomIdx, SlotIdx, empty, TempMatrix),
    remove_assignment_list(Rest, TempMatrix, FinalMatrix).

%% find_room_index_sim(+RoomID, -Index)
find_room_index_sim(RoomID, Index) :-
    get_all_rooms(Rooms),
    nth0(Index, Rooms, room(RoomID, _, _, _)).

%% find_slot_index_sim(+SlotID, -Index)
find_slot_index_sim(SlotID, Index) :-
    get_all_timeslots(Slots),
    nth0(Index, Slots, timeslot(SlotID, _, _, _, _)).

% ============================================================================
% END OF MODULE
% ============================================================================
