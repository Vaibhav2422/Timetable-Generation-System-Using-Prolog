% test_probability.pl
% Test file for probability_module.pl

:- use_module(probability_module).
:- use_module(matrix_model).

% Test 1: Basic reliability calculation
test_basic_reliability :-
    write('Test 1: Basic reliability calculation... '),
    % Create a simple timetable with 3 assignments
    Matrix = [
        [assigned(class1, math, teacher1), assigned(class2, physics, teacher2), empty],
        [empty, assigned(class1, chemistry, teacher3), empty]
    ],
    schedule_reliability(Matrix, Reliability),
    % Expected: 0.95 * 0.98 * 0.99 = 0.92169 per assignment
    % For 3 assignments: 0.92169^3 ≈ 0.783
    Reliability >= 0.78,
    Reliability =< 0.79,
    write('PASSED'), nl,
    format('  Reliability: ~3f~n', [Reliability]).

% Test 2: Assignment reliability
test_assignment_reliability :-
    write('Test 2: Assignment reliability... '),
    assignment_reliability(assigned(class1, math, teacher1), Prob),
    % Expected: 0.95 * 0.98 * 0.99 = 0.92169
    ExpectedProb is 0.95 * 0.98 * 0.99,
    abs(Prob - ExpectedProb) < 0.0001,
    write('PASSED'), nl,
    format('  Probability: ~5f (Expected: ~5f)~n', [Prob, ExpectedProb]).

% Test 3: Combine probabilities
test_combine_probabilities :-
    write('Test 3: Combine probabilities... '),
    combine_probabilities([0.95, 0.98, 0.99], Total),
    ExpectedTotal is 0.95 * 0.98 * 0.99,
    abs(Total - ExpectedTotal) < 0.0001,
    write('PASSED'), nl,
    format('  Combined: ~5f (Expected: ~5f)~n', [Total, ExpectedTotal]).

% Test 4: Empty timetable reliability
test_empty_timetable :-
    write('Test 4: Empty timetable reliability... '),
    Matrix = [[empty, empty], [empty, empty]],
    schedule_reliability(Matrix, Reliability),
    Reliability =:= 1.0,  % No assignments = perfect reliability
    write('PASSED'), nl,
    format('  Reliability: ~3f~n', [Reliability]).

% Test 5: Risk category classification
test_risk_category :-
    write('Test 5: Risk category classification... '),
    risk_category(0.96, Cat1), Cat1 = low,
    risk_category(0.90, Cat2), Cat2 = medium,
    risk_category(0.75, Cat3), Cat3 = high,
    risk_category(0.65, Cat4), Cat4 = critical,
    write('PASSED'), nl,
    write('  0.96 -> low, 0.90 -> medium, 0.75 -> high, 0.65 -> critical'), nl.

% Test 6: Expected disruptions
test_expected_disruptions :-
    write('Test 6: Expected disruptions... '),
    Matrix = [
        [assigned(class1, math, teacher1), assigned(class2, physics, teacher2)],
        [assigned(class1, chemistry, teacher3), empty]
    ],
    expected_disruptions(Matrix, ExpectedCount),
    % 3 assignments, reliability ≈ 0.783, disruptions ≈ 3 * (1 - 0.783) = 0.651
    ExpectedCount >= 0.6,
    ExpectedCount =< 0.7,
    write('PASSED'), nl,
    format('  Expected disruptions: ~3f~n', [ExpectedCount]).

% Test 7: Conditional reliability (teacher unavailable)
test_conditional_reliability :-
    write('Test 7: Conditional reliability (teacher unavailable)... '),
    Matrix = [
        [assigned(class1, math, teacher1), assigned(class2, physics, teacher2)],
        [assigned(class1, chemistry, teacher1), empty]
    ],
    conditional_reliability(Matrix, teacher1, ConditionalProb),
    % Teacher1 has 2 sessions, so if unavailable, conditional prob = 0
    ConditionalProb =:= 0.0,
    write('PASSED'), nl,
    format('  Conditional probability: ~3f~n', [ConditionalProb]).

% Test 8: Bayesian reliability
test_bayesian_reliability :-
    write('Test 8: Bayesian reliability... '),
    Matrix = [
        [assigned(class1, math, teacher1), assigned(class2, physics, teacher2)],
        [assigned(class1, chemistry, teacher3), empty]
    ],
    bayesian_reliability(Matrix, evidence(teacher_absent, teacher1), PosteriorProb),
    % Posterior should be calculated using Bayes' rule
    PosteriorProb >= 0.0,
    PosteriorProb =< 1.0,
    write('PASSED'), nl,
    format('  Posterior probability: ~5f~n', [PosteriorProb]).

% Test 9: Reliability score range validation
test_reliability_range :-
    write('Test 9: Reliability score range validation... '),
    Matrix = [
        [assigned(class1, math, teacher1), assigned(class2, physics, teacher2)],
        [assigned(class1, chemistry, teacher3), assigned(class3, biology, teacher1)]
    ],
    schedule_reliability(Matrix, Reliability),
    Reliability >= 0.0,
    Reliability =< 1.0,
    write('PASSED'), nl,
    format('  Reliability: ~5f (within [0.0, 1.0])~n', [Reliability]).

% Run all tests
run_all_tests :-
    write('========================================'), nl,
    write('PROBABILITY MODULE TESTS'), nl,
    write('========================================'), nl, nl,
    test_basic_reliability,
    test_assignment_reliability,
    test_combine_probabilities,
    test_empty_timetable,
    test_risk_category,
    test_expected_disruptions,
    test_conditional_reliability,
    test_bayesian_reliability,
    test_reliability_range,
    nl,
    write('========================================'), nl,
    write('ALL TESTS PASSED'), nl,
    write('========================================'), nl.

% Entry point
:- initialization(run_all_tests, main).
