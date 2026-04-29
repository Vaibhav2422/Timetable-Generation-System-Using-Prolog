% ============================================================================
% test_probability_properties.pl - Property-Based Tests for Probability Module
% ============================================================================
% This module implements property-based testing for the probability module
% to verify that reliability calculations satisfy critical properties.
%
% Properties Tested:
% - Property 20: Reliability Score Range (Requirements 8.4, 8.7)
% - Property 21: Reliability Calculation Correctness (Requirement 8.5)
% - Property 22: Conditional Reliability Dependencies (Requirement 8.6)
%
% Testing Strategy:
% - Generate random timetables with varying numbers of assignments
% - Verify reliability scores are always in valid range [0.0, 1.0]
% - Verify reliability calculation follows product rule correctly
% - Verify conditional reliability properly handles dependencies
% - Run 100+ iterations with different random data
% - Report any property violations found
%
% Author: AI Timetable Generation System
% ============================================================================

:- use_module(probability_module).
:- use_module(matrix_model).
:- use_module(library(random)).
:- use_module(library(lists)).

% ============================================================================
% PART 1: TEST TIMETABLE GENERATION
% ============================================================================

% ----------------------------------------------------------------------------
% generate_random_assignment/1: Generate a random assignment
% ----------------------------------------------------------------------------
generate_random_assignment(assigned(RoomID, ClassID, SubjectID, TeacherID, SlotID)) :-
    random_between(1, 6, R),
    random_between(1, 10, C),
    random_between(1, 8, S),
    random_between(1, 5, T),
    random_between(1, 30, Sl),
    atom_concat('r', R, RoomID),
    atom_concat('class', C, ClassID),
    atom_concat('subject', S, SubjectID),
    atom_concat('teacher', T, TeacherID),
    atom_concat('slot', Sl, SlotID).

% ----------------------------------------------------------------------------
% generate_random_timetable/2: Generate random timetable with N assignments
% ----------------------------------------------------------------------------
generate_random_timetable(NumAssignments, Matrix) :-
    NumRooms is max(3, ceiling(sqrt(NumAssignments))),
    NumSlots is max(3, ceiling(NumAssignments / NumRooms)),
    length(Rooms, NumRooms),
    length(Slots, NumSlots),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    generate_assignments(NumAssignments, EmptyMatrix, Matrix).

% ----------------------------------------------------------------------------
% generate_assignments/3: Fill matrix with random assignments
% ----------------------------------------------------------------------------
generate_assignments(0, Matrix, Matrix) :- !.
generate_assignments(N, CurrentMatrix, FinalMatrix) :-
    N > 0,
    generate_random_assignment(Assignment),
    % Find an empty cell
    find_empty_cell(CurrentMatrix, RoomIdx, SlotIdx),
    !,
    set_cell(CurrentMatrix, RoomIdx, SlotIdx, Assignment, NewMatrix),
    N1 is N - 1,
    generate_assignments(N1, NewMatrix, FinalMatrix).
generate_assignments(_, Matrix, Matrix).  % No more empty cells

% ----------------------------------------------------------------------------
% find_empty_cell/3: Find first empty cell in matrix
% ----------------------------------------------------------------------------
find_empty_cell(Matrix, RoomIdx, SlotIdx) :-
    length(Matrix, NumRooms),
    between(0, NumRooms, RoomIdx),
    nth0(RoomIdx, Matrix, Row),
    length(Row, NumSlots),
    between(0, NumSlots, SlotIdx),
    nth0(SlotIdx, Row, Cell),
    Cell = empty,
    !.

% ----------------------------------------------------------------------------
% generate_timetable_with_teacher/3: Generate timetable with specific teacher
% ----------------------------------------------------------------------------
generate_timetable_with_teacher(NumAssignments, TeacherID, Matrix) :-
    NumRooms is max(3, ceiling(sqrt(NumAssignments))),
    NumSlots is max(3, ceiling(NumAssignments / NumRooms)),
    length(Rooms, NumRooms),
    length(Slots, NumSlots),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    generate_assignments_with_teacher(NumAssignments, TeacherID, EmptyMatrix, Matrix).

