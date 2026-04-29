% ============================================================================
% search_statistics.pl - AI Search Visualization Statistics Module
% ============================================================================
% This module tracks and exposes statistics about the CSP search process,
% enabling visualization of the AI search algorithm's behavior.
%
% Statistics tracked:
% - nodes_explored: Total search nodes visited
% - backtracks: Number of backtracking events
% - heuristic_applications: Times MRV/Degree/LCV heuristics were applied
% - domain_prunings: Values pruned via forward checking
% - assignments_made: Successful variable assignments
% - constraint_checks: Total constraint evaluations
%
% Author: AI Timetable Generation System
% ============================================================================

:- module(search_statistics, [
    initialize_search_stats/0,
    increment_stat/1,
    get_search_statistics/1,
    solve_csp_with_stats/3,
    backtracking_search_with_stats/4,
    log_search_statistics/1
]).

:- use_module(knowledge_base, [
    qualified/2,
    suitable_room/2,
    teacher_available/2,
    get_all_rooms/1,
    get_all_timeslots/1
]).
:- use_module(matrix_model, [
    set_cell/5,
    get_all_assignments/2
]).
:- use_module(constraints, [
    check_all_hard_constraints/6
]).
:- use_module(csp_solver, [
    initialize_domains/2,
    generate_domain/2,
    get_domain/3,
    update_domain/4,
    has_empty_domain/1,
    select_variable/4,
    order_domain_values/4,
    forward_check/5,
    assign_value/4,
    check_constraints/3,
    filter_domain/4,
    conflicts_with/3
]).
:- use_module(logging, [
    log_info/1,
    log_debug/1
]).

% Dynamic storage for search statistics
:- dynamic search_stat/2.

% ============================================================================
% PART 1: STATISTICS MANAGEMENT
% ============================================================================

% ----------------------------------------------------------------------------
% initialize_search_stats/0: Reset all statistics to zero
% ----------------------------------------------------------------------------
% Clears all existing statistics and initialises counters to 0.
%
initialize_search_stats :-
    retractall(search_stat(_, _)),
    assertz(search_stat(nodes_explored, 0)),
    assertz(search_stat(backtracks, 0)),
    assertz(search_stat(heuristic_applications, 0)),
    assertz(search_stat(domain_prunings, 0)),
    assertz(search_stat(assignments_made, 0)),
    assertz(search_stat(constraint_checks, 0)).

% ----------------------------------------------------------------------------
% increment_stat/1: Increment a named counter by 1
% ----------------------------------------------------------------------------
% @param StatName - Atom naming the statistic to increment
%
increment_stat(StatName) :-
    (   retract(search_stat(StatName, Current))
    ->  NewValue is Current + 1,
        assertz(search_stat(StatName, NewValue))
    ;   assertz(search_stat(StatName, 1))
    ).

% ----------------------------------------------------------------------------
% get_search_statistics/1: Retrieve all statistics as a dict
% ----------------------------------------------------------------------------
% @param Stats - Output dict with all statistic key-value pairs
%
get_search_statistics(Stats) :-
    findall(Name-Value, search_stat(Name, Value), Pairs),
    pairs_to_stats_dict(Pairs, Stats).

% Helper: convert key-value pairs to a Prolog dict
pairs_to_stats_dict(Pairs, Stats) :-
    dict_pairs(Stats, search_stats, Pairs).

% ============================================================================
% PART 2: CSP SOLVER WITH STATISTICS TRACKING
% ============================================================================

% ----------------------------------------------------------------------------
% solve_csp_with_stats/3: CSP solver entry point with statistics
% ----------------------------------------------------------------------------
% Wraps the standard CSP solver, initialising stats before search and
% logging them on completion.
%
% @param Sessions  - List of session(ClassID, SubjectID) to schedule
% @param Matrix    - Initial timetable matrix
% @param Solution  - Output complete timetable matrix
%
solve_csp_with_stats(Sessions, Matrix, Solution) :-
    log_info('Starting CSP solver with statistics tracking'),
    initialize_search_stats,
    length(Sessions, NumSessions),
    format(atom(Msg), 'Scheduling ~w sessions (with stats)', [NumSessions]),
    log_info(Msg),
    initialize_domains(Sessions, Domains),
    backtracking_search_with_stats(Sessions, Domains, Matrix, Solution),
    log_search_statistics(Solution).

