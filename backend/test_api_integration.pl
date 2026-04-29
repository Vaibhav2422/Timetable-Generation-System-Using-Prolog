%% ============================================================================
%% test_api_integration.pl - Integration Tests for API Server
%% ============================================================================
%% This file contains integration tests that verify the API server works
%% correctly with the full timetable generation system.
%%
%% Author: AI Timetable Generation System
%% ============================================================================

:- use_module(api_server).
:- use_module(knowledge_base).
:- use_module(timetable_generator).
:- use_module(probability_module).
:- use_module(logging).

%% Load sample data
:- consult('../data/dataset.pl').

%% ============================================================================
%% Test Runner
%% ============================================================================

run_integration_tests :-
    log_info('Starting API server integration tests'),
    test_full_workflow,
    test_analytics_with_real_data,
    test_conflict_detection,
    test_export_formats,
    log_info('All API server integration tests completed').

%% ============================================================================
%% Integration Test Cases
%% ============================================================================

%% Test full workflow: generate -> retrieve -> analyze
test_full_workflow :-
    log_info('Testing full API workflow'),
    % Clean up any existing timetable
    retractall(current_timetable(_)),
    
    % Generate timetable
    log_info('  Step 1: Generating timetable'),
    (generate_timetable(Timetable) ->
        log_info('  ✓ Timetable generated successfully'),
        assertz(current_timetable(Timetable)),
        
        % Retrieve timetable
        log_info('  Step 2: Retrieving timetable'),
        (current_timetable(Retrieved), Retrieved = Timetable ->
            log_info('  ✓ Timetable retrieved successfully'),
            
            % Calculate reliability
            log_info('  Step 3: Calculating reliability'),
            (schedule_reliability(Timetable, Reliability),
             Reliability >= 0.0, Reliability =< 1.0 ->
                format(atom(Msg), '  ✓ Reliability calculated: ~2f', [Reliability]),
                log_info(Msg),
                
                % Format as JSON
                log_info('  Step 4: Formatting as JSON'),
                (format_timetable(Timetable, json, _JSONOutput) ->
                    log_info('  ✓ JSON formatting successful'),
                    log_info('✓ Full workflow test passed')
                ;
                    log_error('  ✗ JSON formatting failed'),
                    log_error('✗ Full workflow test failed')
                )
            ;
                log_error('  ✗ Reliability calculation failed'),
                log_error('✗ Full workflow test failed')
            )
        ;
            log_error('  ✗ Timetable retrieval failed'),
            log_error('✗ Full workflow test failed')
        )
    ;
        log_error('  ✗ Timetable generation failed'),
        log_error('✗ Full workflow test failed')
    ).

%% Test analytics with real data
test_analytics_with_real_data :-
    log_info('Testing analytics with real data'),
    (current_timetable(Timetable) ->
        (calculate_analytics(Timetable, Analytics) ->
            % Verify analytics structure
            (is_dict(Analytics),
             get_dict(teacher_workload, Analytics, Workload),
             get_dict(room_utilization, Analytics, Utilization),
             get_dict(schedule_density, Analytics, Density),
             is_list(Workload),
             is_list(Utilization),
             number(Density) ->
                format(atom(Msg), '  ✓ Analytics calculated: ~w teachers, ~w rooms, density ~2f',
                       [length(Workload), length(Utilization), Density]),
                log_info(Msg),
                log_info('✓ Analytics test passed')
            ;
                log_error('  ✗ Analytics structure invalid'),
                log_error('✗ Analytics test failed')
            )
        ;
            log_error('  ✗ Analytics calculation failed'),
            log_error('✗ Analytics test failed')
        )
    ;
        log_warning('  ⚠ No timetable available for analytics test'),
        log_info('✓ Analytics test skipped (no timetable)')
    ).

%% Test conflict detection
test_conflict_detection :-
    log_info('Testing conflict detection'),
    (current_timetable(Timetable) ->
        (detect_conflicts(Timetable, Conflicts) ->
            (is_list(Conflicts) ->
                length(Conflicts, NumConflicts),
                format(atom(Msg), '  ✓ Conflict detection successful: ~w conflicts found', [NumConflicts]),
                log_info(Msg),
                log_info('✓ Conflict detection test passed')
            ;
                log_error('  ✗ Conflicts not a list'),
                log_error('✗ Conflict detection test failed')
            )
        ;
            log_error('  ✗ Conflict detection failed'),
            log_error('✗ Conflict detection test failed')
        )
    ;
        log_warning('  ⚠ No timetable available for conflict detection test'),
        log_info('✓ Conflict detection test skipped (no timetable)')
    ).

%% Test export formats
test_export_formats :-
    log_info('Testing export formats'),
    (current_timetable(Timetable) ->
        % Test JSON export
        log_info('  Testing JSON export'),
        (format_timetable(Timetable, json, JSONOutput),
         JSONOutput \= '' ->
            log_info('  ✓ JSON export successful'),
            
            % Test CSV export
            log_info('  Testing CSV export'),
            (format_timetable(Timetable, csv, CSVOutput),
             CSVOutput \= '' ->
                log_info('  ✓ CSV export successful'),
                
                % Test text export
                log_info('  Testing text export'),
                (format_timetable(Timetable, text, TextOutput),
                 TextOutput \= '' ->
                    log_info('  ✓ Text export successful'),
                    log_info('✓ Export formats test passed')
                ;
                    log_error('  ✗ Text export failed'),
                    log_error('✗ Export formats test failed')
                )
            ;
                log_error('  ✗ CSV export failed'),
                log_error('✗ Export formats test failed')
            )
        ;
            log_error('  ✗ JSON export failed'),
            log_error('✗ Export formats test failed')
        )
    ;
        log_warning('  ⚠ No timetable available for export test'),
        log_info('✓ Export formats test skipped (no timetable)')
    ).

%% ============================================================================
%% Main Entry Point
%% ============================================================================

:- initialization(run_integration_tests, main).