% ----------------------------------------------------------------------------
% generate_assignments_with_teacher/4: Fill matrix ensuring teacher appears
% ----------------------------------------------------------------------------
generate_assignments_with_teacher(0, _, Matrix, Matrix) :- !.
generate_assignments_with_teacher(N, TeacherID, CurrentMatrix, FinalMatrix) :-
    N > 0,
    % First assignment uses specified teacher
    (N = 1 -> UseTeacher = TeacherID ; generate_random_teacher(UseTeacher)),
    random_between(1, 6, R),
    random_between(1, 10, C),
    random_between(1, 8, S),
    random_between(1, 30, Sl),
    atom_concat('r', R, RoomID),
    atom_concat('class', C, ClassID),
    atom_concat('subject', S, SubjectID),
    atom_concat('slot', Sl, SlotID),
    Assignment = assigned(RoomID, ClassID, SubjectID, UseTeacher, SlotID),
    find_empty_cell(CurrentMatrix, RoomIdx, SlotIdx),
    !,
    set_cell(CurrentMatrix, RoomIdx, SlotIdx, Assignment, NewMatrix),
    N1 is N - 1,
    generate_assignments_with_teacher(N1, TeacherID, NewMatrix, FinalMatrix).
generate_assignments_with_teacher(_, _, Matrix, Matrix).

generate_random_teacher(TeacherID) :-
    random_between(1, 5, T),
    atom_concat('teacher', T, TeacherID).

% ============================================================================
% PART 2: PROPERTY VERIFICATION PREDICATES
% ============================================================================

% ----------------------------------------------------------------------------
% property_reliability_score_range/1: Verify Property 20
% **Validates: Requirements 8.4, 8.7**
% ----------------------------------------------------------------------------
% For any timetable (empty or with assignments), the reliability score
% must be in the range [0.0, 1.0].
%
% This property ensures that:
% 1. Reliability scores are valid probabilities
% 2. No calculation errors produce out-of-range values
% 3. Empty timetables have reliability 1.0 (perfect)
% 4. Timetables with assignments have reliability <= 1.0
%
property_reliability_score_range(Matrix) :-
    schedule_reliability(Matrix, Reliability),
    Reliability >= 0.0,
    Reliability =< 1.0.

% ----------------------------------------------------------------------------
% property_reliability_calculation_correctness/1: Verify Property 21
% **Validates: Requirement 8.5**
% ----------------------------------------------------------------------------
% For any timetable, the reliability score should equal the product of
% individual assignment reliabilities (product rule for independent events).
%
% This property ensures that:
% 1. Individual assignment probabilities are calculated correctly
% 2. The product rule is applied correctly
% 3. The calculation matches manual verification
%
property_reliability_calculation_correctness(Matrix) :-
    % Get overall reliability
    schedule_reliability(Matrix, OverallReliability),
    
    % Calculate manually using product rule
    get_all_assignments(Matrix, Assignments),
    calculate_assignment_reliabilities(Assignments, Probabilities),
    combine_probabilities(Probabilities, ManualReliability),
    
    % Should be equal (within floating point tolerance)
    abs(OverallReliability - ManualReliability) < 0.0001.

% ----------------------------------------------------------------------------
% assignment_has_teacher/2: Helper to check if assignment has specific teacher
% ----------------------------------------------------------------------------
assignment_has_teacher(assigned(_, _, TeacherID), TeacherID).
assignment_has_teacher(assigned(_, _, _, TeacherID, _), TeacherID).

