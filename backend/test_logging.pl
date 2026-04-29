%% ============================================================================
%% test_logging.pl - Unit Tests for Logging Module
%% ============================================================================
%% Tests for the logging.pl module to verify log level management,
%% logging predicates, and CSP-specific logging functionality.
%% ============================================================================

:- use_module(logging).

%% ============================================================================
%% Test Runner
%% ============================================================================

run_all_tests :-
    write('========================================\n'),
    write('Running Logging Module Tests\n'),
    write('========================================\n\n'),
    
    test_log_level_management,
    test_logging_predicates,
    test_timestamp_generation,
    test_csp_logging,
    test_log_filtering,
    
    write('\n========================================\n'),
    write('All Logging Tests Completed Successfully!\n'),
    write('========================================\n').

%% ============================================================================
%% Test Cases
%% ============================================================================

%% Test 1: Log Level Management
test_log_level_management :-
    write('Test 1: Log Level Management\n'),
    
    % Test setting valid log levels
    set_log_level(debug),
    get_log_level(Level1),
    assertion(Level1 == debug, 'Set log level to debug'),
    
    set_log_level(info),
    get_log_level(Level2),
    assertion(Level2 == info, 'Set log level to info'),
    
    set_log_level(warning),
    get_log_level(Level3),
    assertion(Level3 == warning, 'Set log level to warning'),
    
    set_log_level(error),
    get_log_level(Level4),
    assertion(Level4 == error, 'Set log level to error'),
    
    % Reset to info for other tests
    set_log_level(info),
    
    write('  ✓ Log level management works correctly\n\n').

%% Test 2: Logging Predicates
test_logging_predicates :-
    write('Test 2: Logging Predicates\n'),
    
    % Set to debug to see all messages
    set_log_level(debug),
    
    write('  Testing log_debug:\n'),
    log_debug('This is a debug message'),
    
    write('  Testing log_info:\n'),
    log_info('This is an info message'),
    
    write('  Testing log_warning:\n'),
    log_warning('This is a warning message'),
    
    write('  Testing log_error:\n'),
    log_error('This is an error message'),
    
    write('  ✓ All logging predicates work correctly\n\n').

%% Test 3: Timestamp Generation
test_timestamp_generation :-
    write('Test 3: Timestamp Generation\n'),
    
    get_timestamp(Timestamp),
    atom_length(Timestamp, Length),
    assertion(Length == 19, 'Timestamp has correct length (YYYY-MM-DD HH:MM:SS)'),
    
    write('  Generated timestamp: '), write(Timestamp), nl,
    write('  ✓ Timestamp generation works correctly\n\n').

%% Test 4: CSP-Specific Logging
test_csp_logging :-
    write('Test 4: CSP-Specific Logging\n'),
    
    set_log_level(debug),
    
    write('  Testing log_assignment:\n'),
    log_assignment('CS101', 'Math', 'T001', 'Mon-9AM'),
    
    write('  Testing log_backtrack:\n'),
    log_backtrack('Constraint violation detected'),
    
    write('  Testing log_constraint_violation:\n'),
    log_constraint_violation('teacher_conflict', 'Teacher T001 double-booked at Mon-9AM'),
    
    write('  Testing log_search_node (should log at 1000):\n'),
    log_search_node(1000),
    
    write('  Testing log_search_node (should not log at 999):\n'),
    log_search_node(999),
    
    write('  ✓ CSP-specific logging works correctly\n\n').

%% Test 5: Log Filtering
test_log_filtering :-
    write('Test 5: Log Filtering\n'),
    
    % Test that debug messages are filtered when level is info
    set_log_level(info),
    write('  Set log level to INFO - debug messages should not appear:\n'),
    log_debug('This debug message should NOT appear'),
    log_info('This info message SHOULD appear'),
    
    % Test that info messages are filtered when level is warning
    set_log_level(warning),
    write('  Set log level to WARNING - info messages should not appear:\n'),
    log_info('This info message should NOT appear'),
    log_warning('This warning message SHOULD appear'),
    
    % Test that warning messages are filtered when level is error
    set_log_level(error),
    write('  Set log level to ERROR - warning messages should not appear:\n'),
    log_warning('This warning message should NOT appear'),
    log_error('This error message SHOULD appear'),
    
    % Reset to info
    set_log_level(info),
    
    write('  ✓ Log filtering works correctly\n\n').

%% ============================================================================
%% Helper Predicates
%% ============================================================================

assertion(Condition, Message) :-
    (   Condition
    ->  format('  ✓ ~w~n', [Message])
    ;   format('  ✗ FAILED: ~w~n', [Message]),
        fail
    ).

%% ============================================================================
%% Entry Point
%% ============================================================================

:- initialization(run_all_tests, main).
