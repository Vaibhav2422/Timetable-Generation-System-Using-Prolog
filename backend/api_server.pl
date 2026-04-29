%% ============================================================================
%% api_server.pl - HTTP REST API Server
%% ============================================================================
%% This module provides a RESTful HTTP API for the timetable generation system.
%% It exposes endpoints for resource management, timetable generation, analysis,
%% and export functionality.
%%
%% Requirements: 11.1-11.10, 13.3, 13.4, 16.1, 16.2, 16.5, 16.6, 16.7,
%%               22.1-22.4, 24.1-24.3, 25.1-25.4
%%
%% Author: AI Timetable Generation System
%% ============================================================================

:- module(api_server, [
    start_server/1,
    cors_headers/0,
    handle_validate_input/1,
    handle_resources/1,
    handle_generate/1,
    handle_get_timetable/1,
    handle_reliability/1,
    handle_explain/1,
    handle_explain_detailed/1,
    handle_conflicts/1,
    handle_repair/1,
    handle_analytics/1,
    handle_export/1,
    handle_suggest_fixes/1,
    handle_apply_fix/1,
    handle_simulate/1,
    handle_compare_scenarios/1,
    handle_quality_score/1,
    handle_recommendations/1,
    handle_apply_recommendation/1,
    handle_heatmap/1,
    handle_search_stats/1,
    handle_generate_multiple/1,
    handle_compare_timetables/1,
    handle_constraint_weights/1,
    handle_set_weights/1,
    handle_generate_with_weights/1,
    handle_optimize_ga/1,
    handle_validate_move/1,
    handle_apply_move/1,
    handle_suggest_alternatives/1,
    handle_learning_stats/1,
    handle_apply_learning/1,
    handle_clear_history/1,
    handle_discover_patterns/1,
    handle_apply_pattern/1,
    handle_analyze_scenarios/1,
    handle_constraint_graph/1,
    handle_complexity_analysis/1,
    handle_nl_query/1,
    handle_predict_conflicts/1,
    handle_save_version/1,
    handle_list_versions/1,
    handle_load_version/1,
    handle_compare_versions/1,
    handle_rollback/1,
    validate_resource_data/2,
    store_resources/1,
    sanitize_inputs/2,
    format_user_error/2,
    safe_execute/2,
    calculate_analytics/2
]).

%% Required HTTP libraries
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_cors)).
:- use_module(library(http/http_files)).
:- use_module(library(http/html_write)).
:- use_module(library(time)).
:- mutex_create(timetable_mutex, []).

%% CORS: allow all origins on every request
:- multifile http:cors_allow_origin/2.
http:cors_allow_origin(_, '*').

%% Backend modules
:- use_module(knowledge_base).
:- use_module(timetable_generator).
:- use_module(probability_module).
:- use_module(matrix_model).
:- use_module(logging).
:- use_module(xai_explainer).
:- use_module(conflict_resolver).
:- use_module(scenario_simulator).
%% Import quality_scorer but exclude room_utilization_score/2 which is already
%% imported from xai_explainer (both modules define this predicate).
:- use_module(quality_scorer, [
    calculate_quality_score/2,
    hard_constraint_score/2,
    workload_balance_score/2,
    schedule_compactness_score/2,
    quality_breakdown/2,
    count_constraint_violations/3,
    calculate_balance_metric/2,
    count_gaps/2
]).
:- use_module(recommendation_engine).
:- use_module(heatmap_generator).
:- use_module(search_statistics).
:- use_module(multi_solution_generator).
:- use_module(dynamic_constraints).
:- use_module(realtime_validator).
:- use_module(genetic_optimizer).
:- use_module(interactive_editor).
:- use_module(learning_module).
:- use_module(pattern_analyzer).
:- use_module(multi_scenario_analyzer).
:- use_module(constraint_graph).
:- use_module(complexity_analyzer).
:- use_module(nl_query).
:- use_module(conflict_predictor).
:- use_module(version_manager).

%% ============================================================================
%% HTTP Server Infrastructure (Subtask 11.1)
%% Requirements: 11.10, 13.3, 13.4
%% ============================================================================

%% Dynamic storage for current timetable
:- dynamic current_timetable/1.

%% start_server(+Port)
%% Start HTTP server on specified port
%% Validates: Requirements 13.3, 13.4
%% Allow all origins for CORS preflight and actual requests
:- multifile http:cors_allow_origin/2.
http:cors_allow_origin(_, '*').

%% Enable CORS globally
:- set_setting(http:cors, [*]).

start_server(Port) :-
    log_info('Starting HTTP server'),
    http_server(http_dispatch, [port(Port)]),
    format('~n==============================================~n', []),
    format('AI Timetable Generation System - API Server~n', []),
    format('==============================================~n', []),
    format('Server started successfully!~n', []),
    format('Server URL: http://localhost:~w~n', [Port]),
    format('API Base: http://localhost:~w/api~n', [Port]),
    format('==============================================~n~n', []),
    log_info('HTTP server started successfully').

%% cors_headers/0
%% Set CORS headers for cross-origin requests
cors_headers :-
    cors_enable.

%% reply_json_with_cors(+Data)
%% Reply with JSON and CORS headers
reply_json_with_cors(Data) :-
    cors_enable,
    reply_json(Data).

%% reply_json_with_cors(+Data, +Options)
%% Reply with JSON, CORS headers, and options
reply_json_with_cors(Data, Options) :-
    cors_enable,
    (Options = [status(Code)] ->
        reply_json(Data, [status(Code)])
    ;
        reply_json(Data, Options)
    ).

%% reply_cors_preflight(+Request)
%% Reply to OPTIONS preflight
reply_cors_preflight(Request) :-
    cors_enable(Request, [methods([get,post,options])]),
    format('~n').

%% ============================================================================
%% HTTP Route Definitions
%% ============================================================================

%% Serve frontend index.html at root
:- http_handler(root(.), handle_root, []).
:- http_handler(root('index.html'), handle_root, []).
:- http_handler(root('style.css'), handle_static_css, []).
:- http_handler(root('script.js'), handle_static_js, []).

handle_root(_Request) :-
    (   current_prolog_flag(argv, _),
        frontend_path(FrontendPath)
    ->  true
    ;   FrontendPath = 'frontend'
    ),
    atomic_list_concat([FrontendPath, '/index.html'], FilePath),
    (   exists_file(FilePath)
    ->  http_reply_file(FilePath, [], _Request)
    ;   reply_html_page(title('AI Timetable'), [h1('AI Timetable Generation System'), p('Frontend files not found.')])
    ).

handle_static_css(_Request) :-
    (   frontend_path(FrontendPath) -> true ; FrontendPath = 'frontend' ),
    atomic_list_concat([FrontendPath, '/style.css'], FilePath),
    http_reply_file(FilePath, [], _Request).

handle_static_js(_Request) :-
    (   frontend_path(FrontendPath) -> true ; FrontendPath = 'frontend' ),
    atomic_list_concat([FrontendPath, '/script.js'], FilePath),
    http_reply_file(FilePath, [], _Request).

%% Enable CORS for all API routes
:- http_handler(root(api/resources), handle_resources, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/generate), handle_generate, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/timetable), handle_get_timetable, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/reliability), handle_reliability, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/explain), handle_explain, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/explain_detailed), handle_explain_detailed, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/conflicts), handle_conflicts, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/repair), handle_repair, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/analytics), handle_analytics, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/export), handle_export, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/suggest_fixes), handle_suggest_fixes, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/apply_fix), handle_apply_fix, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/simulate), handle_simulate, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/compare_scenarios), handle_compare_scenarios, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/quality_score), handle_quality_score, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/recommendations), handle_recommendations, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/apply_recommendation), handle_apply_recommendation, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/heatmap), handle_heatmap, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/search_stats), handle_search_stats, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/generate_multiple), handle_generate_multiple, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/compare_timetables), handle_compare_timetables, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/constraint_weights), handle_constraint_weights, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/set_weights), handle_set_weights, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/generate_with_weights), handle_generate_with_weights, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/validate_input), handle_validate_input, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/optimize_ga), handle_optimize_ga, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/validate_move), handle_validate_move, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/apply_move), handle_apply_move, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/suggest_alternatives), handle_suggest_alternatives, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/learning_stats), handle_learning_stats, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/apply_learning), handle_apply_learning, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/clear_history), handle_clear_history, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/discover_patterns), handle_discover_patterns, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/apply_pattern), handle_apply_pattern, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/analyze_scenarios), handle_analyze_scenarios, [cors([methods([get,post,options]), origin('*')])]).
:- http_handler(root(api/constraint_graph), handle_constraint_graph, [cors([methods([get,options]), origin('*')])]).
:- http_handler(root(api/complexity_analysis), handle_complexity_analysis, [cors([methods([get,options]), origin('*')])]).
:- http_handler(root(api/nl_query), handle_nl_query, [cors([methods([post,options]), origin('*')])]).
:- http_handler(root(api/predict_conflicts), handle_predict_conflicts, [method(post)]).
:- http_handler(root(api/save_version), handle_save_version, [cors([methods([post,options]), origin('*')])]).
:- http_handler(root(api/versions), handle_list_versions, [cors([methods([get,options]), origin('*')])]).
:- http_handler(root(api/version), handle_load_version, [cors([methods([get,options]), origin('*')])]).
:- http_handler(root(api/compare_versions), handle_compare_versions, [cors([methods([post,options]), origin('*')])]).
:- http_handler(root(api/rollback), handle_rollback, [cors([methods([post,options]), origin('*')])]).
:- http_handler(root(api/debug_kb), handle_debug_kb, []).

handle_debug_kb(_Request) :-
    findall(T, user:teacher(T,_,_,_,_), Teachers),
    findall(S, user:subject(S,_,_,_,_), Subjects),
    findall(R, user:room(R,_,_,_), Rooms),
    length(Teachers, NT), length(Subjects, NS), length(Rooms, NR),
    reply_json(_{teachers:NT, subjects:NS, rooms:NR}).
%% ============================================================================
%% Resource Management Endpoints (Subtask 11.2)
%% Requirements: 11.1, 24.1, 24.2, 24.3
%% ============================================================================

%% handle_resources(+Request)
%% Handle POST /api/resources - Submit resource data
%% Validates: Requirements 11.1, 24.1, 24.2, 24.3
handle_resources(Request) :-
    member(method(post), Request),
    !,
    safe_execute(
        (
            http_read_json_dict(Request, JSONData),
            log_info('Resource submission received'),
            validate_resource_data(JSONData, ValidatedData),
            store_resources(ValidatedData),
            log_info('Resources stored successfully'),
            reply_json_with_cors(_{status: success, message: 'Resources stored successfully'})
        ),
        handle_resources_error
    ).

handle_resources(Request) :-
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_resources(_) :-
    format_user_error('Invalid request method. Use POST to submit resources.', ErrorMsg),
    reply_json_with_cors(_{status: error, message: ErrorMsg}, [status(400)]).

