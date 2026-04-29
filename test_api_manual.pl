% test_api_manual.pl - Manual API testing script
% This script tests API functionality directly without HTTP

:- use_module(backend/logging).
:- use_module(backend/knowledge_base).
:- use_module(backend/matrix_model).
:- use_module(backend/constraints).
:- use_module(backend/csp_solver).
:- use_module(backend/probability_module).
:- use_module(backend/timetable_generator).
:- use_module(backend/api_server).

% Load dataset
:- consult('data/dataset.pl').

test_all :-
    writeln('==========================================='),
    writeln('API Functionality Tests'),
    writeln('==========================================='),
    writeln(''),
    
    % Test 1: Resource retrieval
    writeln('Test 1: Resource Retrieval'),
    (   get_all_teachers(Teachers),
        length(Teachers, NumTeachers),
        format('  ✓ Retrieved ~w teachers~n', [NumTeachers])
    ;   writeln('  ✗ Failed to retrieve teachers')
    ),
    writeln(''),
    
    % Test 2: Timetable generation
    writeln('Test 2: Timetable Generation'),
    (   generate_timetable(Timetable),
        writeln('  ✓ Timetable generated successfully')
    ;   writeln('  ✗ Timetable generation failed')
    ),
    writeln(''),
    
    % Test 3: Reliability calculation
    writeln('Test 3: Reliability Calculation'),
    (   current_predicate(current_timetable/1),
        current_timetable(TT),
        schedule_reliability(TT, Reliability),
        format('  ✓ Reliability: ~3f~n', [Reliability])
    ;   writeln('  ✗ Reliability calculation failed')
    ),
    writeln(''),
    
    % Test 4: Conflict detection
    writeln('Test 4: Conflict Detection'),
    (   current_timetable(TT2),
        detect_conflicts(TT2, Conflicts),
        length(Conflicts, NumConflicts),
        format('  ✓ Found ~w conflicts~n', [NumConflicts])
    ;   writeln('  ✗ Conflict detection failed')
    ),
    writeln(''),
    
    % Test 5: Analytics calculation
    writeln('Test 5: Analytics Calculation'),
    (   current_timetable(TT3),
        calculate_analytics(TT3, Analytics),
        writeln('  ✓ Analytics calculated successfully')
    ;   writeln('  ✗ Analytics calculation failed')
    ),
    writeln(''),
    
    writeln('==========================================='),
    writeln('All tests completed'),
    writeln('===========================================').

:- initialization(test_all, main).
