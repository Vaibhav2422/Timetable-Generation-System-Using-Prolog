% Simple test without modules to verify constraint logic

% Load all files without module system
:- consult('../data/dataset.pl').
:- consult('knowledge_base.pl').
:- consult('matrix_model.pl').
:- consult('constraints.pl').

test_basic :-
    write('Testing basic predicates...'), nl,
    % Test 1: Check if t1 is qualified for s1
    write('Test 1: t1 qualified for s1? '),
    (qualified(t1, s1) -> write('YES') ; write('NO')), nl,
    
    % Test 2: Check if r1 is suitable for theory
    write('Test 2: r1 suitable for theory? '),
    (suitable_room(r1, theory) -> write('YES') ; write('NO')), nl,
    
    % Test 3: Check teacher availability
    write('Test 3: t1 available at slot1? '),
    (teacher_available(t1, slot1) -> write('YES') ; write('NO')), nl,
    
    % Test 4: Check consecutive slots
    write('Test 4: slot1 and slot2 consecutive? '),
    (check_consecutive_slots(slot1, slot2) -> write('YES') ; write('NO')), nl,
    
    % Test 5: Create empty matrix and test
    write('Test 5: Creating empty matrix... '),
    create_empty_timetable([r1, r2], [slot1, slot2], Matrix),
    (is_list(Matrix) -> write('SUCCESS') ; write('FAILED')), nl.

:- initialization(test_basic, main).