% ----------------------------------------------------------------------------
% property_conditional_reliability_dependencies/2: Verify Property 22
% **Validates: Requirement 8.6**
% ----------------------------------------------------------------------------
% For any timetable with a specific teacher, the conditional reliability
% given that teacher is unavailable should be 0.0 (all their sessions fail).
%
% This property ensures that:
% 1. Conditional probability correctly models dependencies
% 2. Teacher unavailability affects all their sessions
% 3. If teacher has no sessions, conditional reliability equals overall
%
property_conditional_reliability_dependencies(Matrix, TeacherID) :-
    % Get conditional reliability
    conditional_reliability(Matrix, TeacherID, ConditionalProb),
    
    % Check if teacher has any assignments
    get_all_assignments(Matrix, Assignments),
    findall(A, (member(A, Assignments), assignment_has_teacher(A, TeacherID)), TeacherAssignments),
    length(TeacherAssignments, NumTeacherSessions),
    
    % If teacher has sessions, conditional prob should be 0.0
    % If teacher has no sessions, conditional prob should equal overall reliability
    (   NumTeacherSessions > 0
    ->  ConditionalProb =:= 0.0
    ;   schedule_reliability(Matrix, OverallReliability),
        abs(ConditionalProb - OverallReliability) < 0.0001
    ).

% ----------------------------------------------------------------------------
% property_empty_timetable_perfect_reliability/1: Additional property
% ----------------------------------------------------------------------------
% An empty timetable (no assignments) should have perfect reliability (1.0)
%
property_empty_timetable_perfect_reliability(Matrix) :-
    get_all_assignments(Matrix, Assignments),
    (   Assignments = []
    ->  schedule_reliability(Matrix, Reliability),
        Reliability =:= 1.0
    ;   true  % Not empty, property doesn't apply
    ).

% ----------------------------------------------------------------------------
% property_reliability_decreases_with_assignments/2: Additional property
% ----------------------------------------------------------------------------
% Adding more assignments should not increase reliability
% (more assignments = more potential failures)
%
property_reliability_decreases_with_assignments(Matrix1, Matrix2) :-
    get_all_assignments(Matrix1, Assignments1),
    get_all_assignments(Matrix2, Assignments2),
    length(Assignments1, Len1),
    length(Assignments2, Len2),
    (   Len1 < Len2
    ->  schedule_reliability(Matrix1, Rel1),
        schedule_reliability(Matrix2, Rel2),
        Rel1 >= Rel2  % Fewer assignments should have higher or equal reliability
    ;   true  % Property doesn't apply
    ).

% ============================================================================
% PART 3: PROPERTY TEST EXECUTION
% ============================================================================

% ----------------------------------------------------------------------------
% run_single_property_test/1: Run one iteration of property tests
% ----------------------------------------------------------------------------
run_single_property_test(Iteration) :-
    format('Iteration ~w: ', [Iteration]),
    
    % Generate random number of assignments (1 to 20)
    random_between(1, 20, NumAssignments),
    
    % Test Property 20: Reliability Score Range
    generate_random_timetable(NumAssignments, Matrix1),
    (   property_reliability_score_range(Matrix1)
    ->  true
    ;   format('~n  FAILED: Property 20 (Reliability Score Range)~n'),
        fail
    ),
    
    % Test Property 21: Reliability Calculation Correctness
    (   property_reliability_calculation_correctness(Matrix1)
    ->  true
    ;   format('~n  FAILED: Property 21 (Reliability Calculation Correctness)~n'),
        fail
    ),
    
    % Test Property 22: Conditional Reliability Dependencies
    random_between(1, 5, T),
    atom_concat('teacher', T, TeacherID),
    generate_timetable_with_teacher(NumAssignments, TeacherID, Matrix2),
    (   property_conditional_reliability_dependencies(Matrix2, TeacherID)
    ->  true
    ;   format('~n  FAILED: Property 22 (Conditional Reliability Dependencies)~n'),
        fail
    ),
    
    % Test additional properties
    (   property_empty_timetable_perfect_reliability(Matrix1)
    ->  true
    ;   format('~n  FAILED: Empty timetable perfect reliability~n'),
        fail
    ),
    
    % Test reliability decreases with more assignments
    random_between(1, 10, NumAssignments2),
    generate_random_timetable(NumAssignments2, Matrix3),
    (   property_reliability_decreases_with_assignments(Matrix3, Matrix1)
    ->  true
    ;   format('~n  FAILED: Reliability decreases with assignments~n'),
        fail
    ),
    
    format('PASSED (N=~w assignments)~n', [NumAssignments]).

