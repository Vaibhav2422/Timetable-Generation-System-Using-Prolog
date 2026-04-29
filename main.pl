% main.pl - Entry point for AI-Based Timetable Generation System
% This file loads all required modules and starts the HTTP server

:- initialization(main, main).

% Load configuration
:- (exists_file('config.pl') -> consult('config.pl') ; true).

% Set default configuration if not loaded
:- (current_predicate(server_port/1) -> true ; assert(server_port(8080))).
:- (current_predicate(log_level/1) -> true ; assert(log_level(info))).

% Module loading order - load in dependency order
:- catch(use_module(backend/logging), E, (format('Error loading logging.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/knowledge_base), E, (format('Error loading knowledge_base.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/matrix_model), E, (format('Error loading matrix_model.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/constraints), E, (format('Error loading constraints.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/csp_solver), E, (format('Error loading csp_solver.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/probability_module), E, (format('Error loading probability_module.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/timetable_generator), E, (format('Error loading timetable_generator.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/xai_explainer), E, (format('Error loading xai_explainer.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/conflict_resolver), E, (format('Error loading conflict_resolver.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/scenario_simulator), E, (format('Error loading scenario_simulator.pl: ~w~n', [E]), fail)).
%% Import quality_scorer but exclude predicates already imported from other modules
:- catch(use_module(backend/quality_scorer, [
    calculate_quality_score/2,
    hard_constraint_score/2,
    workload_balance_score/2,
    schedule_compactness_score/2,
    quality_breakdown/2,
    count_constraint_violations/3,
    calculate_balance_metric/2
]), E, (format('Error loading quality_scorer.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/recommendation_engine), E, (format('Error loading recommendation_engine.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/heatmap_generator), E, (format('Error loading heatmap_generator.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/search_statistics), E, (format('Error loading search_statistics.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/multi_solution_generator), E, (format('Error loading multi_solution_generator.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/dynamic_constraints), E, (format('Error loading dynamic_constraints.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/realtime_validator), E, (format('Error loading realtime_validator.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/genetic_optimizer), E, (format('Error loading genetic_optimizer.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/interactive_editor), E, (format('Error loading interactive_editor.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/learning_module), E, (format('Error loading learning_module.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/pattern_analyzer), E, (format('Error loading pattern_analyzer.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/multi_scenario_analyzer), E, (format('Error loading multi_scenario_analyzer.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/constraint_graph), E, (format('Error loading constraint_graph.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/complexity_analyzer), E, (format('Error loading complexity_analyzer.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/nl_query), E, (format('Error loading nl_query.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/conflict_predictor), E, (format('Error loading conflict_predictor.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/version_manager), E, (format('Error loading version_manager.pl: ~w~n', [E]), fail)).
:- catch(use_module(backend/api_server), E, (format('Error loading api_server.pl: ~w~n', [E]), fail)).

% Load example dataset if available - DISABLED: users submit their own data via API
% :- (exists_file('data/dataset.pl') -> 
%     catch(consult('data/dataset.pl'), E, (format('Warning: Could not load dataset.pl: ~w~n', [E]), true)) 
%     ; 
%     writeln('Warning: data/dataset.pl not found. System will start without example data.')).

% Main entry point
main :-
    writeln('==========================================='),
    writeln('AI-Based Timetable Generation System'),
    writeln('==========================================='),
    writeln(''),
    
    % Check for required Prolog libraries
    writeln('Checking required libraries...'),
    (   check_libraries
    ->  writeln('All required libraries are available.')
    ;   writeln('ERROR: Some required libraries are missing.'),
        writeln('Please install missing libraries and restart.'),
        halt(1)
    ),
    writeln(''),
    
    % Initialize logging system
    writeln('Initializing logging system...'),
    log_level(LogLevel),
    set_log_level(LogLevel),
    format('  Log level set to: ~w~n', [LogLevel]),
    log_info('Logging system initialized'),
    writeln(''),
    
    % Display configuration
    writeln('Configuration:'),
    server_port(Port),
    format('  - Server Port: ~w~n', [Port]),
    format('  - Log Level: ~w~n', [LogLevel]),
    max_search_nodes(MaxNodes),
    format('  - Max Search Nodes: ~w~n', [MaxNodes]),
    search_timeout(Timeout),
    format('  - Search Timeout: ~w seconds~n', [Timeout]),
    writeln(''),
    
    % Verify backend modules loaded
    writeln('Verifying backend modules...'),
    verify_modules,
    writeln(''),
    
    % Check for example dataset
    writeln('Checking for example dataset...'),
    (   current_predicate(user:teacher/5)
    ->  findall(T, user:teacher(T, _, _, _, _), Teachers),
        length(Teachers, NumTeachers),
        format('  Dataset loaded: ~w teachers found~n', [NumTeachers])
    ;   writeln('  No pre-loaded dataset. Submit resources via POST /api/resources.')
    ),
    writeln(''),
    
    % Start HTTP server
    writeln('Starting HTTP server...'),
    log_info('Starting API server'),
    (   catch(start_server(Port), Error, (
            format('ERROR: Failed to start server: ~w~n', [Error]),
            log_error('Server startup failed'),
            halt(1)
        ))
    ->  format('  ✓ Server started successfully~n'),
        writeln(''),
        writeln('==========================================='),
        format('Server URL: http://localhost:~w~n', [Port]),
        writeln('API Endpoints:'),
        writeln('  POST /api/resources   - Submit resource data'),
        writeln('  POST /api/generate    - Generate timetable'),
        writeln('  GET  /api/timetable   - Retrieve timetable'),
        writeln('  GET  /api/reliability - Get reliability score'),
        writeln('  POST /api/explain     - Get assignment explanation'),
        writeln('  GET  /api/conflicts   - Detect conflicts'),
        writeln('  POST /api/repair      - Repair timetable'),
        writeln('  GET  /api/analytics   - Get analytics'),
        writeln('  GET  /api/export      - Export timetable'),
        writeln('==========================================='),
        writeln(''),
        writeln('System ready. Press Ctrl+C to stop.'),
        log_info('System initialization complete'),
        % Keep server running
        thread_get_message(_)
    ;   writeln('ERROR: Server failed to start'),
        log_error('Server startup failed'),
        halt(1)
    ).

% Verify that all required backend modules are loaded
verify_modules :-
    verify_module(log_info/1, 'logging.pl'),
    verify_module(teacher/5, 'knowledge_base.pl'),
    verify_module(create_empty_timetable/3, 'matrix_model.pl'),
    verify_module(check_all_hard_constraints/6, 'constraints.pl'),
    verify_module(solve_csp/3, 'csp_solver.pl'),
    verify_module(schedule_reliability/2, 'probability_module.pl'),
    verify_module(generate_timetable/1, 'timetable_generator.pl'),
    verify_module(start_server/1, 'api_server.pl'),
    writeln('  ✓ All backend modules loaded successfully').

verify_module(Predicate, ModuleName) :-
    (   current_predicate(Predicate)
    ->  format('  ✓ ~w loaded~n', [ModuleName])
    ;   format('  ✗ ~w NOT loaded (missing ~w)~n', [ModuleName, Predicate]),
        fail
    ).

% Check if required Prolog libraries are available
check_libraries :-
    writeln('  Checking Prolog libraries...'),
    check_library(http/http_server, 'HTTP Server'),
    check_library(http/http_json, 'JSON Support'),
    check_library(http/http_cors, 'CORS Support'),
    check_library(lists, 'List Operations'),
    !.

check_libraries :-
    writeln(''),
    writeln('  Installation Instructions:'),
    writeln('  For SWI-Prolog, the http libraries are usually included.'),
    writeln('  If missing, install with:'),
    writeln('    ?- pack_install(http).'),
    writeln(''),
    writeln('  Or download from: https://www.swi-prolog.org/download/stable'),
    fail.

check_library(Library, Name) :-
    (   catch(use_module(library(Library)), _, fail)
    ->  format('    ✓ ~w (~w)~n', [Name, Library])
    ;   format('    ✗ ~w (~w) - MISSING~n', [Name, Library]),
        fail
    ).
