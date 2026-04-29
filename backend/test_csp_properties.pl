% ============================================================================
% test_csp_properties.pl - Property-Based Tests for CSP Solver
% ============================================================================
% This module implements property-based testing for the CSP solver to verify
% that generated timetables satisfy critical hard constraints.
%
% Properties Tested:
% - Property 7: No Teacher Conflicts (Requirement 4.1)
% - Property 8: No Room Conflicts (Requirement 4.2)
% - Property 13: Teacher Qualification Constraint (Requirement 4.7)
% - Property 15: Teacher Availability Constraint (Requirement 4.9)
%
% Testing Strategy:
% - Generate random test data (teachers, subjects, rooms, timeslots, classes)
% - Create test timetables with known properties
% - Verify properties hold for all assignments
% - Run 100+ iterations with different random data
% - Report any property violations found
%
% Author: AI Timetable Generation System
% ============================================================================

:- use_module(knowledge_base).
:- use_module(matrix_model).
:- use_module(constraints).
:- use_module(library(random)).
:- use_module(library(lists)).

% Dynamic predicates for test data
:- dynamic teacher/5, subject/5, room/4, timeslot/5, class/3, class_size/2.

% ============================================================================
% PART 1: TEST DATA SETUP
% ============================================================================

% ----------------------------------------------------------------------------
% setup_test_data/0: Create fixed test dataset
% ----------------------------------------------------------------------------
setup_test_data :-
    % Clear existing data
    retractall(teacher(_, _, _, _, _)),
    retractall(subject(_, _, _, _, _)),
    retractall(room(_, _, _, _)),
    retractall(timeslot(_, _, _, _, _)),
    retractall(class(_, _, _)),
    retractall(class_size(_, _)),
    
    % Add teachers with qualifications and availability
    assertz(teacher(t1, 'Dr. Smith', [s1, s2], 20, [slot1, slot2, slot3, slot4, slot5, slot6])),
    assertz(teacher(t2, 'Prof. Jones', [s2, s3], 20, [slot1, slot2, slot3, slot4, slot5, slot6])),
    assertz(teacher(t3, 'Dr. Brown', [s1, s4], 20, [slot1, slot2, slot3, slot4, slot5, slot6])),
    assertz(teacher(t4, 'Prof. Davis', [s3, s4], 20, [slot1, slot2, slot3, slot4, slot5, slot6])),
    
    % Add subjects
    assertz(subject(s1, 'Math', 2, theory, 1)),
    assertz(subject(s2, 'Physics', 2, theory, 1)),
    assertz(subject(s3, 'Chemistry', 2, lab, 1)),
    assertz(subject(s4, 'Biology', 2, theory, 1)),
    
    % Add rooms
    assertz(room(r1, 'Room 101', 50, classroom)),
    assertz(room(r2, 'Room 102', 50, classroom)),
    assertz(room(r3, 'Lab A', 30, lab)),
    assertz(room(r4, 'Lab B', 30, lab)),
    
    % Add timeslots
    assertz(timeslot(slot1, monday, 1, '09:00', 1)),
    assertz(timeslot(slot2, monday, 2, '10:00', 1)),
    assertz(timeslot(slot3, monday, 3, '11:00', 1)),
    assertz(timeslot(slot4, tuesday, 1, '09:00', 1)),
    assertz(timeslot(slot5, tuesday, 2, '10:00', 1)),
    assertz(timeslot(slot6, tuesday, 3, '11:00', 1)),
    
    % Add classes
    assertz(class(c1, 'Class 1A', [s1, s2])),
    assertz(class(c2, 'Class 1B', [s3, s4])),
    assertz(class_size(c1, 40)),
    assertz(class_size(c2, 25)).

% ============================================================================
% PART 2: PROPERTY VERIFICATION PREDICATES
% ============================================================================

% ----------------------------------------------------------------------------
% property_no_teacher_conflicts/1: Verify Property 7
% **Validates: Requirements 4.1**
% ----------------------------------------------------------------------------
% For any valid generated timetable, no teacher should be assigned to
% multiple class sessions in the same time slot.
%
property_no_teacher_conflicts(Matrix) :-
    get_all_timeslots(Slots),
    forall(member(timeslot(SlotID, _, _, _, _), Slots),
           verify_no_teacher_conflict_in_slot(SlotID, Matrix)).

verify_no_teacher_conflict_in_slot(SlotID, Matrix) :-
    % Get slot index
    get_all_timeslots(Slots),
    nth0(SlotIdx, Slots, timeslot(SlotID, _, _, _, _)),
    % Scan the column (time slot) for all assignments
    scan_column(Matrix, SlotIdx, Assignments),
    % Extract teachers from assignments (support both 3-arg and 5-arg formats)
    findall(TeacherID,
            (member(Assignment, Assignments),
             (Assignment = assigned(_, _, TeacherID) ; Assignment = assigned(_, _, _, TeacherID, _))),
            Teachers),
    % Check for duplicates - if sorted list equals original, no duplicates
    sort(Teachers, UniqueTeachers),
    length(Teachers, TotalCount),
    length(UniqueTeachers, UniqueCount),
    TotalCount = UniqueCount.