% ----------------------------------------------------------------------------
% backtracking_search_with_stats/4: Backtracking search with stat tracking
% ----------------------------------------------------------------------------
% Mirrors backtracking_search/4 from csp_solver.pl but increments counters
% at each decision point.
%
% @param Sessions  - Remaining sessions to assign
% @param Domains   - Current domain map
% @param Matrix    - Current partial timetable matrix
% @param Solution  - Output complete timetable matrix
%
backtracking_search_with_stats([], _, Matrix, Matrix) :- !.
backtracking_search_with_stats(Sessions, Domains, Matrix, Solution) :-
    % Count this node
    increment_stat(nodes_explored),
    increment_stat(heuristic_applications),

    % Select variable using MRV heuristic
    select_variable(Sessions, Domains, SelectedSession, RemainingSessions),
    get_domain(SelectedSession, Domains, Domain),

    % Order values using LCV heuristic
    order_domain_values(Domain, SelectedSession, Matrix, OrderedDomain),

    % Try values
    try_values_with_stats(OrderedDomain, SelectedSession, RemainingSessions, Domains, Matrix, Solution).

% ----------------------------------------------------------------------------
% try_values_with_stats/6: Try domain values with statistics tracking
% ----------------------------------------------------------------------------
try_values_with_stats([Value|_Rest], Session, Remaining, Domains, Matrix, Solution) :-
    Session = session(ClassID, SubjectID),
    Value = value(TeacherID, RoomID, SlotID),

    % Count constraint check
    increment_stat(constraint_checks),
    assign_value(Session, Value, Matrix, NewMatrix),

    (   check_constraints(Session, Value, NewMatrix)
    ->  increment_stat(assignments_made),
        % Forward check and count prunings
        forward_check_with_stats(Session, Value, Remaining, Domains, NewDomains),
        (   \+ has_empty_domain(NewDomains)
        ->  backtracking_search_with_stats(Remaining, NewDomains, NewMatrix, Solution)
        ;   increment_stat(backtracks),
            fail
        )
    ;   increment_stat(backtracks),
        fail
    ),
    !.
try_values_with_stats([_|Rest], Session, Remaining, Domains, Matrix, Solution) :-
    try_values_with_stats(Rest, Session, Remaining, Domains, Matrix, Solution).

% ----------------------------------------------------------------------------
% forward_check_with_stats/5: Forward checking with pruning counter
% ----------------------------------------------------------------------------
forward_check_with_stats(AssignedSession, AssignedValue, RemainingSessions, Domains, NewDomains) :-
    forward_check_all_with_stats(RemainingSessions, AssignedSession, AssignedValue, Domains, NewDomains).

forward_check_all_with_stats([], _, _, Domains, Domains).
forward_check_all_with_stats([Session|Rest], AssignedSession, AssignedValue, Domains, NewDomains) :-
    get_domain(Session, Domains, Domain),
    length(Domain, Before),
    filter_domain(Domain, AssignedSession, AssignedValue, FilteredDomain),
    length(FilteredDomain, After),
    Pruned is Before - After,
    (Pruned > 0 -> increment_stat(domain_prunings) ; true),
    update_domain(Session, FilteredDomain, Domains, TempDomains),
    forward_check_all_with_stats(Rest, AssignedSession, AssignedValue, TempDomains, NewDomains).

% ============================================================================
% PART 3: LOGGING
% ============================================================================

% ----------------------------------------------------------------------------
% log_search_statistics/1: Log all statistics to the console
% ----------------------------------------------------------------------------
% @param _Solution - The completed timetable (unused, kept for interface)
%
log_search_statistics(_Solution) :-
    get_search_statistics(Stats),
    get_dict(nodes_explored,        Stats, Nodes),
    get_dict(backtracks,            Stats, BT),
    get_dict(heuristic_applications,Stats, HA),
    get_dict(domain_prunings,       Stats, DP),
    get_dict(assignments_made,      Stats, AM),
    get_dict(constraint_checks,     Stats, CC),
    format(atom(Msg),
        'Search Statistics: nodes=~w, backtracks=~w, heuristics=~w, prunings=~w, assignments=~w, checks=~w',
        [Nodes, BT, HA, DP, AM, CC]),
    log_info(Msg).

% ============================================================================
% END OF MODULE
% ============================================================================
