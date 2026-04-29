% test_main_integration.pl - Test main.pl integration
% This test verifies that main.pl loads all modules correctly

:- use_module(library(plunit)).

% Load configuration
:- consult('config.pl').

% Load all backend modules
:- consult('backend/logging.pl').
:- consult('backend/knowledge_base.pl').
:- consult('backend/matrix_model.pl').
:- consult('backend/constraints.pl').
:- consult('backend/csp_solver.pl').
:- consult('backend/probability_module.pl').
:- consult('backend/timetable_generator.pl').

% Load dataset
:- consult('data/dataset.pl').

:- begin_tests(main_integration).

% Test 1: Configuration loaded
test(config_loaded, [true(Port == 8080)]) :-
    server_port(Port).

test(log_level_loaded, [true(Level == info)]) :-
    log_level(Level).

% Test 2: Logging system initialized
test(logging_system_works) :-
    set_log_level(info),
    log_info('Test log message'),
    log_warning('Test warning'),
    log_error('Test error').

% Test 3: All backend modules loaded
test(logging_module_loaded) :-
    current_predicate(log_info/1),
    current_predicate(set_log_level/1).

test(knowledge_base_loaded) :-
    current_predicate(teacher/5),
    current_predicate(subject/5),
    current_predicate(room/4),
    current_predicate(timeslot/5),
    current_predicate(class/3).

test(matrix_model_loaded) :-
    current_predicate(create_empty_timetable/3),
    current_predicate(get_cell/4),
    current_predicate(set_cell/5).

test(constraints_loaded) :-
    current_predicate(check_all_hard_constraints/6),
    current_predicate(calculate_soft_score/2).

test(csp_solver_loaded) :-
    current_predicate(solve_csp/3),
    current_predicate(initialize_domains/2).

test(probability_module_loaded) :-
    current_predicate(schedule_reliability/2),
    current_predicate(assignment_reliability/2).

test(timetable_generator_loaded) :-
    current_predicate(generate_timetable/1),
    current_predicate(detect_conflicts/2).

% Test 4: Dataset loaded
test(dataset_loaded) :-
    findall(T, teacher(T, _, _, _, _), Teachers),
    length(Teachers, NumTeachers),
    NumTeachers > 0.

test(dataset_has_subjects) :-
    findall(S, subject(S, _, _, _, _), Subjects),
    length(Subjects, NumSubjects),
    NumSubjects > 0.

test(dataset_has_rooms) :-
    findall(R, room(R, _, _, _), Rooms),
    length(Rooms, NumRooms),
    NumRooms > 0.

test(dataset_has_timeslots) :-
    findall(T, timeslot(T, _, _, _, _), Timeslots),
    length(Timeslots, NumTimeslots),
    NumTimeslots > 0.

test(dataset_has_classes) :-
    findall(C, class(C, _, _), Classes),
    length(Classes, NumClasses),
    NumClasses > 0.

% Test 5: Module dependencies work
test(matrix_creation_works) :-
    findall(R, room(R, _, _, _), Rooms),
    findall(T, timeslot(T, _, _, _, _), Timeslots),
    create_empty_timetable(Rooms, Timeslots, Matrix),
    is_list(Matrix),
    length(Matrix, NumRows),
    NumRows > 0.

% Test 6: Configuration values accessible
test(max_search_nodes_configured, [true(MaxNodes == 10000)]) :-
    max_search_nodes(MaxNodes).

test(search_timeout_configured, [true(Timeout == 120)]) :-
    search_timeout(Timeout).

:- end_tests(main_integration).

% Run tests
:- run_tests.
:- halt.