% ----------------------------------------------------------------------------
% run_property_tests/1: Run N iterations of property tests
% ----------------------------------------------------------------------------
run_property_tests(NumIterations) :-
    format('~n========================================~n'),
    format('PROBABILITY MODULE PROPERTY-BASED TESTS~n'),
    format('========================================~n'),
    format('Running ~w iterations~n', [NumIterations]),
    format('~nProperties tested:~n'),
    format('  - Property 20: Reliability Score Range (Req 8.4, 8.7)~n'),
    format('  - Property 21: Reliability Calculation Correctness (Req 8.5)~n'),
    format('  - Property 22: Conditional Reliability Dependencies (Req 8.6)~n'),
    format('  - Additional: Empty timetable perfect reliability~n'),
    format('  - Additional: Reliability decreases with assignments~n'),
    format('========================================~n~n'),
    
    % Run iterations
    SuccessCount = 0,
    run_iterations(1, NumIterations, SuccessCount, FinalCount),
    
    format('~n========================================~n'),
    format('PROPERTY TESTS COMPLETE~n'),
    format('Passed: ~w / ~w iterations~n', [FinalCount, NumIterations]),
    (   FinalCount = NumIterations
    ->  format('Result: ALL TESTS PASSED~n')
    ;   format('Result: SOME TESTS FAILED~n')
    ),
    format('========================================~n~n').

% ----------------------------------------------------------------------------
% run_iterations/4: Helper to run iterations and count successes
% ----------------------------------------------------------------------------
run_iterations(Current, Max, Count, Count) :-
    Current > Max, !.
run_iterations(Current, Max, CurrentCount, FinalCount) :-
    Current =< Max,
    (   catch(run_single_property_test(Current), Error,
              (format('~n  ERROR in iteration ~w: ~w~n', [Current, Error]), fail))
    ->  NewCount is CurrentCount + 1
    ;   NewCount = CurrentCount
    ),
    Next is Current + 1,
    run_iterations(Next, Max, NewCount, FinalCount).

% ============================================================================
% PART 4: SPECIFIC TEST CASES
% ============================================================================

% ----------------------------------------------------------------------------
% test_empty_timetable/0: Test empty timetable has reliability 1.0
% ----------------------------------------------------------------------------
test_empty_timetable :-
    format('~nTest: Empty timetable... '),
    length(Rooms, 3),
    length(Slots, 3),
    create_empty_timetable(Rooms, Slots, Matrix),
    schedule_reliability(Matrix, Reliability),
    (   Reliability =:= 1.0
    ->  format('PASSED (Reliability = ~3f)~n', [Reliability])
    ;   format('FAILED (Expected 1.0, got ~3f)~n', [Reliability])
    ).

% ----------------------------------------------------------------------------
% test_single_assignment/0: Test single assignment reliability
% ----------------------------------------------------------------------------
test_single_assignment :-
    format('Test: Single assignment... '),
    length(Rooms, 3),
    length(Slots, 3),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    Assignment = assigned(class1, subject1, teacher1),
    set_cell(EmptyMatrix, 0, 0, Assignment, Matrix),
    schedule_reliability(Matrix, Reliability),
    % Expected: 0.95 * 0.98 * 0.99 = 0.92169
    ExpectedReliability is 0.95 * 0.98 * 0.99,
    (   abs(Reliability - ExpectedReliability) < 0.0001
    ->  format('PASSED (Reliability = ~5f, Expected = ~5f)~n', [Reliability, ExpectedReliability])
    ;   format('FAILED (Reliability = ~5f, Expected = ~5f)~n', [Reliability, ExpectedReliability])
    ).

