%% ============================================================================
%% test_api_server.pl - Unit Tests for API Server Module
%% ============================================================================
%% This file contains unit tests for the api_server module.
%%
%% Author: AI Timetable Generation System
%% ============================================================================

:- use_module(api_server).
:- use_module(knowledge_base).
:- use_module(logging).

%% ============================================================================
%% Test Runner
%% ============================================================================

run_all_tests :-
    log_info('Starting API server tests'),
    test_cors_headers,
    test_validate_resource_data,
    test_sanitize_inputs,
    test_store_resources,
    test_format_user_error,
    test_calculate_analytics,
    log_info('All API server tests completed').

%% ============================================================================
%% Test Cases
%% ============================================================================

%% Test CORS headers
test_cors_headers :-
    log_info('Testing CORS headers'),
    % CORS headers should succeed without error
    (cors_headers ->
        log_info('✓ CORS headers test passed')
    ;
        log_error('✗ CORS headers test failed')
    ).

%% Test resource data validation
test_validate_resource_data :-
    log_info('Testing resource data validation'),
    % Test with valid data
    ValidData = _{type: teacher, id: t1, name: 'Test Teacher', 
                  qualified_subjects: [math], max_load: 20, availability: [1,2,3]},
    (validate_resource_data(ValidData, _) ->
        log_info('✓ Valid resource data test passed')
    ;
        log_error('✗ Valid resource data test failed')
    ).

%% Test input sanitization
test_sanitize_inputs :-
    log_info('Testing input sanitization'),
    TestData = _{field1: value1, field2: value2},
    (sanitize_inputs(TestData, Sanitized), is_dict(Sanitized) ->
        log_info('✓ Input sanitization test passed')
    ;
        log_error('✗ Input sanitization test failed')
    ).

%% Test resource storage
test_store_resources :-
    log_info('Testing resource storage'),
    % Clean up any existing test data
    retractall(teacher(test_t1, _, _, _, _)),
    % Test storing a teacher
    TeacherData = _{type: teacher, id: test_t1, name: 'Test Teacher',
                    qualified_subjects: [math], max_load: 20, availability: [1,2,3]},
    (store_resources(TeacherData),
     teacher(test_t1, 'Test Teacher', [math], 20, [1,2,3]) ->
        log_info('✓ Resource storage test passed'),
        retractall(teacher(test_t1, _, _, _, _))
    ;
        log_error('✗ Resource storage test failed'),
        retractall(teacher(test_t1, _, _, _, _))
    ).

%% Test error formatting
test_format_user_error :-
    log_info('Testing error formatting'),
    % Test with atom error
    (format_user_error('Test error', Msg1), atom(Msg1) ->
        log_info('✓ Atom error formatting test passed')
    ;
        log_error('✗ Atom error formatting test failed')
    ),
    % Test with structured error
    (format_user_error(error(test_type, 'Test context'), Msg2), atom(Msg2) ->
        log_info('✓ Structured error formatting test passed')
    ;
        log_error('✗ Structured error formatting test failed')
    ).

%% Test analytics calculation
test_calculate_analytics :-
    log_info('Testing analytics calculation'),
    % Set up test data
    assertz(teacher(t1, 'Teacher 1', [math], 20, [1,2,3])),
    assertz(teacher(t2, 'Teacher 2', [physics], 20, [1,2,3])),
    assertz(room(r1, 'Room 1', 30, classroom)),
    assertz(room(r2, 'Room 2', 30, lab)),
    assertz(timeslot(s1, monday, 1, '09:00', 1)),
    assertz(timeslot(s2, monday, 2, '10:00', 1)),
    assertz(timeslot(s3, monday, 3, '11:00', 1)),
    
    % Create a simple timetable matrix
    Matrix = [
        [assigned(r1, c1, math, t1, s1), assigned(r1, c1, math, t1, s2), empty],
        [assigned(r2, c2, physics, t2, s1), empty, empty]
    ],
    
    % Test analytics calculation
    (calculate_analytics(Matrix, Analytics),
     is_dict(Analytics),
     get_dict(teacher_workload, Analytics, _),
     get_dict(room_utilization, Analytics, _),
     get_dict(schedule_density, Analytics, _) ->
        log_info('✓ Analytics calculation test passed')
    ;
        log_error('✗ Analytics calculation test failed')
    ),
    
    % Clean up
    retractall(teacher(t1, _, _, _, _)),
    retractall(teacher(t2, _, _, _, _)),
    retractall(room(r1, _, _, _)),
    retractall(room(r2, _, _, _)),
    retractall(timeslot(s1, _, _, _, _)),
    retractall(timeslot(s2, _, _, _, _)),
    retractall(timeslot(s3, _, _, _, _)).

%% ============================================================================
%% Main Entry Point
%% ============================================================================

:- initialization(run_all_tests, main).
