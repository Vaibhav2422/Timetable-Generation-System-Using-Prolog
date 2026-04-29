% test_probability_integration.pl
% Integration test for probability_module with realistic timetable data

:- use_module(probability_module).
:- use_module(matrix_model).

% Test with a realistic timetable scenario
test_realistic_timetable :-
    write('========================================'), nl,
    write('PROBABILITY MODULE INTEGRATION TEST'), nl,
    write('========================================'), nl, nl,
    
    % Create a realistic timetable with 6 rooms and 5 time slots
    % Room 1: 3 classes scheduled
    % Room 2: 2 classes scheduled
    % Room 3: 1 class scheduled
    % Room 4-6: Empty
    Matrix = [
        [assigned(class1, math, teacher1), assigned(class2, physics, teacher2), assigned(class1, chemistry, teacher3), empty, empty],
        [assigned(class3, biology, teacher1), empty, assigned(class2, math, teacher2), empty, empty],
        [empty, assigned(class1, physics, teacher4), empty, empty, empty],
        [empty, empty, empty, empty, empty],
        [empty, empty, empty, empty, empty],
        [empty, empty, empty, empty, empty]
    ],
    
    write('Timetable Configuration:'), nl,
    write('  - 6 rooms, 5 time slots'), nl,
    write('  - 6 total assignments'), nl,
    write('  - 4 teachers involved'), nl,
    write('  - 3 classes scheduled'), nl, nl,
    
    % Test 1: Overall reliability
    write('Test 1: Overall Schedule Reliability'), nl,
    schedule_reliability(Matrix, Reliability),
    format('  Reliability Score: ~5f~n', [Reliability]),
    risk_category(Reliability, Category),
    format('  Risk Category: ~w~n', [Category]),
    nl,
    
    % Test 2: Expected disruptions
    write('Test 2: Expected Disruptions'), nl,
    expected_disruptions(Matrix, ExpectedCount),
    format('  Expected disruptions: ~3f sessions~n', [ExpectedCount]),
    get_all_assignments(Matrix, Assignments),
    length(Assignments, TotalSessions),
    format('  Total sessions: ~w~n', [TotalSessions]),
    SuccessRate is (TotalSessions - ExpectedCount) / TotalSessions * 100,
    format('  Expected success rate: ~2f%~n', [SuccessRate]),
    nl,
    
    % Test 3: Conditional reliability (teacher1 unavailable)
    write('Test 3: Conditional Reliability (Teacher1 Unavailable)'), nl,
    conditional_reliability(Matrix, teacher1, ConditionalProb1),
    format('  P(Schedule valid | teacher1 unavailable): ~5f~n', [ConditionalProb1]),
    write('  Note: Teacher1 has 2 sessions, so probability is 0.0'), nl,
    nl,
    
    % Test 4: Conditional reliability (teacher4 unavailable)
    write('Test 4: Conditional Reliability (Teacher4 Unavailable)'), nl,
    conditional_reliability(Matrix, teacher4, ConditionalProb4),
    format('  P(Schedule valid | teacher4 unavailable): ~5f~n', [ConditionalProb4]),
    write('  Note: Teacher4 has 1 session, so probability is 0.0'), nl,
    nl,
    
    % Test 5: Bayesian reliability with evidence
    write('Test 5: Bayesian Reliability (Teacher Absent)'), nl,
    bayesian_reliability(Matrix, evidence(teacher_absent, teacher2), PosteriorProb),
    format('  Prior probability: ~5f~n', [Reliability]),
    format('  Posterior probability (teacher2 absent): ~5f~n', [PosteriorProb]),
    nl,
    
    % Test 6: Individual assignment reliabilities
    write('Test 6: Individual Assignment Reliabilities'), nl,
    get_all_assignments(Matrix, AllAssignments),
    calculate_assignment_reliabilities(AllAssignments, Probabilities),
    write('  Assignment probabilities:'), nl,
    print_assignment_probabilities(AllAssignments, Probabilities),
    nl,
    
    % Test 7: Risk categories for different scenarios
    write('Test 7: Risk Category Analysis'), nl,
    test_risk_scenarios,
    nl,
    
    write('========================================'), nl,
    write('INTEGRATION TEST COMPLETE'), nl,
    write('All tests executed successfully'), nl,
    write('========================================'), nl.

% Helper to print assignment probabilities
print_assignment_probabilities([], []).
print_assignment_probabilities([assigned(Class, Subject, Teacher)|RestA], [Prob|RestP]) :-
    format('    ~w - ~w (Teacher: ~w): ~5f~n', [Class, Subject, Teacher, Prob]),
    print_assignment_probabilities(RestA, RestP).

% Test different risk scenarios
test_risk_scenarios :-
    write('  Testing risk categories:'), nl,
    
    % Scenario 1: High reliability (1 assignment)
    Matrix1 = [[assigned(class1, math, teacher1)]],
    schedule_reliability(Matrix1, R1),
    risk_category(R1, Cat1),
    format('    1 assignment: ~5f -> ~w~n', [R1, Cat1]),
    
    % Scenario 2: Medium reliability (5 assignments)
    Matrix2 = [
        [assigned(class1, math, teacher1), assigned(class2, physics, teacher2)],
        [assigned(class1, chemistry, teacher3), assigned(class3, biology, teacher1)],
        [assigned(class2, math, teacher2), empty]
    ],
    schedule_reliability(Matrix2, R2),
    risk_category(R2, Cat2),
    format('    5 assignments: ~5f -> ~w~n', [R2, Cat2]),
    
    % Scenario 3: Lower reliability (10 assignments)
    Matrix3 = [
        [assigned(c1, s1, t1), assigned(c2, s2, t2), assigned(c3, s3, t3)],
        [assigned(c1, s4, t1), assigned(c2, s5, t2), assigned(c3, s6, t3)],
        [assigned(c1, s7, t1), assigned(c2, s8, t2), assigned(c3, s9, t3)],
        [assigned(c1, s10, t1), empty, empty]
    ],
    schedule_reliability(Matrix3, R3),
    risk_category(R3, Cat3),
    format('    10 assignments: ~5f -> ~w~n', [R3, Cat3]).

% Entry point
:- initialization(test_realistic_timetable, main).