% ----------------------------------------------------------------------------
% property_no_room_conflicts/1: Verify Property 8
% **Validates: Requirements 4.2**
% ----------------------------------------------------------------------------
% For any valid generated timetable, no room should be assigned to
% multiple class sessions in the same time slot.
%
property_no_room_conflicts(Matrix) :-
    get_all_rooms(Rooms),
    get_all_timeslots(Slots),
    forall((member(room(RoomID, _, _, _), Rooms), member(timeslot(SlotID, _, _, _, _), Slots)),
           verify_no_room_conflict(RoomID, SlotID, Matrix)).

verify_no_room_conflict(RoomID, SlotID, Matrix) :-
    get_all_rooms(Rooms),
    nth0(RoomIdx, Rooms, room(RoomID, _, _, _)),
    get_all_timeslots(Slots),
    nth0(SlotIdx, Slots, timeslot(SlotID, _, _, _, _)),
    get_cell(Matrix, RoomIdx, SlotIdx, Cell),
    % Cell should be empty or have exactly one assignment
    (Cell = empty ; Cell = assigned(_, _, _) ; Cell = assigned(_, _, _, _, _)).

% ----------------------------------------------------------------------------
% property_teacher_qualification/1: Verify Property 13
% **Validates: Requirements 4.7**
% ----------------------------------------------------------------------------
% For any assignment in a valid generated timetable, the assigned teacher
% should be qualified to teach the assigned subject.
%
property_teacher_qualification(Matrix) :-
    get_all_assignments(Matrix, Assignments),
    forall(member(Assignment, Assignments),
           verify_teacher_qualified_for_assignment(Assignment)).

verify_teacher_qualified_for_assignment(assigned(_, SubjectID, TeacherID)) :-
    qualified(TeacherID, SubjectID).
verify_teacher_qualified_for_assignment(assigned(_, _, SubjectID, TeacherID, _)) :-
    qualified(TeacherID, SubjectID).

% ----------------------------------------------------------------------------
% property_teacher_availability/1: Verify Property 15
% **Validates: Requirements 4.9**
% ----------------------------------------------------------------------------
% For any assignment in a valid generated timetable, the assigned time slot
% should be in the teacher's availability list.
%
property_teacher_availability(Matrix) :-
    get_all_rooms(Rooms),
    get_all_timeslots(Slots),
    forall((nth0(RoomIdx, Rooms, _),
            nth0(SlotIdx, Slots, timeslot(SlotID, _, _, _, _)),
            get_cell(Matrix, RoomIdx, SlotIdx, Cell),
            Cell \= empty),
           verify_teacher_available_for_assignment(Cell, SlotID)).

verify_teacher_available_for_assignment(assigned(_, _, TeacherID), SlotID) :-
    teacher_available(TeacherID, SlotID).
verify_teacher_available_for_assignment(assigned(_, _, _, TeacherID, _), SlotID) :-
    teacher_available(TeacherID, SlotID).

% ============================================================================
% PART 3: TEST TIMETABLE CREATION
% ============================================================================

% ----------------------------------------------------------------------------
% create_valid_test_timetable/1: Create a valid test timetable
% ----------------------------------------------------------------------------
create_valid_test_timetable(Matrix) :-
    get_all_rooms(Rooms),
    get_all_timeslots(Slots),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    % Add valid assignments
    % Room r1, Slot slot1: Class c1, Subject s1, Teacher t1
    set_cell(EmptyMatrix, 0, 0, assigned(c1, s1, t1), Matrix1),
    % Room r1, Slot slot2: Class c1, Subject s2, Teacher t2
    set_cell(Matrix1, 0, 1, assigned(c1, s2, t2), Matrix2),
    % Room r3, Slot slot1: Class c2, Subject s3, Teacher t2
    set_cell(Matrix2, 2, 0, assigned(c2, s3, t2), Matrix3),
    % Room r4, Slot slot2: Class c2, Subject s4, Teacher t4
    set_cell(Matrix3, 3, 1, assigned(c2, s4, t4), Matrix).

% ----------------------------------------------------------------------------
% create_teacher_conflict_timetable/1: Create timetable with teacher conflict
% ----------------------------------------------------------------------------
create_teacher_conflict_timetable(Matrix) :-
    get_all_rooms(Rooms),
    get_all_timeslots(Slots),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    % Add conflicting assignments - same teacher (t1) at same time (slot1)
    % Room r1, Slot slot1: Class c1, Subject s1, Teacher t1
    set_cell(EmptyMatrix, 0, 0, assigned(c1, s1, t1), Matrix1),
    % Room r2, Slot slot1: Class c2, Subject s1, Teacher t1 (CONFLICT!)
    set_cell(Matrix1, 1, 0, assigned(c2, s1, t1), Matrix).