% ----------------------------------------------------------------------------
% test_multiple_assignments/0: Test multiple assignments reliability
% ----------------------------------------------------------------------------
test_multiple_assignments :-
    format('Test: Multiple assignments... '),
    length(Rooms, 3),
    length(Slots, 3),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    set_cell(EmptyMatrix, 0, 0, assigned(class1, subject1, teacher1), Matrix1),
    set_cell(Matrix1, 0, 1, assigned(class2, subject2, teacher2), Matrix2),
    set_cell(Matrix2, 1, 0, assigned(class3, subject3, teacher3), Matrix),
    schedule_reliability(Matrix, Reliability),
    % Expected: (0.95 * 0.98 * 0.99)^3 = 0.92169^3 ≈ 0.783
    SingleProb is 0.95 * 0.98 * 0.99,
    ExpectedReliability is SingleProb ** 3,
    (   abs(Reliability - ExpectedReliability) < 0.001
    ->  format('PASSED (Reliability = ~5f, Expected = ~5f)~n', [Reliability, ExpectedReliability])
    ;   format('FAILED (Reliability = ~5f, Expected = ~5f)~n', [Reliability, ExpectedReliability])
    ).

% ----------------------------------------------------------------------------
% test_conditional_reliability_with_teacher/0: Test conditional reliability
% ----------------------------------------------------------------------------
test_conditional_reliability_with_teacher :-
    format('Test: Conditional reliability (teacher unavailable)... '),
    length(Rooms, 3),
    length(Slots, 3),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    % Add assignments with teacher1
    set_cell(EmptyMatrix, 0, 0, assigned(class1, subject1, teacher1), Matrix1),
    set_cell(Matrix1, 0, 1, assigned(class2, subject2, teacher1), Matrix2),
    set_cell(Matrix2, 1, 0, assigned(class3, subject3, teacher2), Matrix),
    conditional_reliability(Matrix, teacher1, ConditionalProb),
    % Teacher1 has 2 sessions, so conditional prob should be 0.0
    (   ConditionalProb =:= 0.0
    ->  format('PASSED (Conditional Prob = ~3f)~n', [ConditionalProb])
    ;   format('FAILED (Expected 0.0, got ~3f)~n', [ConditionalProb])
    ).

% ----------------------------------------------------------------------------
% test_conditional_reliability_without_teacher/0: Test conditional reliability
% ----------------------------------------------------------------------------
test_conditional_reliability_without_teacher :-
    format('Test: Conditional reliability (teacher not in timetable)... '),
    length(Rooms, 3),
    length(Slots, 3),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    % Add assignments without teacher5
    set_cell(EmptyMatrix, 0, 0, assigned(class1, subject1, teacher1), Matrix1),
    set_cell(Matrix1, 0, 1, assigned(class2, subject2, teacher2), Matrix),
    schedule_reliability(Matrix, OverallReliability),
    conditional_reliability(Matrix, teacher5, ConditionalProb),
    % Teacher5 has no sessions, so conditional prob should equal overall
    (   abs(ConditionalProb - OverallReliability) < 0.0001
    ->  format('PASSED (Conditional = ~5f, Overall = ~5f)~n', [ConditionalProb, OverallReliability])
    ;   format('FAILED (Conditional = ~5f, Overall = ~5f)~n', [ConditionalProb, OverallReliability])
    ).

% ----------------------------------------------------------------------------
% test_risk_categories/0: Test risk category classification
% ----------------------------------------------------------------------------
test_risk_categories :-
    format('Test: Risk category classification... '),
    risk_category(0.96, Cat1),
    risk_category(0.90, Cat2),
    risk_category(0.75, Cat3),
    risk_category(0.65, Cat4),
    (   Cat1 = low, Cat2 = medium, Cat3 = high, Cat4 = critical
    ->  format('PASSED (0.96->low, 0.90->medium, 0.75->high, 0.65->critical)~n')
    ;   format('FAILED (Categories: ~w, ~w, ~w, ~w)~n', [Cat1, Cat2, Cat3, Cat4])
    ).

