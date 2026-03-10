% config.pl - Configuration settings for AI-Based Timetable Generation System

% Server Configuration
% Port number for HTTP server (default: 8080)
:- dynamic server_port/1.
server_port(8080).

% Logging Configuration
% Log levels: debug, info, warning, error
:- dynamic log_level/1.
log_level(info).

% CSP Solver Configuration
% Maximum search nodes before timeout (default: 10000)
:- dynamic max_search_nodes/1.
max_search_nodes(10000).

% Search timeout in seconds (default: 120)
:- dynamic search_timeout/1.
search_timeout(120).

% API Configuration
% Enable CORS for cross-origin requests (default: true)
:- dynamic enable_cors/1.
enable_cors(true).

% Maximum request payload size in bytes (default: 1MB)
:- dynamic max_payload_size/1.
max_payload_size(1048576).

% Request timeout in seconds (default: 300)
:- dynamic request_timeout/1.
request_timeout(300).

% Probability Module Configuration
% Default teacher availability probability (default: 0.95)
:- dynamic default_teacher_availability/1.
default_teacher_availability(0.95).

% Default room availability probability (default: 0.98)
:- dynamic default_room_availability/1.
default_room_availability(0.98).

% Default class occurrence probability (default: 0.99)
:- dynamic default_class_occurrence/1.
default_class_occurrence(0.99).

% Soft Constraint Weights (0.0 to 1.0)
:- dynamic weight_balanced_workload/1.
weight_balanced_workload(1.0).

:- dynamic weight_avoid_late_theory/1.
weight_avoid_late_theory(0.8).

:- dynamic weight_minimize_gaps/1.
weight_minimize_gaps(0.9).

:- dynamic weight_teacher_preferences/1.
weight_teacher_preferences(0.7).

% Performance Configuration
% Log progress every N search nodes (default: 1000)
:- dynamic log_progress_interval/1.
log_progress_interval(1000).

% Enable search statistics collection (default: true)
:- dynamic enable_search_stats/1.
enable_search_stats(true).

% Database Configuration
% Enable persistent storage (default: false, in-memory only)
:- dynamic enable_persistence/1.
enable_persistence(false).

% Database file path (if persistence enabled)
:- dynamic database_file/1.
database_file('data/timetable_db.pl').

% Frontend Configuration
% Frontend directory path
:- dynamic frontend_path/1.
frontend_path('frontend').

% Export Configuration
% Temporary directory for export files
:- dynamic export_temp_dir/1.
export_temp_dir('temp/exports').

% Enable PDF export (requires external library)
:- dynamic enable_pdf_export/1.
enable_pdf_export(false).

% Enable CSV export
:- dynamic enable_csv_export/1.
enable_csv_export(true).

% Enable JSON export
:- dynamic enable_json_export/1.
enable_json_export(true).

% Development Configuration
% Enable debug mode (verbose logging)
:- dynamic debug_mode/1.
debug_mode(false).

% Enable hot reload (reload modules on change)
:- dynamic enable_hot_reload/1.
enable_hot_reload(false).

% Configuration Helper Predicates

% Get configuration value with default fallback
get_config(Key, Value) :-
    call(Key, Value), !.
get_config(_, default).

% Update configuration value dynamically
set_config(Key, Value) :-
    functor(Predicate, Key, 1),
    retractall(Predicate),
    arg(1, Predicate, Value),
    assert(Predicate).

% Display all configuration settings
show_config :-
    writeln('Current Configuration:'),
    writeln(''),
    writeln('Server:'),
    server_port(Port), format('  server_port: ~w~n', [Port]),
    writeln(''),
    writeln('Logging:'),
    log_level(LogLevel), format('  log_level: ~w~n', [LogLevel]),
    writeln(''),
    writeln('CSP Solver:'),
    max_search_nodes(MaxNodes), format('  max_search_nodes: ~w~n', [MaxNodes]),
    search_timeout(Timeout), format('  search_timeout: ~w seconds~n', [Timeout]),
    writeln(''),
    writeln('Soft Constraint Weights:'),
    weight_balanced_workload(W1), format('  balanced_workload: ~w~n', [W1]),
    weight_avoid_late_theory(W2), format('  avoid_late_theory: ~w~n', [W2]),
    weight_minimize_gaps(W3), format('  minimize_gaps: ~w~n', [W3]),
    weight_teacher_preferences(W4), format('  teacher_preferences: ~w~n', [W4]),
    writeln('').
