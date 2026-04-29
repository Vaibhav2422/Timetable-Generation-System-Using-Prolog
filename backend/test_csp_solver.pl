% test_csp_solver.pl
% Simple tests for CSP solver module

:- use_module(csp_solver).
:- use_module(knowledge_base).
:- use_module(matrix_model).
:- use_module(constraints).

% Test data
:- dynamic teacher/5, subject/5, room/4, timeslot/5, class/3, class_size/2.

setup_test_data :-
    % Clear existing data
    retractall(teacher(_, _, _, _, _)),
    retractall(subject(_, _, _, _, _)),
    retractall(room(_, _, _, _)),
    retractall(timeslot(_, _, _, _, _)),
    retractall(class(_, _, _)),
    retractall(class_size(_, _)),
    
    % Add test teachers
    assertz(teacher(t1, 'Dr. Smith', [math, physics], 20, [s1, s2, s3])),
    assertz(teacher(t2, 'Prof. Jones', [cs, math], 20, [s1, s2, s3])),
    
    % Add test subjects
    assertz(subject(math, 'Mathematics', 2, theory, 1)),
    assertz(subject(cs, 'Computer Science', 2, theory, 1)),
    
    % Add test rooms
    assertz(room(r1, 'Room 101', 50, classroom)),
    assertz(room(r2, 'Room 102', 50, classroom)),
    
    % Add test timeslots
    assertz(timeslot(s1, monday, 1, '09:00', 1)),
    assertz(timeslot(s2, monday, 2, '10:00', 1)),
    assertz(timeslot(s3, monday, 3, '11:00', 1)),
    
    % Add test class
    assertz(class(c1, 'Class 1A', [math, cs])),
    assertz(class_size(c1, 30)).

% Test 1: Domain initialization
test_domain_initialization :-
    write('Test 1: Domain initialization... '),
    setup_test_data,
    Sessions = [session(c1, math), session(c1, cs)],
    initialize_domains(Sessions, Domains),
    length(Domains, NumDomains),
    (NumDomains = 2 ->
        write('PASSED\n')
    ;
        write('FAILED\n')
    ).

% Test 2: Domain generation
test_domain_generation :-
    write('Test 2: Domain generation... '),
    setup_test_data,
    generate_domain(session(c1, math), Domain),
    length(Domain, DomainSize),
    (DomainSize > 0 ->
        write('PASSED (domain size: '), write(DomainSize), write(')\n')
    ;
        write('FAILED (empty domain)\n')
    ).

% Test 3: Get domain
test_get_domain :-
    write('Test 3: Get domain... '),
    setup_test_data,
    Sessions = [session(c1, math)],
    initialize_domains(Sessions, Domains),
    get_domain(session(c1, math), Domains, Domain),
    (Domain \= [] ->
        write('PASSED\n')
    ;
        write('FAILED\n')
    ).

% Test 4: Update domain
test_update_domain :-
    write('Test 4: Update domain... '),
    setup_test_data,
    Sessions = [session(c1, math)],
    initialize_domains(Sessions, Domains),
    update_domain(session(c1, math), [value(t1, r1, s1)], Domains, NewDomains),
    get_domain(session(c1, math), NewDomains, NewDomain),
    length(NewDomain, Size),
    (Size = 1 ->
        write('PASSED\n')
    ;
        write('FAILED\n')
    ).

% Test 5: Empty domain detection
test_empty_domain :-
    write('Test 5: Empty domain detection... '),
    Domains = [session(c1, math)-[], session(c1, cs)-[value(t1, r1, s1)]],
    (has_empty_domain(Domains) ->
        write('PASSED\n')
    ;
        write('FAILED\n')
    ).

% Test 6: Conflicts detection
test_conflicts :-
    write('Test 6: Conflicts detection... '),
    Value1 = value(t1, r1, s1),
    Value2 = value(t1, r2, s1),  % Same teacher, same slot
    (conflicts_with(Value1, _, Value2) ->
        write('PASSED\n')
    ;
        write('FAILED\n')
    ).

% Test 7: No conflicts
test_no_conflicts :-
    write('Test 7: No conflicts detection... '),
    Value1 = value(t1, r1, s1),
    Value2 = value(t2, r2, s2),  % Different teacher, different slot
    (\+ conflicts_with(Value1, _, Value2) ->
        write('PASSED\n')
    ;
        write('FAILED\n')
    ).

% Test 8: Variable selection (MRV)
test_variable_selection :-
    write('Test 8: Variable selection (MRV)... '),
    setup_test_data,
    Sessions = [session(c1, math), session(c1, cs)],
    Domains = [
        session(c1, math)-[value(t1, r1, s1)],
        session(c1, cs)-[value(t2, r1, s1), value(t2, r2, s1)]
    ],
    select_variable(Sessions, Domains, Selected, _),
    (Selected = session(c1, math) ->
        write('PASSED\n')
    ;
        write('FAILED\n')
    ).

% Run all tests
run_tests :-
    write('\n=== CSP Solver Module Tests ===\n\n'),
    test_domain_initialization,
    test_domain_generation,
    test_get_domain,
    test_update_domain,
    test_empty_domain,
    test_conflicts,
    test_no_conflicts,
    test_variable_selection,
    write('\n=== Tests Complete ===\n\n').

% Run tests on load
:- initialization(run_tests).