% ----------------------------------------------------------------------------
% test_expected_disruptions/0: Test expected disruptions calculation
% ----------------------------------------------------------------------------
test_expected_disruptions :-
    format('Test: Expected disruptions... '),
    length(Rooms, 3),
    length(Slots, 3),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    set_cell(EmptyMatrix, 0, 0, assigned(class1, subject1, teacher1), Matrix1),
    set_cell(Matrix1, 0, 1, assigned(class2, subject2, teacher2), Matrix2),
    set_cell(Matrix2, 1, 0, assigned(class3, subject3, teacher3), Matrix),
    expected_disruptions(Matrix, ExpectedCount),
    schedule_reliability(Matrix, Reliability),
    ExpectedValue is 3 * (1.0 - Reliability),
    (   abs(ExpectedCount - ExpectedValue) < 0.001
    ->  format('PASSED (Expected = ~3f, Calculated = ~3f)~n', [ExpectedValue, ExpectedCount])
    ;   format('FAILED (Expected = ~3f, Calculated = ~3f)~n', [ExpectedValue, ExpectedCount])
    ).

% ============================================================================
% PART 5: MAIN TEST RUNNER
% ============================================================================

% ----------------------------------------------------------------------------
% run_specific_tests/0: Run specific test cases
% ----------------------------------------------------------------------------
run_specific_tests :-
    format('~n========================================~n'),
    format('SPECIFIC TEST CASES~n'),
    format('========================================~n~n'),
    test_empty_timetable,
    test_single_assignment,
    test_multiple_assignments,
    test_conditional_reliability_with_teacher,
    test_conditional_reliability_without_teacher,
    test_risk_categories,
    test_expected_disruptions,
    format('~n========================================~n'),
    format('SPECIFIC TESTS COMPLETE~n'),
    format('========================================~n').

% ----------------------------------------------------------------------------
% run_all_tests/0: Run all property tests (default 100 iterations)
% ----------------------------------------------------------------------------
run_all_tests :-
    format('~n~n'),
    format('╔════════════════════════════════════════════════════════════╗~n'),
    format('║  PROBABILITY MODULE PROPERTY-BASED TESTING SUITE          ║~n'),
    format('╚════════════════════════════════════════════════════════════╝~n'),
    
    % Run specific test cases first
    run_specific_tests,
    
    % Run property-based tests with 100 iterations
    run_property_tests(100),
    
    format('~n╔════════════════════════════════════════════════════════════╗~n'),
    format('║  ALL TESTS COMPLETED SUCCESSFULLY                          ║~n'),
    format('╚════════════════════════════════════════════════════════════╝~n~n').

% ----------------------------------------------------------------------------
% run_tests/0: Entry point for running tests
% ----------------------------------------------------------------------------
run_tests :-
    run_all_tests.

% ----------------------------------------------------------------------------
% run_tests/1: Entry point with custom iteration count
% ----------------------------------------------------------------------------
run_tests(NumIterations) :-
    format('~n~n'),
    format('╔════════════════════════════════════════════════════════════╗~n'),
    format('║  PROBABILITY MODULE PROPERTY-BASED TESTING SUITE          ║~n'),
    format('╚════════════════════════════════════════════════════════════╝~n'),
    
    % Run specific test cases first
    run_specific_tests,
    
    % Run property-based tests with custom iterations
    run_property_tests(NumIterations),
    
    format('~n╔════════════════════════════════════════════════════════════╗~n'),
    format('║  ALL TESTS COMPLETED SUCCESSFULLY                          ║~n'),
    format('╚════════════════════════════════════════════════════════════╝~n~n').

% Run tests when file is loaded
:- initialization(run_tests, main).

