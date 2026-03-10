% main.pl - Entry point for AI-Based Timetable Generation System
% This file loads all required modules and starts the HTTP server

:- initialization(main, main).

% Load configuration
:- (exists_file('config.pl') -> consult('config.pl') ; true).

% Set default configuration if not loaded
:- (current_predicate(server_port/1) -> true ; assert(server_port(8080))).
:- (current_predicate(log_level/1) -> true ; assert(log_level(info))).

% Module loading order (will be implemented in later tasks)
% :- consult('backend/logging.pl').
% :- consult('backend/knowledge_base.pl').
% :- consult('backend/matrix_model.pl').
% :- consult('backend/constraints.pl').
% :- consult('backend/csp_solver.pl').
% :- consult('backend/probability_module.pl').
% :- consult('backend/timetable_generator.pl').
% :- consult('backend/api_server.pl').

% Load example dataset if available
% :- (exists_file('data/dataset.pl') -> consult('data/dataset.pl') ; true).

% Main entry point
main :-
    writeln('==========================================='),
    writeln('AI-Based Timetable Generation System'),
    writeln('==========================================='),
    writeln(''),
    
    % Check for required Prolog libraries
    writeln('Checking required libraries...'),
    check_libraries,
    writeln(''),
    
    % Display configuration
    server_port(Port),
    log_level(LogLevel),
    format('Configuration:~n'),
    format('  - Server Port: ~w~n', [Port]),
    format('  - Log Level: ~w~n', [LogLevel]),
    writeln(''),
    
    % Start server (will be implemented in later tasks)
    writeln('Note: Backend modules not yet implemented.'),
    writeln('Run task 2 to create example dataset and documentation.'),
    writeln('Run tasks 3-8 to implement core backend modules.'),
    writeln('Run task 11 to implement API server.'),
    writeln(''),
    writeln('System initialization complete.'),
    writeln('===========================================').

% Check if required Prolog libraries are available
check_libraries :-
    check_library(http/http_server, 'HTTP Server'),
    check_library(http/http_json, 'JSON Support'),
    check_library(lists, 'List Operations').

check_library(Library, Name) :-
    (   catch(use_module(library(Library)), _, fail)
    ->  format('  ✓ ~w (~w) - Available~n', [Name, Library])
    ;   format('  ✗ ~w (~w) - MISSING~n', [Name, Library]),
        format('    Install with: ?- pack_install(~w).~n', [Library]),
        fail
    ).
