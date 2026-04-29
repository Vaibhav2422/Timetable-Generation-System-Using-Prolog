% test_constraints.pl - Unit tests for constraints module
% Tests hard and soft constraint checking predicates

% Load test data first (defines facts)
:- consult('../data/dataset.pl').

% Then load modules
:- use_module(knowledge_base).
:- use_module(matrix_model).
:- use_module(constraints).
:- use_module(library(lists)).

% ============================================================================
% TEST SUITE FOR HARD CONSTRAINTS
% ============================================================================

test_teacher_no_conflict :-
    write('Testing check_teacher_no_conflict/3... '),
    % Create a simple matrix with one assignment
    create_empty_timetable([r1, r2], [slot1, slot2], Matrix),
    set_cell(Matrix, 0, 0, assigned(c1, s1, t1), Matrix1),
    % Test 1: No conflict (teacher t1 at slot1, checking slot2)
    (check_teacher_no_conflict(t1, slot2, Matrix1) ->
        write('PASS (no conflict) ')
    ;
        write('FAIL (no conflict) ')
    ),
    % Test 2: Conflict would occur if we check the same slot
    (check_teacher_no_conflict(t1, slot1, Matrix1) ->
        write('PASS (existing assignment) ')
    ;
        write('FAIL (existing assignment) ')
    ),
    nl.

test_room_no_conflict :-
    write('Testing check_room_no_conflict/3... '),
    % Create a simple matrix
    create_empty_timetable([r1, r2], [slot1, slot2], Matrix),
    set_cell(Matrix, 0, 0, assigned(c1, s1, t1), Matrix1),
    % Test: Room r1 at slot1 should have an assignment
    (check_room_no_conflict(r1, slot1, Matrix1) ->
        write('PASS (room has assignment) ')
    ;
        write('FAIL (room has assignment) ')
    ),
    % Test: Room r1 at slot2 should be empty
    (check_room_no_conflict(r1, slot2, Matrix1) ->
        write('PASS (room empty) ')
    ;
        write('FAIL (room empty) ')
    ),
    nl.

test_teacher_qualified :-
    write('Testing check_teacher_qualified/2... '),
    % Test 1: t1 is qualified for s1 (Data Structures)
    (check_teacher_qualified(t1, s1) ->
        write('PASS (qualified) ')
    ;
        write('FAIL (qualified) ')
    ),
    % Test 2: t1 is NOT qualified for s3 (Database Systems)
    (\+ check_teacher_qualified(t1, s3) ->
        write('PASS (not qualified) ')
    ;
        write('FAIL (not qualified) ')
    ),
    nl.

test_room_suitable :-
    write('Testing check_room_suitable/2... '),
    % Test 1: r1 (classroom) is suitable for s1 (theory)
    (check_room_suitable(r1, s1) ->
        write('PASS (classroom for theory) ')
    ;
        write('FAIL (classroom for theory) ')
    ),
    % Test 2: r4 (lab) is suitable for s7 (lab)
    (check_room_suitable(r4, s7) ->
        write('PASS (lab for lab) ')
    ;
        write('FAIL (lab for lab) ')
    ),
    % Test 3: r1 (classroom) is NOT suitable for s7 (lab)
    (\+ check_room_suitable(r1, s7) ->
        write('PASS (classroom not for lab) ')
    ;
        write('FAIL (classroom not for lab) ')
    ),
    nl.

test_room_capacity :-
    write('Testing check_room_capacity/2... '),
    % Test 1: r1 (capacity 50) is sufficient for c1 (size 45)
    (check_room_capacity(r1, c1) ->
        write('PASS (sufficient capacity) ')
    ;
        write('FAIL (sufficient capacity) ')
    ),
    % Test 2: r4 (capacity 30) is NOT sufficient for c1 (size 45)
    (\+ check_room_capacity(r4, c1) ->
        write('PASS (insufficient capacity) ')
    ;
        write('FAIL (insufficient capacity) ')
    ),
    nl.

test_teacher_available :-
    write('Testing check_teacher_available/2... '),
    % Test 1: t1 is available at slot1
    (check_teacher_available(t1, slot1) ->
        write('PASS (available) ')
    ;
        write('FAIL (available) ')
    ),
    % Test 2: t2 is NOT available at slot19 (not in availability list)
    (\+ check_teacher_available(t2, slot19) ->
        write('PASS (not available) ')
    ;
        write('FAIL (not available) ')
    ),
    nl.