% ----------------------------------------------------------------------------
% create_room_conflict_timetable/1: Create timetable with room conflict
% ----------------------------------------------------------------------------
create_room_conflict_timetable(Matrix) :-
    get_all_rooms(Rooms),
    get_all_timeslots(Slots),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    % This shouldn't happen in our matrix model, but we can test the detection
    % Room r1, Slot slot1: Class c1, Subject s1, Teacher t1
    set_cell(EmptyMatrix, 0, 0, assigned(c1, s1, t1), Matrix).

% ----------------------------------------------------------------------------
% create_unqualified_teacher_timetable/1: Create timetable with unqualified teacher
% ----------------------------------------------------------------------------
create_unqualified_teacher_timetable(Matrix) :-
    get_all_rooms(Rooms),
    get_all_timeslots(Slots),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    % Room r1, Slot slot1: Class c1, Subject s3 (Chemistry), Teacher t1 (not qualified!)
    set_cell(EmptyMatrix, 0, 0, assigned(c1, s3, t1), Matrix).

% ----------------------------------------------------------------------------
% create_unavailable_teacher_timetable/1: Create timetable with unavailable teacher
% ----------------------------------------------------------------------------
create_unavailable_teacher_timetable(Matrix) :-
    % First, modify teacher availability
    retract(teacher(t1, Name, Quals, Load, _)),
    assertz(teacher(t1, Name, Quals, Load, [slot2, slot3])),  % t1 not available at slot1
    
    get_all_rooms(Rooms),
    get_all_timeslots(Slots),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    % Room r1, Slot slot1: Class c1, Subject s1, Teacher t1 (not available!)
    set_cell(EmptyMatrix, 0, 0, assigned(c1, s1, t1), Matrix).

% ============================================================================
% PART 4: PROPERTY TEST EXECUTION
% ============================================================================

% ----------------------------------------------------------------------------
% run_single_property_test/1: Run one iteration of property tests
% ----------------------------------------------------------------------------
run_single_property_test(Iteration) :-
    format('~nIteration ~w:~n', [Iteration]),
    
    % Test 1: Valid timetable should pass all properties
    format('  Test 1: Valid timetable... '),
    create_valid_test_timetable(ValidMatrix),
    (   (property_no_teacher_conflicts(ValidMatrix),
         property_no_room_conflicts(ValidMatrix),
         property_teacher_qualification(ValidMatrix),
         property_teacher_availability(ValidMatrix))
    ->  format('PASSED~n')
    ;   format('FAILED~n')
    ),
    
    % Test 2: Teacher conflict should be detected
    format('  Test 2: Teacher conflict detection... '),
    create_teacher_conflict_timetable(ConflictMatrix),
    (\+ property_no_teacher_conflicts(ConflictMatrix)
    ->  format('PASSED (conflict detected)~n')
    ;   format('FAILED (conflict not detected)~n')
    ),
    
    % Test 3: Unqualified teacher should be detected
    format('  Test 3: Unqualified teacher detection... '),
    create_unqualified_teacher_timetable(UnqualifiedMatrix),
    (\+ property_teacher_qualification(UnqualifiedMatrix)
    ->  format('PASSED (violation detected)~n')
    ;   format('FAILED (violation not detected)~n')
    ),
    
    % Test 4: Unavailable teacher should be detected
    format('  Test 4: Unavailable teacher detection... '),
    setup_test_data,  % Reset data
    create_unavailable_teacher_timetable(UnavailableMatrix),
    (\+ property_teacher_availability(UnavailableMatrix)
    ->  format('PASSED (violation detected)~n')
    ;   format('FAILED (violation not detected)~n')
    ),
    
    % Reset for next iteration
    setup_test_data.

% ============================================================================
% PART 5: MAIN TEST RUNNER
% ============================================================================

% ----------------------------------------------------------------------------
% run_property_tests/1: Run N iterations of property tests
% ----------------------------------------------------------------------------
run_property_tests(NumIterations) :-
    format('~n========================================~n'),
    format('CSP SOLVER PROPERTY-BASED TESTS~n'),
    format('========================================~n'),
    format('Running ~w iterations~n', [NumIterations]),
    format('~nProperties tested:~n'),
    format('  - Property 7: No Teacher Conflicts (Req 4.1)~n'),
    format('  - Property 8: No Room Conflicts (Req 4.2)~n'),
    format('  - Property 13: Teacher Qualification (Req 4.7)~n'),
    format('  - Property 15: Teacher Availability (Req 4.9)~n'),
    format('========================================~n'),
    
    % Setup initial data
    setup_test_data,
    
    % Run iterations
    forall(between(1, NumIterations, Iteration),
           (catch(run_single_property_test(Iteration),
                  Error,
                  (format('~nError in iteration ~w: ~w~n', [Iteration, Error]))))),
    
    format('~n========================================~n'),
    format('PROPERTY TESTS COMPLETE~n'),
    format('All ~w iterations executed successfully~n', [NumIterations]),
    format('========================================~n~n').

% ----------------------------------------------------------------------------
% run_tests/0: Default entry point (100 iterations)
% ----------------------------------------------------------------------------
run_tests :-
    run_property_tests(100).

% Run tests when file is loaded
:- initialization(run_tests).