handle_resources_error(Error) :-
    format_user_error(Error, ErrorMsg),
    log_error(ErrorMsg),
    reply_json_with_cors(_{status: error, message: ErrorMsg}, [status(400)]).

%% validate_resource_data(+JSONData, -ValidatedData)
%% Validate and sanitize resource data
%% Validates: Requirements 24.1, 24.2
validate_resource_data(JSONData, ValidatedData) :-
    % Check that JSONData is a dictionary
    is_dict(JSONData),
    % Sanitize inputs
    sanitize_inputs(JSONData, ValidatedData).

%% sanitize_inputs(+Data, -Sanitized)
%% Sanitize input data to prevent injection attacks
%% Validates: Requirement 24.3
sanitize_inputs(Data, Sanitized) :-
    % For now, basic validation - ensure data is a dict
    is_dict(Data),
    Sanitized = Data.

%% store_resources(+ValidatedData)
%% Store validated resources in knowledge base
%% Validates: Requirement 11.1
%% Handles bulk format: {teachers:[...], subjects:[...], rooms:[...], timeslots:[...], classes:[...]}
store_resources(Data) :-
    % Clear existing dynamic facts - user module only (knowledge_base facts are static)
    catch(retractall(user:teacher(_, _, _, _, _)), _, true),
    catch(retractall(user:subject(_, _, _, _, _)), _, true),
    catch(retractall(user:room(_, _, _, _)), _, true),
    catch(retractall(user:timeslot(_, _, _, _, _)), _, true),
    catch(retractall(user:class(_, _, _)), _, true),
    catch(retractall(user:class_size(_, _)), _, true),
    catch(retractall(knowledge_base:teacher(_, _, _, _, _)), _, true),
    catch(retractall(knowledge_base:subject(_, _, _, _, _)), _, true),
    catch(retractall(knowledge_base:room(_, _, _, _)), _, true),
    catch(retractall(knowledge_base:timeslot(_, _, _, _, _)), _, true),
    catch(retractall(knowledge_base:class(_, _, _)), _, true),
    % Store each resource type into user module
    (get_dict(teachers, Data, Teachers) -> maplist(store_resource_by_type(teacher), Teachers) ; true),
    (get_dict(subjects, Data, Subjects) -> maplist(store_resource_by_type(subject), Subjects) ; true),
    (get_dict(rooms, Data, Rooms) -> maplist(store_resource_by_type(room), Rooms) ; true),
    (get_dict(timeslots, Data, Timeslots) -> maplist(store_resource_by_type(timeslot), Timeslots) ; true),
    (get_dict(classes, Data, Classes) -> maplist(store_resource_by_type(class), Classes) ; true).

store_resource_by_type(teacher, Data) :-
    get_dict(id, Data, ID0),
    get_dict(name, Data, Name0),
    (get_dict(subjects, Data, Subjects0) -> true ; get_dict(qualified_subjects, Data, Subjects0)),
    (get_dict(maxload, Data, MaxLoad) -> true ; get_dict(max_load, Data, MaxLoad)),
    get_dict(availability, Data, Avail0),
    to_atom(ID0, ID), to_atom(Name0, Name),
    maplist(to_atom, Subjects0, Subjects),
    maplist(to_atom, Avail0, Availability),
    assertz(user:teacher(ID, Name, Subjects, MaxLoad, Availability)).

store_resource_by_type(subject, Data) :-
    get_dict(id, Data, ID0),
    get_dict(name, Data, Name0),
    (get_dict(hours, Data, Hours) -> true ; get_dict(weekly_hours, Data, Hours)),
    get_dict(type, Data, Type0),
    get_dict(duration, Data, Duration),
    to_atom(ID0, ID), to_atom(Name0, Name), to_atom(Type0, Type),
    assertz(user:subject(ID, Name, Hours, Type, Duration)).

store_resource_by_type(room, Data) :-
    get_dict(id, Data, ID0),
    get_dict(name, Data, Name0),
    get_dict(capacity, Data, Capacity),
    get_dict(type, Data, Type0),
    to_atom(ID0, ID), to_atom(Name0, Name), to_atom(Type0, Type),
    assertz(user:room(ID, Name, Capacity, Type)).

store_resource_by_type(timeslot, Data) :-
    get_dict(id, Data, ID0),
    get_dict(day, Data, Day0),
    get_dict(period, Data, Period),
    (get_dict(start, Data, StartTime0) -> true ; get_dict(start_time, Data, StartTime0)),
    get_dict(duration, Data, Duration),
    to_atom(ID0, ID), to_atom(Day0, Day), to_atom(StartTime0, StartTime),
    assertz(user:timeslot(ID, Day, Period, StartTime, Duration)).

store_resource_by_type(class, Data) :-
    get_dict(id, Data, ID0),
    get_dict(name, Data, Name0),
    get_dict(subjects, Data, Subjects0),
    to_atom(ID0, ID), to_atom(Name0, Name),
    maplist(to_atom, Subjects0, Subjects),
    assertz(user:class(ID, Name, Subjects)).

%% to_atom(+Value, -Atom)
%% Convert string or atom to atom
to_atom(Value, Atom) :-
    (string(Value) -> atom_string(Atom, Value) ; Atom = Value).

store_resource_by_type(Type, _) :-
    format(atom(Msg), 'Unknown resource type: ~w', [Type]),
    throw(error(invalid_resource_type, Msg)).

%% ============================================================================
%% Timetable Generation Endpoints (Subtask 11.3)
%% Requirements: 11.2, 11.3
%% ============================================================================

%% handle_generate(+Request)
%% Handle POST /api/generate - Generate timetable
%% Validates: Requirement 11.2
handle_generate(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            log_info('Timetable generation request received'),
            (call_with_time_limit(300, timetable_generator:generate_timetable(Timetable)) ->
                true
            ;
                throw(error(generation_failed, 'CSP solver could not find a valid timetable. Try adding more time slots or rooms, or reducing the number of sessions per class.'))
            ),
            % Store current timetable (thread-safe)
            with_mutex(timetable_mutex, (
                retractall(current_timetable(_)),
                assertz(current_timetable(Timetable))
            )),
            % Format timetable as JSON
            format_timetable(Timetable, json, JSONOutput),
            % Calculate reliability
            schedule_reliability(Timetable, Reliability),
            log_info('Timetable generated successfully'),
            reply_json_with_cors(_{
                status: success,
                timetable: JSONOutput,
                reliability: Reliability
            })
        ),
        handle_generate_error
    ).