test_consecutive_slots :-
    write('Testing check_consecutive_slots/2... '),
    % Test 1: slot1 and slot2 are consecutive (Monday period 1 and 2)
    (check_consecutive_slots(slot1, slot2) ->
        write('PASS (consecutive) ')
    ;
        write('FAIL (consecutive) ')
    ),
    % Test 2: slot1 and slot3 are NOT consecutive
    (\+ check_consecutive_slots(slot1, slot3) ->
        write('PASS (not consecutive) ')
    ;
        write('FAIL (not consecutive) ')
    ),
    % Test 3: slot1 and slot7 are NOT consecutive (different days)
    (\+ check_consecutive_slots(slot1, slot7) ->
        write('PASS (different days) ')
    ;
        write('FAIL (different days) ')
    ),
    nl.

test_all_hard_constraints :-
    write('Testing check_all_hard_constraints/6... '),
    % Create empty matrix
    create_empty_timetable([r1, r2, r3], [slot1, slot2, slot3], Matrix),
    % Test valid assignment: r1, c1, s1, t1, slot1
    % - t1 is qualified for s1
    % - r1 is suitable for s1 (theory)
    % - r1 has capacity for c1
    % - t1 is available at slot1
    % - No conflicts (empty matrix)
    (check_all_hard_constraints(r1, c1, s1, t1, slot1, Matrix) ->
        write('PASS (valid assignment) ')
    ;
        write('FAIL (valid assignment) ')
    ),
    % Test invalid assignment: r1, c1, s3, t1, slot1
    % - t1 is NOT qualified for s3
    (\+ check_all_hard_constraints(r1, c1, s3, t1, slot1, Matrix) ->
        write('PASS (invalid - not qualified) ')
    ;
        write('FAIL (invalid - not qualified) ')
    ),
    nl.

% ============================================================================
% TEST SUITE FOR SOFT CONSTRAINTS
% ============================================================================

test_group_by_day :-
    write('Testing group_by_day/2... '),
    % Test with slots from different days
    group_by_day([slot1, slot2, slot7, slot8], DayGroups),
    (member(monday-2, DayGroups), member(tuesday-2, DayGroups) ->
        write('PASS (grouped correctly) ')
    ;
        write('FAIL (grouped correctly) ')
    ),
    nl.

test_soft_avoid_late_theory :-
    write('Testing soft_avoid_late_theory/3... '),
    % Test 1: Theory class in early slot (period 1) should score 1.0
    soft_avoid_late_theory(s1, slot1, Score1),
    (Score1 =:= 1.0 ->
        write('PASS (early theory) ')
    ;
        write('FAIL (early theory) ')
    ),
    % Test 2: Lab class in late slot should still score 1.0 (only penalizes theory)
    soft_avoid_late_theory(s7, slot6, Score2),
    (Score2 =:= 1.0 ->
        write('PASS (late lab) ')
    ;
        write('FAIL (late lab) ')
    ),
    nl.

test_count_gaps :-
    write('Testing count_gaps/2... '),
    % Test 1: No gaps (consecutive slots)
    count_gaps([slot1, slot2, slot3], Gaps1),
    (Gaps1 =:= 0 ->
        write('PASS (no gaps) ')
    ;
        write('FAIL (no gaps) ')
    ),
    % Test 2: One gap (slot1, slot3 - missing slot2)
    count_gaps([slot1, slot3], Gaps2),
    (Gaps2 =:= 1 ->
        write('PASS (one gap) ')
    ;
        write('FAIL (one gap) ')
    ),
    nl.

% ============================================================================
% RUN ALL TESTS
% ============================================================================

run_all_tests :-
    nl,
    write('========================================'), nl,
    write('CONSTRAINTS MODULE TEST SUITE'), nl,
    write('========================================'), nl,
    nl,
    write('--- Hard Constraint Tests ---'), nl,
    test_teacher_no_conflict,
    test_room_no_conflict,
    test_teacher_qualified,
    test_room_suitable,
    test_room_capacity,
    test_teacher_available,
    test_consecutive_slots,
    test_all_hard_constraints,
    nl,
    write('--- Soft Constraint Tests ---'), nl,
    test_group_by_day,
    test_soft_avoid_late_theory,
    test_count_gaps,
    nl,
    write('========================================'), nl,
    write('TEST SUITE COMPLETE'), nl,
    write('========================================'), nl,
    nl.

% Run tests when file is loaded
:- initialization(run_all_tests).