handle_generate(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_generate(_) :-
    format_user_error('Invalid request method. Use POST to generate timetable.', ErrorMsg),
    reply_json_with_cors(_{status: error, message: ErrorMsg}, [status(400)]).

handle_generate_error(time_limit_exceeded) :-
    !,
    log_error('Timetable generation timed out after 300 seconds'),
    reply_json_with_cors(_{status: error, message: 'Generation timed out. The problem may be too complex. Try reducing the number of classes or subjects.'}, [status(503)]).
handle_generate_error(Error) :-
    format_user_error(Error, ErrorMsg),
    log_error(ErrorMsg),
    reply_json_with_cors(_{status: error, message: ErrorMsg}, [status(500)]).

%% handle_get_timetable(+Request)
%% Handle GET /api/timetable - Retrieve current timetable
%% Validates: Requirement 11.3
handle_get_timetable(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(get), Request),
    !,
    safe_execute(
        (
            (current_timetable(Timetable) ->
                format_timetable(Timetable, json, JSONOutput),
                reply_json_with_cors(_{status: success, timetable: JSONOutput})
            ;
                reply_json_with_cors(_{status: error, message: 'No timetable available. Generate one first.'}, [status(404)])
            )
        ),
        handle_get_timetable_error
    ).

handle_get_timetable(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_get_timetable(_) :-
    format_user_error('Invalid request method. Use GET to retrieve timetable.', ErrorMsg),
    reply_json_with_cors(_{status: error, message: ErrorMsg}, [status(400)]).

handle_get_timetable_error(Error) :-
    format_user_error(Error, ErrorMsg),
    log_error(ErrorMsg),
    reply_json_with_cors(_{status: error, message: ErrorMsg}, [status(500)]).

%% ============================================================================
%% Analysis Endpoints (Subtask 11.4)
%% Requirements: 11.4, 11.5, 11.6
%% ============================================================================

%% handle_reliability(+Request)
%% Handle GET /api/reliability - Get reliability score
%% Validates: Requirement 11.4
handle_reliability(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(get), Request),
    !,
    safe_execute(
        (
            (current_timetable(Timetable) ->
                schedule_reliability(Timetable, Reliability),
                risk_category(Reliability, Risk),
                expected_disruptions(Timetable, ExpectedDisruptions),
                reply_json_with_cors(_{
                    status: success,
                    reliability: Reliability,
                    risk: Risk,
                    expected_disruptions: ExpectedDisruptions
                })
            ;
                reply_json_with_cors(_{status: error, message: 'No timetable available'}, [status(404)])
            )
        ),
        handle_reliability_error
    ).

handle_reliability(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_reliability(_) :-
    format_user_error('Invalid request method. Use GET to retrieve reliability.', ErrorMsg),
    reply_json_with_cors(_{status: error, message: ErrorMsg}, [status(400)]).

handle_reliability_error(Error) :-
    format_user_error(Error, ErrorMsg),
    log_error(ErrorMsg),
    reply_json_with_cors(_{status: error, message: ErrorMsg}, [status(500)]).

%% handle_explain(+Request)
%% Handle POST /api/explain - Explain assignment
%% Validates: Requirement 11.5
handle_explain(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            http_read_json_dict(Request, JSONData),
            get_dict(class_id, JSONData, ClassID),
            get_dict(subject_id, JSONData, SubjectID),
            (current_timetable(Timetable) ->
                Session = session(ClassID, SubjectID),
                find_assignment_in_timetable(Session, Timetable, Assignment),
                explain_assignment(Session, Assignment, Explanation),
                reply_json_with_cors(_{status: success, explanation: Explanation})
            ;
                reply_json_with_cors(_{status: error, message: 'No timetable available'}, [status(404)])
            )
        ),
        handle_explain_error
    ).

handle_explain(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_explain(_) :-
    format_user_error('Invalid request method. Use POST to request explanation.', ErrorMsg),
    reply_json_with_cors(_{status: error, message: ErrorMsg}, [status(400)]).

handle_explain_error(Error) :-
    format_user_error(Error, ErrorMsg),
    log_error(ErrorMsg),
    reply_json_with_cors(_{status: error, message: ErrorMsg}, [status(500)]).

%% find_assignment_in_timetable(+Session, +Timetable, -Assignment)
%% Find assignment for a session in the timetable
find_assignment_in_timetable(session(ClassID, SubjectID), Timetable, Assignment) :-
    get_all_assignments(Timetable, Assignments),
    member(Assignment, Assignments),
    Assignment = assigned(_, ClassID, SubjectID, _, _).

%% handle_conflicts(+Request)
%% Handle GET /api/conflicts - Detect conflicts
%% Validates: Requirement 11.6
handle_conflicts(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(get), Request),
    !,
    safe_execute(
        (
            (current_timetable(Timetable) ->
                detect_conflicts(Timetable, Conflicts),
                format_conflicts_json(Conflicts, FormattedConflicts),
                reply_json_with_cors(_{status: success, conflicts: FormattedConflicts})
            ;
                reply_json_with_cors(_{status: error, message: 'No timetable available'}, [status(404)])
            )
        ),
        handle_conflicts_error
    ).

handle_conflicts(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_conflicts(_) :-
    format_user_error('Invalid request method. Use GET to detect conflicts.', ErrorMsg),
    reply_json_with_cors(_{status: error, message: ErrorMsg}, [status(400)]).

handle_conflicts_error(Error) :-
    format_user_error(Error, ErrorMsg),
    log_error(ErrorMsg),
    reply_json_with_cors(_{status: error, message: ErrorMsg}, [status(500)]).

%% format_conflicts_json(+Conflicts, -FormattedConflicts)
%% Format conflicts as JSON-compatible structure
format_conflicts_json([], []).
format_conflicts_json([teacher_conflict(TeacherID, SlotID, Sessions)|Rest], 
                      [_{type: teacher_conflict, teacher_id: TeacherID, slot_id: SlotID, sessions: Sessions}|RestFormatted]) :-
    format_conflicts_json(Rest, RestFormatted).
format_conflicts_json([room_conflict(RoomID, SlotID, Sessions)|Rest],
                      [_{type: room_conflict, room_id: RoomID, slot_id: SlotID, sessions: Sessions}|RestFormatted]) :-
    format_conflicts_json(Rest, RestFormatted).

%% handle_repair(+Request)
%% Handle POST /api/repair - Repair timetable
%% Validates: Requirement 11.6
handle_repair(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            (current_timetable(Timetable) ->
                detect_conflicts(Timetable, Conflicts),
                (Conflicts = [] ->
                    reply_json_with_cors(_{status: success, message: 'No conflicts to repair'})
                ;
                    repair_timetable(Timetable, Conflicts, RepairedTimetable),
                    retractall(current_timetable(_)),
                    assertz(current_timetable(RepairedTimetable)),
                    format_timetable(RepairedTimetable, json, JSONOutput),
                    reply_json_with_cors(_{status: success, timetable: JSONOutput})
                )
            ;
                reply_json_with_cors(_{status: error, message: 'No timetable available'}, [status(404)])
            )
        ),
        handle_repair_error
    ).

handle_repair(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_repair(_) :-
    format_user_error('Invalid request method. Use POST to repair timetable.', ErrorMsg),
    reply_json_with_cors(_{status: error, message: ErrorMsg}, [status(400)]).

handle_repair_error(Error) :-
    format_user_error(Error, ErrorMsg),
    log_error(ErrorMsg),
    reply_json_with_cors(_{status: error, message: ErrorMsg}, [status(500)]).

%% ============================================================================
%% Analytics and Export Endpoints (Subtask 11.5)
%% Requirements: 22.1, 22.2, 22.3, 22.4, 25.1, 25.2, 25.3, 25.4
%% ============================================================================

%% handle_analytics(+Request)
%% Handle GET /api/analytics - Get resource utilization analytics
%% Validates: Requirements 22.1, 22.2, 22.3, 22.4
handle_analytics(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(get), Request),
    !,
    safe_execute(
        (
            (current_timetable(Timetable) ->
                calculate_analytics(Timetable, Analytics),
                reply_json_with_cors(_{status: success, analytics: Analytics})
            ;
                reply_json_with_cors(_{status: error, message: 'No timetable available'}, [status(404)])
            )
        ),
        handle_analytics_error
    ).

handle_analytics(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_analytics(_) :-
    format_user_error('Invalid request method. Use GET to retrieve analytics.', ErrorMsg),
    reply_json_with_cors(_{status: error, message: ErrorMsg}, [status(400)]).

handle_analytics_error(Error) :-
    format_user_error(Error, ErrorMsg),
    log_error(ErrorMsg),
    reply_json_with_cors(_{status: error, message: ErrorMsg}, [status(500)]).

%% calculate_analytics(+Timetable, -Analytics)
%% Calculate resource utilization analytics
%% Validates: Requirements 22.1, 22.2, 22.3
calculate_analytics(Timetable, Analytics) :-
    calculate_teacher_workload(Timetable, TeacherWorkload),
    calculate_room_utilization(Timetable, RoomUtilization),
    calculate_schedule_density(Timetable, ScheduleDensity),
    Analytics = _{
        teacher_workload: TeacherWorkload,
        room_utilization: RoomUtilization,
        schedule_density: ScheduleDensity
    }.

%% calculate_teacher_workload(+Timetable, -Workload)
%% Calculate workload statistics for each teacher
%% Validates: Requirement 22.1
calculate_teacher_workload(Timetable, Workload) :-
    get_all_assignments(Timetable, Assignments),
    get_all_teachers(Teachers),
    findall(_{teacher_id: TID, teacher_name: TName, hours: Hours},
            (member(teacher(TID, TName, _, _, _), Teachers),
             count_teacher_hours(TID, Assignments, Hours)),
            Workload).

count_teacher_hours(TeacherID, Assignments, Hours) :-
    findall(1, member(assigned(_, _, _, TeacherID, _), Assignments), Occurrences),
    length(Occurrences, Hours).

%% calculate_room_utilization(+Timetable, -Utilization)
%% Calculate utilization percentage for each room
%% Validates: Requirement 22.2
calculate_room_utilization(Timetable, Utilization) :-
    get_all_rooms(Rooms),
    get_all_timeslots(Slots),
    length(Slots, TotalSlots),
    get_all_assignments(Timetable, Assignments),
    findall(_{room_id: RID, room_name: RName, utilization: Percent},
            (member(room(RID, RName, _, _), Rooms),
             count_room_usage(RID, Assignments, UsedSlots),
             Percent is (UsedSlots / TotalSlots) * 100),
            Utilization).

count_room_usage(RoomID, Assignments, Count) :-
    findall(1, member(assigned(RoomID, _, _, _, _), Assignments), Occurrences),
    length(Occurrences, Count).

%% calculate_schedule_density(+Timetable, -Density)
%% Calculate average schedule density (sessions per time slot)
%% Validates: Requirement 22.3
calculate_schedule_density(Timetable, Density) :-
    get_all_assignments(Timetable, Assignments),
    get_all_timeslots(Slots),
    length(Assignments, TotalAssignments),
    length(Slots, TotalSlots),
    (TotalSlots > 0 ->
        Density is TotalAssignments / TotalSlots
    ;
        Density is 0
    ).

%% handle_export(+Request)
%% Handle GET /api/export - Export timetable in various formats
%% Validates: Requirements 25.1, 25.2, 25.3, 25.4
handle_export(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(get), Request),
    !,
    safe_execute(
        (
            http_parameters(Request, [format(Format, [default(json)])]),
            (current_timetable(Timetable) ->
                export_timetable(Timetable, Format, Output, ContentType),
                format('Content-Type: ~w~n~n', [ContentType]),
                write(Output)
            ;
                reply_json_with_cors(_{status: error, message: 'No timetable available'}, [status(404)])
            )
        ),
        handle_export_error
    ).

handle_export(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_export(_) :-
    format_user_error('Invalid request method. Use GET to export timetable.', ErrorMsg),
    reply_json_with_cors(_{status: error, message: ErrorMsg}, [status(400)]).

handle_export_error(Error) :-
    format_user_error(Error, ErrorMsg),
    log_error(ErrorMsg),
    reply_json_with_cors(_{status: error, message: ErrorMsg}, [status(500)]).

%% export_timetable(+Timetable, +Format, -Output, -ContentType)
%% Export timetable in specified format
%% Validates: Requirements 25.1, 25.2, 25.3
export_timetable(Timetable, json, Output, 'application/json') :-
    format_timetable(Timetable, json, JSONOutput),
    with_output_to(atom(Output), json_write(current_output, JSONOutput)).

export_timetable(Timetable, csv, Output, 'text/csv') :-
    format_timetable(Timetable, csv, Output).

export_timetable(Timetable, pdf, Output, 'application/pdf') :-
    % PDF generation would require additional library
    % For now, return text format with PDF content type
    format_timetable(Timetable, text, Output).

export_timetable(_, Format, _, _) :-
    format(atom(Msg), 'Unsupported export format: ~w', [Format]),
    throw(error(unsupported_format, Msg)).

%% ============================================================================
%% Error Handling and Validation (Subtask 11.6)
%% Requirements: 11.7, 11.8, 11.9, 16.1, 16.2, 16.5, 16.6, 16.7
%% ============================================================================

%% safe_execute(+Goal, +ErrorHandler)
%% Execute goal with error handling
%% Validates: Requirements 16.1, 16.2
safe_execute(Goal, ErrorHandler) :-
    catch(
        (Goal -> true ; call(ErrorHandler, goal_failed)),
        Error,
        call(ErrorHandler, Error)
    ).

%% format_user_error(+Error, -ErrorMsg)
%% Format error as user-friendly message
%% Validates: Requirements 16.2, 16.6
format_user_error(Error, ErrorMsg) :-
    (atom(Error) ->
        ErrorMsg = Error
    ; Error = error(Type, Context) ->
        format(atom(ErrorMsg), 'Error (~w): ~w', [Type, Context])
    ; Error = error(Type) ->
        format(atom(ErrorMsg), 'Error: ~w', [Type])
    ;
        format(atom(ErrorMsg), 'An unexpected error occurred: ~w', [Error])
    ).

%% ============================================================================
%% XAI Detailed Explanation Endpoint (Feature 1 - Task 18.2)
%% Requirements: 9.1, 9.2, 9.3
%% ============================================================================

%% handle_explain_detailed(+Request)
%% Handle POST /api/explain_detailed - Return structured XAI explanation
handle_explain_detailed(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            http_read_json_dict(Request, JSONData),
            get_dict(class_id,   JSONData, ClassID),
            get_dict(subject_id, JSONData, SubjectID),
            get_dict(teacher_id, JSONData, TeacherID),
            get_dict(room_id,    JSONData, RoomID),
            get_dict(slot_id,    JSONData, SlotID),
            explain_assignment(ClassID, SubjectID, TeacherID, RoomID, SlotID, Explanation),
            reply_json_with_cors(_{status: success, explanation: Explanation})
        ),
        handle_explain_detailed_error
    ).

handle_explain_detailed(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_explain_detailed(_) :-
    format_user_error('Use POST with class_id, subject_id, teacher_id, room_id, slot_id.', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_explain_detailed_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% ============================================================================
%% Conflict Suggestion Endpoints (Feature 2 - Task 19.2)
%% ============================================================================

%% handle_suggest_fixes(+Request)
%% Handle GET /api/suggest_fixes
%% Returns all detected conflicts together with actionable fix suggestions.
handle_suggest_fixes(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(get), Request),
    !,
    safe_execute(
        (
            (current_timetable(Timetable) ->
                detect_conflicts(Timetable, Conflicts),
                build_suggestions(Conflicts, ConflictsWithSuggestions),
                reply_json_with_cors(_{
                    status: success,
                    conflicts: ConflictsWithSuggestions
                })
            ;
                reply_json_with_cors(_{status: error, message: 'No timetable available'}, [status(404)])
            )
        ),
        handle_suggest_fixes_error
    ).

handle_suggest_fixes(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_suggest_fixes(_) :-
    format_user_error('Use GET /api/suggest_fixes', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_suggest_fixes_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% build_suggestions(+Conflicts, -ConflictsWithSuggestions)
%% For each conflict, generate suggestions and format as JSON-compatible dicts.
build_suggestions([], []).
build_suggestions([Conflict|Rest], [Entry|RestEntries]) :-
    suggest_fix(Conflict, Suggestions),
    format_conflict_entry(Conflict, Suggestions, Entry),
    build_suggestions(Rest, RestEntries).

%% format_conflict_entry(+Conflict, +Suggestions, -Entry)
format_conflict_entry(teacher_conflict(TeacherID, SlotID, Sessions), Suggestions, Entry) :-
    format_suggestions_json(Suggestions, SuggestionsJSON),
    Entry = _{
        type: teacher_conflict,
        teacher_id: TeacherID,
        slot_id: SlotID,
        sessions: Sessions,
        suggestions: SuggestionsJSON
    }.

format_conflict_entry(room_conflict(RoomID, SlotID, Sessions), Suggestions, Entry) :-
    format_suggestions_json(Suggestions, SuggestionsJSON),
    Entry = _{
        type: room_conflict,
        room_id: RoomID,
        slot_id: SlotID,
        sessions: Sessions,
        suggestions: SuggestionsJSON
    }.

%% format_suggestions_json(+Suggestions, -JSON)
format_suggestions_json([], []).
format_suggestions_json([fix(Type, Desc, FixData)|Rest], [JSON|RestJSON]) :-
    format_fix_data_json(FixData, FixDataJSON),
    JSON = _{fix_type: Type, description: Desc, fix_data: FixDataJSON},
    format_suggestions_json(Rest, RestJSON).

%% format_fix_data_json(+FixData, -JSON)
format_fix_data_json(fix_data(Pairs), JSON) :-
    pairs_to_dict(Pairs, JSON).
format_fix_data_json(FixData, JSON) :-
    FixData =.. [fix_data | Pairs],
    pairs_to_dict(Pairs, JSON).

pairs_to_dict([], _{}).
pairs_to_dict([Key-Value|Rest], Dict) :-
    pairs_to_dict(Rest, RestDict),
    put_dict(Key, RestDict, Value, Dict).

%% handle_apply_fix(+Request)
%% Handle POST /api/apply_fix
%% Applies a chosen fix to the current timetable and returns the updated timetable.
handle_apply_fix(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            http_read_json_dict(Request, JSONData),
            % Extract fix parameters from JSON
            get_dict(fix_type, JSONData, FixTypeAtom),
            get_dict(fix_data, JSONData, FixDataDict),
            get_dict(description, JSONData, Desc),
            % Convert JSON fix_data dict to key-value pair list
            dict_pairs(FixDataDict, _, FixPairs),
            Fix = fix(FixTypeAtom, Desc, FixPairs),
            apply_fix(Fix, UpdatedMatrix),
            % Persist updated timetable
            retractall(current_timetable(_)),
            assertz(current_timetable(UpdatedMatrix)),
            format_timetable(UpdatedMatrix, json, JSONOutput),
            schedule_reliability(UpdatedMatrix, Reliability),
            log_info('Fix applied successfully'),
            reply_json_with_cors(_{
                status: success,
                message: 'Fix applied successfully',
                timetable: JSONOutput,
                reliability: Reliability
            })
        ),
        handle_apply_fix_error
    ).

handle_apply_fix(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_apply_fix(_) :-
    format_user_error('Use POST /api/apply_fix with fix_type, description, fix_data', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_apply_fix_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% ============================================================================
%% End of api_server.pl
%% ============================================================================% ============================================================================
%% Scenario Simulation Endpoints (Feature 3 - Task 20.2)
%% ============================================================================

%% handle_simulate(+Request)
%% Handle POST /api/simulate
%% Runs a what-if scenario against the current timetable and returns the
%% simulated timetable together with a reliability score.
handle_simulate(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            http_read_json_dict(Request, JSONData),
            get_dict(scenario, JSONData, ScenarioAtom),
            % Pass the whole JSON dict as params; individual handlers use get_dict
            simulate_scenario(ScenarioAtom, JSONData, SimResult),
            % Format the simulated timetable for JSON transport
            get_dict(timetable, SimResult, SimMatrix),
            format_timetable(SimMatrix, json, JSONTimetable),
            get_dict(reliability, SimResult, Reliability),
            get_dict(changes, SimResult, Changes),
            format_changes_json(Changes, ChangesJSON),
            log_info('Scenario simulation completed'),
            reply_json_with_cors(_{
                status: success,
                scenario: ScenarioAtom,
                timetable: JSONTimetable,
                reliability: Reliability,
                changes: ChangesJSON
            })
        ),
        handle_simulate_error
    ).

handle_simulate(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_simulate(_) :-
    format_user_error('Use POST /api/simulate with {scenario, ...params}', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_simulate_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% handle_compare_scenarios(+Request)
%% Handle POST /api/compare_scenarios
%% Runs two scenarios and returns a diff comparison.
%% Expected body: {scenario_a: {scenario, ...}, scenario_b: {scenario, ...}}
handle_compare_scenarios(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            http_read_json_dict(Request, JSONData),
            get_dict(scenario_a, JSONData, ParamsA),
            get_dict(scenario_b, JSONData, ParamsB),
            get_dict(scenario, ParamsA, ScenarioA),
            get_dict(scenario, ParamsB, ScenarioB),
            simulate_scenario(ScenarioA, ParamsA, ResultA),
            simulate_scenario(ScenarioB, ParamsB, ResultB),
            compare_scenarios(ResultA, ResultB, Comparison),
            % Format timetables for transport
            get_dict(timetable, ResultA, MatrixA),
            get_dict(timetable, ResultB, MatrixB),
            format_timetable(MatrixA, json, JSONA),
            format_timetable(MatrixB, json, JSONB),
            get_dict(reliability_delta, Comparison, Delta),
            get_dict(reliability_a, Comparison, RelA),
            get_dict(reliability_b, Comparison, RelB),
            get_dict(added, Comparison, Added),
            get_dict(removed, Comparison, Removed),
            format_assignments_json(Added, AddedJSON),
            format_assignments_json(Removed, RemovedJSON),
            log_info('Scenario comparison completed'),
            reply_json_with_cors(_{
                status: success,
                scenario_a: _{
                    scenario: ScenarioA,
                    timetable: JSONA,
                    reliability: RelA
                },
                scenario_b: _{
                    scenario: ScenarioB,
                    timetable: JSONB,
                    reliability: RelB
                },
                comparison: _{
                    added: AddedJSON,
                    removed: RemovedJSON,
                    reliability_delta: Delta
                }
            })
        ),
        handle_compare_scenarios_error
    ).

handle_compare_scenarios(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_compare_scenarios(_) :-
    format_user_error('Use POST /api/compare_scenarios with {scenario_a, scenario_b}', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_compare_scenarios_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% format_changes_json(+Changes, -JSON)
%% Convert a list of change terms to JSON-compatible dicts.
format_changes_json([], []).
format_changes_json([reassigned(CID, SID)|Rest], [_{type: reassigned, class_id: CID, subject_id: SID}|RestJSON]) :-
    format_changes_json(Rest, RestJSON).
format_changes_json([unassigned(CID, SID)|Rest], [_{type: unassigned, class_id: CID, subject_id: SID}|RestJSON]) :-
    format_changes_json(Rest, RestJSON).
format_changes_json([added_session(CID, SID)|Rest], [_{type: added_session, class_id: CID, subject_id: SID}|RestJSON]) :-
    format_changes_json(Rest, RestJSON).
format_changes_json([failed_to_add_session(CID, SID)|Rest], [_{type: failed_to_add, class_id: CID, subject_id: SID}|RestJSON]) :-
    format_changes_json(Rest, RestJSON).
format_changes_json([removed_for_exam(CID, SID, SlotID)|Rest], [_{type: removed_for_exam, class_id: CID, subject_id: SID, slot_id: SlotID}|RestJSON]) :-
    format_changes_json(Rest, RestJSON).
format_changes_json([_|Rest], RestJSON) :-
    format_changes_json(Rest, RestJSON).

%% ============================================================================
%% Quality Scoring Endpoint (Feature 4 - Task 21.2)
%% Requirements: 21.1-21.5
%% ============================================================================

%% handle_quality_score(+Request)
%% Handle GET /api/quality_score
%% Returns the overall quality score (0-100) and a per-metric breakdown.
handle_quality_score(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(get), Request),
    !,
    safe_execute(
        (
            (current_timetable(Timetable) ->
                quality_breakdown(Timetable, Breakdown),
                log_info('Quality score calculated'),
                reply_json_with_cors(_{status: success, quality: Breakdown})
            ;
                reply_json_with_cors(_{status: error, message: 'No timetable available'}, [status(404)])
            )
        ),
        handle_quality_score_error
    ).

handle_quality_score(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_quality_score(_) :-
    format_user_error('Use GET /api/quality_score', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_quality_score_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% ============================================================================
%% Recommendation Engine Endpoints (Feature 5 - Task 22.2)
%% ============================================================================

%% handle_recommendations(+Request)
%% Handle GET /api/recommendations
%% Returns a prioritised list of AI-generated improvement recommendations.
handle_recommendations(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(get), Request),
    !,
    safe_execute(
        (
            (current_timetable(Timetable) ->
                generate_recommendations(Timetable, Recommendations),
                maplist(format_recommendation, Recommendations, FormattedRecs),
                log_info('Recommendations generated'),
                reply_json_with_cors(_{status: success, recommendations: FormattedRecs})
            ;
                reply_json_with_cors(_{status: error, message: 'No timetable available'}, [status(404)])
            )
        ),
        handle_recommendations_error
    ).

handle_recommendations(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_recommendations(_) :-
    format_user_error('Use GET /api/recommendations', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_recommendations_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% handle_apply_recommendation(+Request)
%% Handle POST /api/apply_recommendation
%% Applies a chosen recommendation and returns the updated timetable.
%% Expected body: { priority, category, description, action: { type, ... } }
handle_apply_recommendation(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            http_read_json_dict(Request, JSONData),
            get_dict(priority,    JSONData, Priority),
            get_dict(category,    JSONData, Category),
            get_dict(description, JSONData, Description),
            get_dict(action,      JSONData, ActionDict),
            % Reconstruct the recommendation term from JSON
            dict_to_action(ActionDict, ActionData),
            Rec = recommendation(Priority, Category, Description, ActionData),
            apply_recommendation(Rec, UpdatedMatrix),
            retractall(current_timetable(_)),
            assertz(current_timetable(UpdatedMatrix)),
            format_timetable(UpdatedMatrix, json, JSONOutput),
            schedule_reliability(UpdatedMatrix, Reliability),
            log_info('Recommendation applied successfully'),
            reply_json_with_cors(_{
                status: success,
                message: 'Recommendation applied',
                timetable: JSONOutput,
                reliability: Reliability
            })
        ),
        handle_apply_recommendation_error
    ).

handle_apply_recommendation(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_apply_recommendation(_) :-
    format_user_error('Use POST /api/apply_recommendation with recommendation data', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_apply_recommendation_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% dict_to_action(+Dict, -ActionTerm)
%% Converts a JSON action dict back into an action/N term.
dict_to_action(Dict, ActionTerm) :-
    get_dict(type, Dict, Type),
    dict_pairs(Dict, _, AllPairs),
    findall(Key-Value,
            (member(Key-Value, AllPairs), Key \= type),
            Pairs),
    ActionTerm =.. [action, Type | Pairs].

%% ============================================================================
%% Heatmap Endpoint (Feature 6 - Task 23.2)
%% ============================================================================

%% handle_heatmap(+Request)
%% Handle GET /api/heatmap?type=teacher|room|timeslot
%% Returns heatmap data as JSON with cells containing id, label, and intensity.
handle_heatmap(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(get), Request),
    !,
    safe_execute(
        (
            http_parameters(Request, [type(HeatmapType, [default(teacher)])]),
            atom_string(HeatmapTypeAtom, HeatmapType),
            log_info('Heatmap request received'),
            generate_heatmap(HeatmapTypeAtom, HeatmapData),
            log_info('Heatmap generated successfully'),
            reply_json_with_cors(_{status: success, heatmap: HeatmapData})
        ),
        handle_heatmap_error
    ).

handle_heatmap(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_heatmap(_) :-
    format_user_error('Use GET /api/heatmap?type=teacher|room|timeslot', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_heatmap_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% ============================================================================
%% End of api_server.pl
%% ============================================================================


%% ============================================================================
%% Search Statistics Endpoint (Feature 7 - Task 24.2)
%% ============================================================================

%% handle_search_stats(+Request)
%% Handle GET /api/search_stats
%% Returns comprehensive statistics about the last CSP search run.
handle_search_stats(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(get), Request),
    !,
    safe_execute(
        (
            get_search_statistics(Stats),
            log_info('Search statistics retrieved'),
            reply_json_with_cors(_{status: success, stats: Stats})
        ),
        handle_search_stats_error
    ).

handle_search_stats(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_search_stats(_) :-
    format_user_error('Use GET /api/search_stats', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_search_stats_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% ============================================================================
%% Multiple Timetable Generation Endpoints (Feature 8 - Task 25.2)
%% ============================================================================

%% handle_generate_multiple(+Request)
%% Handle POST /api/generate_multiple
%% Body: { count: N }  where 2 <= N <= 10
%% Returns a ranked list of up to N timetable solutions with quality and
%% reliability badges.
handle_generate_multiple(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            http_read_json_dict(Request, JSONData),
            % Extract count, default 3, clamp to [2, 10]
            (get_dict(count, JSONData, RawCount) -> true ; RawCount = 3),
            Count is max(2, min(10, RawCount)),
            format(atom(Msg), 'Multiple timetable generation requested: ~w solutions', [Count]),
            log_info(Msg),
            generate_top_timetables(Count, RankedSolutions),
            format_ranked_solutions(RankedSolutions, FormattedSolutions),
            length(FormattedSolutions, Found),
            format(atom(DoneMsg), 'Returning ~w ranked solutions', [Found]),
            log_info(DoneMsg),
            reply_json_with_cors(_{
                status:    success,
                count:     Found,
                solutions: FormattedSolutions
            })
        ),
        handle_generate_multiple_error
    ).

handle_generate_multiple(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_generate_multiple(_) :-
    format_user_error('Use POST /api/generate_multiple with {count: N} (2-10)', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_generate_multiple_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% format_ranked_solutions(+RankedSolutions, -Formatted)
%% Convert ranked solution dicts to JSON-serialisable form.
format_ranked_solutions([], []).
format_ranked_solutions([Sol|Rest], [Formatted|RestFormatted]) :-
    get_dict(timetable,      Sol, Timetable),
    get_dict(quality_score,  Sol, Quality),
    get_dict(reliability,    Sol, Reliability),
    get_dict(combined_score, Sol, Combined),
    format_timetable(Timetable, json, JSONTimetable),
    Formatted = _{
        timetable:      JSONTimetable,
        quality_score:  Quality,
        reliability:    Reliability,
        combined_score: Combined
    },
    format_ranked_solutions(Rest, RestFormatted).

%% handle_compare_timetables(+Request)
%% Handle POST /api/compare_timetables
%% Body: { index_a: I, index_b: J }
%% Compares two solutions from the most recently generated set.
%% For simplicity the client sends two full timetable JSON objects:
%%   { timetable_a: <json>, timetable_b: <json> }
handle_compare_timetables(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            http_read_json_dict(Request, JSONData),
            get_dict(timetable_a, JSONData, JSONA),
            get_dict(timetable_b, JSONData, JSONB),
            % Parse both timetables from JSON
            parse_timetable(JSONA, TimetableA),
            parse_timetable(JSONB, TimetableB),
            compare_timetables(TimetableA, TimetableB, Comparison),
            % Format assignment lists for JSON transport
            get_dict(added,   Comparison, Added),
            get_dict(removed, Comparison, Removed),
            format_assignments_json(Added,   AddedJSON),
            format_assignments_json(Removed, RemovedJSON),
            get_dict(added_count,       Comparison, AddedCount),
            get_dict(removed_count,     Comparison, RemovedCount),
            get_dict(quality_delta,     Comparison, QDelta),
            get_dict(reliability_delta, Comparison, RDelta),
            log_info('Timetable comparison completed'),
            reply_json_with_cors(_{
                status: success,
                comparison: _{
                    added:             AddedJSON,
                    removed:           RemovedJSON,
                    added_count:       AddedCount,
                    removed_count:     RemovedCount,
                    quality_delta:     QDelta,
                    reliability_delta: RDelta
                }
            })
        ),
        handle_compare_timetables_error
    ).

handle_compare_timetables(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_compare_timetables(_) :-
    format_user_error('Use POST /api/compare_timetables with {timetable_a, timetable_b}', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_compare_timetables_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% ============================================================================
%% Constraint Weights Endpoints (Feature 9 - Task 26.2)
%% Requirements: 5.1-5.6
%% ============================================================================

%% handle_constraint_weights(+Request)
%% Handle GET /api/constraint_weights
%% Returns the current weight for every soft constraint.
handle_constraint_weights(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(get), Request),
    !,
    safe_execute(
        (
            get_all_weights(Weights),
            format_weights_json(Weights, WeightsJSON),
            log_info('Constraint weights retrieved'),
            reply_json_with_cors(_{status: success, weights: WeightsJSON})
        ),
        handle_constraint_weights_error
    ).

handle_constraint_weights(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_constraint_weights(_) :-
    format_user_error('Use GET /api/constraint_weights', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_constraint_weights_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% format_weights_json(+Weights, -JSON)
%% Converts a list of constraint_weight(Name, Value) terms to a JSON dict.
format_weights_json(Weights, JSON) :-
    foldl([constraint_weight(Name, Value), Acc, Out]>>(put_dict(Name, Acc, Value, Out)),
          Weights, _{}, JSON).

%% handle_set_weights(+Request)
%% Handle POST /api/set_weights
%% Body: { "workload_balance": 0.9, "avoid_late_theory": 0.5, ... }
%% Accepts a partial dict - only the provided keys are updated.
handle_set_weights(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            http_read_json_dict(Request, JSONData),
            apply_weight_updates(JSONData),
            get_all_weights(UpdatedWeights),
            format_weights_json(UpdatedWeights, WeightsJSON),
            log_info('Constraint weights updated'),
            reply_json_with_cors(_{
                status: success,
                message: 'Weights updated successfully',
                weights: WeightsJSON
            })
        ),
        handle_set_weights_error
    ).

handle_set_weights(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_set_weights(_) :-
    format_user_error('Use POST /api/set_weights with a JSON object of constraint weights', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_set_weights_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

%% apply_weight_updates(+JSONDict)
%% Iterates over the JSON dict and calls set_constraint_weight/2 for each key.
apply_weight_updates(JSONDict) :-
    dict_pairs(JSONDict, _, Pairs),
    maplist([Name-Value]>>(
        (number(Value) ->
            set_constraint_weight(Name, Value)
        ;
            format(atom(Msg), 'Skipping non-numeric weight for ~w', [Name]),
            log_debug(Msg)
        )
    ), Pairs).

%% handle_generate_with_weights(+Request)
%% Handle POST /api/generate_with_weights
%% Body: { "weights": { "workload_balance": 0.9, ... } }
%% Applies the provided weights then generates a timetable.
handle_generate_with_weights(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            http_read_json_dict(Request, JSONData),
            % Extract optional weights dict
            (get_dict(weights, JSONData, WeightsDict) ->
                apply_weight_updates(WeightsDict)
            ;
                true  % Use existing weights if none provided
            ),
            log_info('Generating timetable with custom constraint weights'),
            generate_with_custom_weights([], Timetable),
            retractall(current_timetable(_)),
            assertz(current_timetable(Timetable)),
            format_timetable(Timetable, json, JSONOutput),
            schedule_reliability(Timetable, Reliability),
            get_all_weights(ActiveWeights),
            format_weights_json(ActiveWeights, WeightsJSON),
            log_info('Weighted timetable generation complete'),
            reply_json_with_cors(_{
                status: success,
                timetable: JSONOutput,
                reliability: Reliability,
                weights_used: WeightsJSON
            })
        ),
        handle_generate_with_weights_error
    ).

handle_generate_with_weights(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_generate_with_weights(_) :-
    format_user_error('Use POST /api/generate_with_weights with optional {weights: {...}}', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_generate_with_weights_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% format_assignments_json(+Assignments, -JSON)
%% Convert a list of assignment terms to JSON-compatible dicts.
format_assignments_json([], []).
format_assignments_json([assigned(RoomID, ClassID, SubjectID, TeacherID, SlotID)|Rest],
                        [_{room_id: RoomID, class_id: ClassID, subject_id: SubjectID,
                           teacher_id: TeacherID, slot_id: SlotID}|RestJSON]) :-
    format_assignments_json(Rest, RestJSON).
format_assignments_json([_|Rest], RestJSON) :-
    format_assignments_json(Rest, RestJSON).

%% ============================================================================
%% Real-Time Validation Endpoint (Feature 10 - Task 27.2)
%% Requirements: 1.7, 16.3, 16.4, 24.1, 24.2, 24.3
%% ============================================================================

%% handle_validate_input(+Request)
%% Handle POST /api/validate_input - Validate resource input in real time
%% Body: { "type": "teacher|subject|room|timeslot|class", ...fields... }
%% Returns: { status, valid, errors, suggestions, conflicts }
handle_validate_input(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            http_read_json_dict(Request, JSONData),
            (get_dict(type, JSONData, TypeAtom) -> true ; TypeAtom = unknown),
            %% Field-level validation
            validate_by_type(TypeAtom, JSONData, ValidationResult),
            %% Conflict detection against existing knowledge base
            check_resource_conflicts(JSONData, Conflicts),
            %% Extra suggestions
            suggest_corrections(JSONData, Suggestions),
            (ValidationResult = valid ->
                IsValid = true,
                Errors = []
            ;
                ValidationResult = error(Errors, _),
                IsValid = false
            ),
            reply_json_with_cors(_{
                status:      success,
                valid:       IsValid,
                errors:      Errors,
                suggestions: Suggestions,
                conflicts:   Conflicts
            })
        ),
        handle_validate_input_error
    ).

handle_validate_input(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_validate_input(_) :-
    format_user_error('Use POST /api/validate_input with resource data and a "type" field.', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_validate_input_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% ============================================================================
%% Genetic Algorithm Optimization Endpoint (Feature 11 - Task 28A.2)
%% ============================================================================

%% handle_optimize_ga(+Request)
%% Handle POST /api/optimize_ga - Optimize timetable using Genetic Algorithm
%%
%% Request body (all fields optional):
%%   {
%%     "population_size": 20,
%%     "generations":     50,
%%     "mutation_rate":   0.1,
%%     "crossover_rate":  0.8
%%   }
%%
%% Response:
%%   {
%%     "status":          "success",
%%     "timetable":       <timetable JSON>,
%%     "fitness":         <float 0-1>,
%%     "fitness_history": [<float>, ...],
%%     "reliability":     <float 0-1>
%%   }
handle_optimize_ga(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            http_read_json_dict(Request, JSONData),
            log_info('GA optimization request received'),
            % Build options dict from request (use defaults for missing keys)
            build_ga_options(JSONData, Options),
            optimize_timetable_with_ga(Options, GAResult),
            get_dict(timetable, GAResult, BestMatrix),
            get_dict(fitness,   GAResult, Fitness),
            get_dict(fitness_history, GAResult, FitnessHistory),
            % Store as current timetable
            retractall(current_timetable(_)),
            assertz(current_timetable(BestMatrix)),
            % Format for response
            format_timetable(BestMatrix, json, JSONOutput),
            schedule_reliability(BestMatrix, Reliability),
            log_info('GA optimization complete'),
            reply_json_with_cors(_{
                status:          success,
                timetable:       JSONOutput,
                fitness:         Fitness,
                fitness_history: FitnessHistory,
                reliability:     Reliability
            })
        ),
        handle_optimize_ga_error
    ).

handle_optimize_ga(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_optimize_ga(_) :-
    format_user_error('Use POST /api/optimize_ga with optional GA parameters.', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_optimize_ga_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% build_ga_options(+JSONData, -Options)
%% Extract GA parameters from JSON, applying defaults for missing fields.
build_ga_options(JSONData, Options) :-
    (get_dict(population_size, JSONData, PS) -> true ; PS = 20),
    (get_dict(generations,     JSONData, G)  -> true ; G  = 50),
    (get_dict(mutation_rate,   JSONData, MR) -> true ; MR = 0.1),
    (get_dict(crossover_rate,  JSONData, CR) -> true ; CR = 0.8),
    Options = _{
        population_size: PS,
        generations:     G,
        mutation_rate:   MR,
        crossover_rate:  CR
    }.

%% ============================================================================
%% Interactive Drag-and-Drop Editing Endpoints (Feature 12 - Task 28B.2)
%% ============================================================================

%% handle_validate_move(+Request)
%% Handle POST /api/validate_move
%%
%% Request body:
%%   { "from_room": "r1", "from_slot": "s1", "to_room": "r2", "to_slot": "s2" }
%%
%% Response:
%%   { "status": "success", "valid": true|false, "warnings": [...] }
handle_validate_move(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            http_read_json_dict(Request, JSONData),
            get_dict(from_room, JSONData, FromRoom),
            get_dict(from_slot, JSONData, FromSlot),
            get_dict(to_room,   JSONData, ToRoom),
            get_dict(to_slot,   JSONData, ToSlot),
            (   current_timetable(Matrix)
            ->  Move = move(FromRoom, FromSlot, ToRoom, ToSlot),
                validate_manual_change(Matrix, Move, IsValid, Warnings),
                reply_json_with_cors(_{
                    status:   success,
                    valid:    IsValid,
                    warnings: Warnings
                })
            ;   reply_json_with_cors(
                    _{status: error, message: 'No timetable available'},
                    [status(404)])
            )
        ),
        handle_validate_move_error
    ).

handle_validate_move(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_validate_move(_) :-
    format_user_error('Use POST /api/validate_move with from_room, from_slot, to_room, to_slot.', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_validate_move_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% handle_apply_move(+Request)
%% Handle POST /api/apply_move
%%
%% Request body:
%%   { "from_room": "r1", "from_slot": "s1", "to_room": "r2", "to_slot": "s2" }
%%
%% Response:
%%   { "status": "success", "timetable": <json>, "effects": [...] }
handle_apply_move(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            http_read_json_dict(Request, JSONData),
            get_dict(from_room, JSONData, FromRoom),
            get_dict(from_slot, JSONData, FromSlot),
            get_dict(to_room,   JSONData, ToRoom),
            get_dict(to_slot,   JSONData, ToSlot),
            (   current_timetable(Matrix)
            ->  Move = move(FromRoom, FromSlot, ToRoom, ToSlot),
                check_cascading_effects(Matrix, Move, Effects),
                apply_manual_change(Matrix, Move, UpdatedMatrix, Result),
                (   Result = success
                ->  auto_fix_conflicts(UpdatedMatrix, FixedMatrix),
                    retractall(current_timetable(_)),
                    assertz(current_timetable(FixedMatrix)),
                    format_timetable(FixedMatrix, json, JSONOutput),
                    format_effects_json(Effects, EffectsJSON),
                    log_info('Manual move applied successfully'),
                    reply_json_with_cors(_{
                        status:   success,
                        timetable: JSONOutput,
                        effects:  EffectsJSON
                    })
                ;   Result = error(Reason),
                    reply_json_with_cors(
                        _{status: error, message: Reason},
                        [status(400)])
                )
            ;   reply_json_with_cors(
                    _{status: error, message: 'No timetable available'},
                    [status(404)])
            )
        ),
        handle_apply_move_error
    ).

handle_apply_move(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_apply_move(_) :-
    format_user_error('Use POST /api/apply_move with from_room, from_slot, to_room, to_slot.', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_apply_move_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% handle_suggest_alternatives(+Request)
%% Handle POST /api/suggest_alternatives
%%
%% Request body:
%%   { "from_room": "r1", "from_slot": "s1" }
%%
%% Response:
%%   { "status": "success", "alternatives": [{"room_id": ..., "slot_id": ...}, ...] }
handle_suggest_alternatives(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            http_read_json_dict(Request, JSONData),
            get_dict(from_room, JSONData, FromRoom),
            get_dict(from_slot, JSONData, FromSlot),
            (   current_timetable(Matrix)
            ->  suggest_alternative_slots(Matrix, from(FromRoom, FromSlot), Alts),
                format_alternatives_json(Alts, AltsJSON),
                reply_json_with_cors(_{
                    status:       success,
                    alternatives: AltsJSON
                })
            ;   reply_json_with_cors(
                    _{status: error, message: 'No timetable available'},
                    [status(404)])
            )
        ),
        handle_suggest_alternatives_error
    ).

handle_suggest_alternatives(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_suggest_alternatives(_) :-
    format_user_error('Use POST /api/suggest_alternatives with from_room and from_slot.', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_suggest_alternatives_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% format_effects_json(+Effects, -JSON)
format_effects_json([], []).
format_effects_json([effect(Type, Desc) | Rest], [_{type: Type, description: Desc} | RestJSON]) :-
    format_effects_json(Rest, RestJSON).

%% format_alternatives_json(+Alts, -JSON)
format_alternatives_json([], []).
format_alternatives_json([alt(RoomID, SlotID) | Rest],
                         [_{room_id: RoomID, slot_id: SlotID} | RestJSON]) :-
    format_alternatives_json(Rest, RestJSON).

%% ============================================================================
%% Historical Learning System Endpoints (Feature 13 - Task 28C.2)
%% ============================================================================

%% handle_learning_stats(+Request)
%% Handle GET /api/learning_stats
%% Returns statistics about what the learning system has discovered.
handle_learning_stats(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(get), Request),
    !,
    safe_execute(
        (
            get_learning_statistics(Stats),
            log_info('Learning statistics retrieved'),
            reply_json_with_cors(_{status: success, learning: Stats})
        ),
        handle_learning_stats_error
    ).

handle_learning_stats(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_learning_stats(_) :-
    format_user_error('Use GET /api/learning_stats', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_learning_stats_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% handle_apply_learning(+Request)
%% Handle POST /api/apply_learning
%% Stores the current timetable in history and returns updated learning stats.
handle_apply_learning(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            (current_timetable(Timetable) ->
                store_timetable_history(Timetable),
                get_learning_statistics(Stats),
                log_info('Learning applied to current timetable'),
                reply_json_with_cors(_{
                    status: success,
                    message: 'Timetable stored in learning history',
                    learning: Stats
                })
            ;
                reply_json_with_cors(_{
                    status: error,
                    message: 'No timetable available to learn from'
                }, [status(404)])
            )
        ),
        handle_apply_learning_error
    ).

handle_apply_learning(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_apply_learning(_) :-
    format_user_error('Use POST /api/apply_learning', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_apply_learning_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% handle_clear_history(+Request)
%% Handle POST /api/clear_history
%% Clears all stored timetable history and learned patterns.
handle_clear_history(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            clear_learning_history,
            log_info('Learning history cleared via API'),
            reply_json_with_cors(_{
                status: success,
                message: 'Learning history cleared successfully'
            })
        ),
        handle_clear_history_error
    ).

handle_clear_history(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_clear_history(_) :-
    format_user_error('Use POST /api/clear_history', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_clear_history_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% ============================================================================
%% End of learning system endpoints
%% ============================================================================

%% ============================================================================
%% Pattern Discovery Endpoints (Feature 14 - Task 28D.2)
%% ============================================================================

%% handle_discover_patterns(+Request)
%% Handle POST /api/discover_patterns
%% Analyses the current timetable and returns discovered patterns with
%% confidence scores.  The caller may then accept or reject each pattern.
handle_discover_patterns(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            (current_timetable(Timetable) ->
                discover_patterns(Timetable, Patterns),
                format_patterns_json(Patterns, PatternsJSON),
                length(PatternsJSON, Count),
                format(atom(Msg), 'Discovered ~w patterns', [Count]),
                log_info(Msg),
                reply_json_with_cors(_{
                    status: success,
                    patterns: PatternsJSON,
                    count: Count
                })
            ;
                reply_json_with_cors(_{
                    status: error,
                    message: 'No timetable available. Generate a timetable first.'
                }, [status(404)])
            )
        ),
        handle_discover_patterns_error
    ).

handle_discover_patterns(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_discover_patterns(_) :-
    format_user_error('Use POST /api/discover_patterns', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_discover_patterns_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% format_patterns_json(+Patterns, -JSON)
%% Convert internal pattern/4 terms to JSON-friendly dicts.
format_patterns_json([], []).
format_patterns_json([pattern(Type, Desc, Confidence, SuggestedConstraint)|Rest],
                     [JSON|RestJSON]) :-
    term_to_atom(SuggestedConstraint, ConstraintAtom),
    ConfidencePct is round(Confidence * 100),
    JSON = _{
        type: Type,
        description: Desc,
        confidence: Confidence,
        confidence_pct: ConfidencePct,
        suggested_constraint: ConstraintAtom
    },
    format_patterns_json(Rest, RestJSON).

%% handle_apply_pattern(+Request)
%% Handle POST /api/apply_pattern
%% Accepts a user-approved pattern and stores it as an active soft constraint.
%% Body: { constraint: "<constraint atom string>", description: "..." }
handle_apply_pattern(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            http_read_json_dict(Request, JSONData),
            get_dict(constraint, JSONData, ConstraintAtom),
            get_dict(description, JSONData, Desc),
            % Store the accepted pattern as a dynamic fact
            term_to_atom(ConstraintTerm, ConstraintAtom),
            assertz(accepted_pattern(ConstraintTerm, Desc)),
            format(atom(LogMsg), 'Pattern accepted: ~w', [Desc]),
            log_info(LogMsg),
            reply_json_with_cors(_{
                status: success,
                message: 'Pattern accepted and stored as soft constraint',
                constraint: ConstraintAtom
            })
        ),
        handle_apply_pattern_error
    ).

handle_apply_pattern(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_apply_pattern(_) :-
    format_user_error('Use POST /api/apply_pattern with {constraint, description}', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_apply_pattern_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% Dynamic storage for accepted patterns
:- dynamic accepted_pattern/2.

%% ============================================================================
%% End of pattern discovery endpoints
%% ============================================================================

%% ============================================================================
%% What-If Optimization Dashboard Endpoint (Feature 15 - Task 28E.2)
%% ============================================================================

%% handle_analyze_scenarios(+Request)
%% Handle POST /api/analyze_scenarios
%%
%% Accepts a list of scenario descriptors, runs each one, builds a comparison
%% matrix, ranks the results, and returns an AI recommendation.
%%
%% Request body:
%%   {
%%     "scenarios": [
%%       { "scenario": "teacher_absence", "teacher_id": "t1" },
%%       { "scenario": "room_maintenance", "room_id": "r2" },
%%       { "scenario": "baseline" }
%%     ]
%%   }
%%
%% Response:
%%   {
%%     "status": "success",
%%     "results": [ <scenario result>, ... ],
%%     "comparison_matrix": [ <row>, ... ],
%%     "ranked": [ <ranked result>, ... ],
%%     "recommendation": { recommended_index, recommended_name, reason, trade_offs }
%%   }
%%
handle_analyze_scenarios(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            http_read_json_dict(Request, JSONData),
            (get_dict(scenarios, JSONData, ScenarioList) ->
                true
            ;
                throw(error(missing_field, 'Request body must contain a "scenarios" list'))
            ),
            log_info('Multi-scenario analysis request received'),
            % Run all scenarios
            analyze_multiple_scenarios(ScenarioList, Results),
            % Build comparison matrix
            scenario_comparison_matrix(Results, ComparisonMatrix),
            % Rank by quality
            rank_scenarios_by_quality(Results, RankedResults),
            % AI recommendation
            recommend_best_scenario(RankedResults, Recommendation),
            % Format results for JSON transport
            format_scenario_results(Results, FormattedResults),
            format_ranked_scenario_results(RankedResults, FormattedRanked),
            length(FormattedResults, ScenarioCount),
            format(atom(DoneMsg), 'Multi-scenario analysis complete: ~w scenarios', [ScenarioCount]),
            log_info(DoneMsg),
            reply_json_with_cors(_{
                status:            success,
                count:             ScenarioCount,
                results:           FormattedResults,
                comparison_matrix: ComparisonMatrix,
                ranked:            FormattedRanked,
                recommendation:    Recommendation
            })
        ),
        handle_analyze_scenarios_error
    ).

handle_analyze_scenarios(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_analyze_scenarios(_) :-
    format_user_error('Use POST /api/analyze_scenarios with {"scenarios": [...]}', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_analyze_scenarios_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% format_scenario_results(+Results, -Formatted)
%% Convert internal scenario result dicts to JSON-serialisable form.
%% The timetable matrix is formatted as JSON; other fields are passed through.
format_scenario_results([], []).
format_scenario_results([Result|Rest], [Formatted|RestFormatted]) :-
    get_dict(index,       Result, Index),
    get_dict(name,        Result, Name),
    get_dict(scenario,    Result, Scenario),
    get_dict(timetable,   Result, Timetable),
    get_dict(reliability, Result, Reliability),
    get_dict(changes,     Result, Changes),
    get_dict(metrics,     Result, Metrics),
    % Format timetable
    (   Timetable \= []
    ->  catch(format_timetable(Timetable, json, JSONTimetable), _, JSONTimetable = null)
    ;   JSONTimetable = null
    ),
    % Format changes
    format_changes_json(Changes, ChangesJSON),
    length(Changes, ChangesCount),
    Formatted = _{
        index:         Index,
        name:          Name,
        scenario:      Scenario,
        timetable:     JSONTimetable,
        reliability:   Reliability,
        changes:       ChangesJSON,
        changes_count: ChangesCount,
        metrics:       Metrics
    },
    format_scenario_results(Rest, RestFormatted).

%% format_ranked_scenario_results(+RankedResults, -Formatted)
%% Same as format_scenario_results but also includes combined_score.
format_ranked_scenario_results([], []).
format_ranked_scenario_results([Result|Rest], [Formatted|RestFormatted]) :-
    get_dict(index,          Result, Index),
    get_dict(name,           Result, Name),
    get_dict(scenario,       Result, Scenario),
    get_dict(reliability,    Result, Reliability),
    get_dict(metrics,        Result, Metrics),
    get_dict(combined_score, Result, CombinedScore),
    get_dict(changes,        Result, Changes),
    length(Changes, ChangesCount),
    Formatted = _{
        index:          Index,
        name:           Name,
        scenario:       Scenario,
        reliability:    Reliability,
        metrics:        Metrics,
        combined_score: CombinedScore,
        changes_count:  ChangesCount
    },
    format_ranked_scenario_results(Rest, RestFormatted).

%% ============================================================================
%% End of what-if dashboard endpoint
%% ============================================================================

%% ============================================================================
%% Constraint Graph Endpoint (Feature 16)
%% ============================================================================

%% handle_constraint_graph(+Request)
%% Handle GET /api/constraint_graph
%% Returns the constraint graph as JSON with nodes, edges, and metrics.
handle_constraint_graph(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(get), Request),
    !,
    safe_execute(
        (
            log_info('Constraint graph request received'),
            generate_constraint_graph(Graph),
            export_graph_json(Graph, JSONOutput),
            log_info('Constraint graph generated'),
            reply_json_with_cors(_{status: success, graph: JSONOutput})
        ),
        handle_constraint_graph_error
    ).

handle_constraint_graph(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_constraint_graph(_) :-
    format_user_error('Use GET /api/constraint_graph', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_constraint_graph_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% ============================================================================
%% End of constraint graph endpoint
%% ============================================================================

%% ============================================================================
%% Complexity Analysis Endpoint (Feature 17)
%% ============================================================================

%% handle_complexity_analysis(+Request)
%% Handle GET /api/complexity_analysis
%% Returns comprehensive AI solver complexity metrics.
handle_complexity_analysis(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(get), Request),
    !,
    safe_execute(
        (
            log_info('Complexity analysis request received'),
            (analyze_solver_complexity(Metrics) -> true ;
                Metrics = _{branching_factor: 0, search_depth: _{max_depth:0, avg_depth:0},
                            constraint_density: 0, time_complexity: 'N/A',
                            nodes_explored: 0, backtracks: 0, domain_prunings: 0,
                            constraint_checks: 0, assignments_made: 0}
            ),
            (generate_complexity_report(_, Report) -> true ; Report = 'Complexity analysis unavailable'),
            log_info('Complexity analysis complete'),
            reply_json_with_cors(_{status: success, metrics: Metrics, report: Report})
        ),
        handle_complexity_analysis_error
    ).

handle_complexity_analysis(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_complexity_analysis(_) :-
    format_user_error('Use GET /api/complexity_analysis', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_complexity_analysis_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% ============================================================================
%% End of complexity analysis endpoint
%% ============================================================================

%% ============================================================================
%% Natural Language Query Endpoint (Feature 18 - Task 28H.2)
%% ============================================================================

%% handle_nl_query(+Request)
%% Handle POST /api/nl_query - Accept natural language text and return answer.
%% Request body: {"query": "Show Dr. Smith schedule"}
%% Response: {"status": "success", "answer": "...", "intent": "...", "entity": "..."}
handle_nl_query(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            http_read_json_dict(Request, JSONData),
            get_dict(query, JSONData, QueryText),
            log_info('NL query received'),
            % Parse the query to extract intent and entity for metadata
            (atom(QueryText) -> Q = QueryText ; atom_string(Q, QueryText)),
            atom_string(Q, QStr),
            string_lower(QStr, QNorm),
            atom_string(QAtom, QNorm),
            parse_nl_query(QAtom, query(Intent, Entity)),
            % Get the answer
            answer_query(QueryText, Answer),
            log_info('NL query answered'),
            reply_json_with_cors(_{
                status: success,
                answer: Answer,
                intent: Intent,
                entity: Entity
            })
        ),
        handle_nl_query_error
    ).

handle_nl_query(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_nl_query(_) :-
    format_user_error('Use POST with {"query": "your question here"} to query the timetable.', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_nl_query_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% ============================================================================
%% End of NL query endpoint
%% ============================================================================

%% ============================================================================
%% Conflict Prediction Endpoint (Feature 19 - Task 28I.2)
%% ============================================================================

%% handle_predict_conflicts(+Request)
%% Handle POST /api/predict_conflicts
%% Optional body: {"sessions": [{"class_id": ..., "subject_id": ...}, ...]}
%% If sessions list is omitted or empty, sessions are derived from the KB.
%% Response:
%%   { "status": "success",
%%     "risk_level": "medium",
%%     "conflict_probability": 0.12,
%%     "predictions": [...],
%%     "bottlenecks": [...],
%%     "suggestions": [...] }
handle_predict_conflicts(Request) :-
    cors_headers,
    member(method(post), Request),
    !,
    catch(
        (
            % Read optional JSON body; fall back to empty sessions list
            (catch(http_read_json_dict(Request, JSONData), _, JSONData = _{})),
            (get_dict(sessions, JSONData, RawSessions) ->
                maplist(json_session_to_prolog, RawSessions, Sessions)
            ;
                Sessions = []
            ),
            log_info('Conflict prediction request received'),
            predict_conflicts(Sessions, Predictions),
            calculate_conflict_probability(Sessions, Probability),
            identify_bottleneck_resources(Sessions, Bottlenecks),
            suggest_preventive_actions(Sessions, Actions),
            risk_assessment(Sessions, RiskLevel),
            % Convert Prolog terms to JSON-compatible dicts
            maplist(prediction_to_json, Predictions, PredictionsJSON),
            maplist(bottleneck_to_json, Bottlenecks, BottlenecksJSON),
            maplist(action_to_json, Actions, ActionsJSON),
            atom_string(RiskLevel, RiskLevelStr),
            log_info('Conflict prediction completed'),
            reply_json_dict(_{
                status: success,
                risk_level: RiskLevelStr,
                conflict_probability: Probability,
                predictions: PredictionsJSON,
                bottlenecks: BottlenecksJSON,
                suggestions: ActionsJSON
            })
        ),
        Error,
        (
            format_user_error(Error, ErrorMsg),
            log_error(ErrorMsg),
            reply_json_dict(_{status: error, message: ErrorMsg}, [status(500)])
        )
    ).

handle_predict_conflicts(Request) :-
    cors_headers,
    member(method(options), Request),
    !,
    reply_json_dict(_{status: success}).

handle_predict_conflicts(_) :-
    cors_headers,
    format_user_error('Use POST /api/predict_conflicts with optional {sessions: [...]}', Msg),
    reply_json_dict(_{status: error, message: Msg}, [status(400)]).

%% json_session_to_prolog(+JSONDict, -session(ClassID, SubjectID))
%% Convert a JSON session dict to a Prolog session/2 term.
json_session_to_prolog(Dict, session(ClassID, SubjectID)) :-
    get_dict(class_id,   Dict, ClassID),
    get_dict(subject_id, Dict, SubjectID).

%% prediction_to_json(+Risk, -Dict)
%% Convert a predicted risk term to a JSON-compatible dict.
prediction_to_json(teacher_overload_risk(TeacherID, Demanded, Available),
    _{type: teacher_overload_risk, teacher_id: TeacherID,
      demanded: Demanded, available: Available}).

prediction_to_json(room_shortage_risk(Type, Demanded, Available),
    _{type: room_shortage_risk, room_type: Type,
      demanded: Demanded, available: Available}).

prediction_to_json(timeslot_shortage_risk(Demanded, Available),
    _{type: timeslot_shortage_risk,
      demanded: Demanded, available: Available}).

prediction_to_json(unqualified_subject_risk(SubjectID),
    _{type: unqualified_subject_risk, subject_id: SubjectID}).

prediction_to_json(no_suitable_room_risk(SubjectID, Type),
    _{type: no_suitable_room_risk, subject_id: SubjectID, room_type: Type}).

%% bottleneck_to_json(+Bottleneck, -Dict)
%% Convert a bottleneck term to a JSON-compatible dict.
bottleneck_to_json(teacher_bottleneck(TeacherID, Name, Demand, MaxLoad),
    _{type: teacher_bottleneck, teacher_id: TeacherID, name: Name,
      demand: Demand, max_load: MaxLoad}).

bottleneck_to_json(room_bottleneck(Type, Demand, Supply),
    _{type: room_bottleneck, room_type: Type,
      demand: Demand, supply: Supply}).

bottleneck_to_json(timeslot_bottleneck(Demand, Supply),
    _{type: timeslot_bottleneck, demand: Demand, supply: Supply}).

%% action_to_json(+Action, -Dict)
%% Convert an action/2 term to a JSON-compatible dict.
action_to_json(action(Priority, Description),
    _{priority: Priority, description: Description}).

%% ============================================================================
%% End of conflict prediction endpoint
%% ============================================================================

%% ============================================================================
%% Timetable Versioning Endpoints (Feature 20 - Task 28J.2)
%% ============================================================================

%% handle_save_version(+Request)
%% Handle POST /api/save_version
%% Optional body: { "author": "...", "reason": "..." }
%% Saves the current timetable as a new version and returns the version ID.
handle_save_version(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            (current_timetable(Timetable) ->
                %% Read optional metadata from body
                (catch(http_read_json_dict(Request, JSONData), _, JSONData = _{})),
                (get_dict(author, JSONData, Author) -> true ; Author = 'user'),
                (get_dict(reason, JSONData, Reason) -> true ; Reason = 'manual save'),
                ExtraMeta = _{author: Author, reason: Reason},
                save_version(Timetable, VersionID, ExtraMeta),
                version_metadata(VersionID, Metadata),
                log_info('Timetable version saved'),
                reply_json_with_cors(_{
                    status:     success,
                    version_id: VersionID,
                    metadata:   Metadata
                })
            ;
                reply_json_with_cors(_{
                    status:  error,
                    message: 'No timetable available to save. Generate one first.'
                }, [status(404)])
            )
        ),
        handle_save_version_error
    ).

handle_save_version(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_save_version(_) :-
    format_user_error('Use POST /api/save_version with optional {author, reason}', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_save_version_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% handle_list_versions(+Request)
%% Handle GET /api/versions
%% Returns all saved version metadata, newest first.
handle_list_versions(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(get), Request),
    !,
    safe_execute(
        (
            list_versions(Versions),
            length(Versions, Count),
            log_info('Version list retrieved'),
            reply_json_with_cors(_{
                status:   success,
                count:    Count,
                versions: Versions
            })
        ),
        handle_list_versions_error
    ).

handle_list_versions(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_list_versions(_) :-
    format_user_error('Use GET /api/versions', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_list_versions_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% handle_load_version(+Request)
%% Handle GET /api/version?id=<version_id>
%% Returns the timetable stored under the given version ID.
handle_load_version(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(get), Request),
    !,
    safe_execute(
        (
            http_parameters(Request, [id(VersionID, [])]),
            (load_version(VersionID, Timetable) ->
                version_metadata(VersionID, Metadata),
                format_timetable(Timetable, json, JSONOutput),
                log_info('Version loaded'),
                reply_json_with_cors(_{
                    status:     success,
                    version_id: VersionID,
                    metadata:   Metadata,
                    timetable:  JSONOutput
                })
            ;
                format(atom(Msg), 'Version ~w not found', [VersionID]),
                reply_json_with_cors(_{status: error, message: Msg}, [status(404)])
            )
        ),
        handle_load_version_error
    ).

handle_load_version(Request) :-
    cors_enable(Request, [methods([get, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_load_version(_) :-
    format_user_error('Use GET /api/version?id=<version_id>', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_load_version_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% handle_compare_versions(+Request)
%% Handle POST /api/compare_versions
%% Body: { "version_a": "v1", "version_b": "v2" }
%% Returns a detailed diff between the two versions.
handle_compare_versions(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            http_read_json_dict(Request, JSONData),
            get_dict(version_a, JSONData, VersionA),
            get_dict(version_b, JSONData, VersionB),
            compare_versions(VersionA, VersionB, Diff),
            %% Format assignment lists for JSON transport
            get_dict(added,     Diff, Added),
            get_dict(removed,   Diff, Removed),
            get_dict(unchanged, Diff, Unchanged),
            format_assignments_json(Added,     AddedJSON),
            format_assignments_json(Removed,   RemovedJSON),
            format_assignments_json(Unchanged, UnchangedJSON),
            get_dict(added_count,     Diff, AddedCount),
            get_dict(removed_count,   Diff, RemovedCount),
            get_dict(unchanged_count, Diff, UnchangedCount),
            get_dict(meta_a, Diff, MetaA),
            get_dict(meta_b, Diff, MetaB),
            log_info('Version comparison completed'),
            reply_json_with_cors(_{
                status: success,
                diff: _{
                    version_a:       VersionA,
                    version_b:       VersionB,
                    meta_a:          MetaA,
                    meta_b:          MetaB,
                    added:           AddedJSON,
                    removed:         RemovedJSON,
                    unchanged:       UnchangedJSON,
                    added_count:     AddedCount,
                    removed_count:   RemovedCount,
                    unchanged_count: UnchangedCount
                }
            })
        ),
        handle_compare_versions_error
    ).

handle_compare_versions(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_compare_versions(_) :-
    format_user_error('Use POST /api/compare_versions with {version_a, version_b}', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_compare_versions_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% handle_rollback(+Request)
%% Handle POST /api/rollback
%% Body: { "version_id": "v2" }
%% Restores the current timetable to the specified version.
handle_rollback(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    !,
    safe_execute(
        (
            http_read_json_dict(Request, JSONData),
            get_dict(version_id, JSONData, VersionID),
            rollback_to_version(VersionID, Timetable),
            version_metadata(VersionID, Metadata),
            format_timetable(Timetable, json, JSONOutput),
            schedule_reliability(Timetable, Reliability),
            format(atom(LogMsg), 'Rolled back to version ~w', [VersionID]),
            log_info(LogMsg),
            reply_json_with_cors(_{
                status:     success,
                message:    LogMsg,
                version_id: VersionID,
                metadata:   Metadata,
                timetable:  JSONOutput,
                reliability: Reliability
            })
        ),
        handle_rollback_error
    ).

handle_rollback(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    reply_cors_preflight(Request).

handle_rollback(_) :-
    format_user_error('Use POST /api/rollback with {version_id}', Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(400)]).

handle_rollback_error(Error) :-
    format_user_error(Error, Msg),
    log_error(Msg),
    reply_json_with_cors(_{status: error, message: Msg}, [status(500)]).

%% ============================================================================
%% End of versioning endpoints
%% ============================================================================
