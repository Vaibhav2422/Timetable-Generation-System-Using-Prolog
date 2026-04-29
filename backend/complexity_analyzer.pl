% ============================================================================
% complexity_analyzer.pl - AI Complexity Analysis Module
% ============================================================================
% This module analyzes the computational complexity of the CSP solver,
% providing metrics on branching factor, search depth, constraint density,
% and time complexity estimates.
%
% Author: AI Timetable Generation System
% ============================================================================

:- module(complexity_analyzer, [
    analyze_solver_complexity/1,
    calculate_branching_factor/2,
    calculate_search_depth/2,
    calculate_constraint_density/2,
    calculate_time_complexity/2,
    generate_complexity_report/2
]).

:- use_module(knowledge_base, [
    get_all_teachers/1,
    get_all_subjects/1,
    get_all_rooms/1,
    get_all_timeslots/1,
    get_all_classes/1,
    qualified/2,
    suitable_room/2
]).
:- use_module(search_statistics, [
    get_search_statistics/1
]).
:- use_module(logging, [
    log_info/1
]).

% ============================================================================
% PART 1: MAIN ANALYSIS ENTRY POINT
% ============================================================================

% ----------------------------------------------------------------------------
% analyze_solver_complexity/1: Comprehensive complexity metrics
% ----------------------------------------------------------------------------
% Collects all complexity metrics into a single dict.
%
% @param Metrics - Output dict with all complexity metrics
%
analyze_solver_complexity(Metrics) :-
    log_info('Analyzing solver complexity'),
    calculate_branching_factor(_, BranchingFactor),
    calculate_search_depth(_, SearchDepth),
    calculate_constraint_density(_, ConstraintDensity),
    calculate_time_complexity(_, TimeComplexity),
    get_search_statistics(Stats),
    get_dict(nodes_explored,         Stats, NodesExplored),
    get_dict(backtracks,             Stats, Backtracks),
    get_dict(domain_prunings,        Stats, DomainPrunings),
    get_dict(constraint_checks,      Stats, ConstraintChecks),
    get_dict(assignments_made,       Stats, AssignmentsMade),
    Metrics = _{
        branching_factor:    BranchingFactor,
        search_depth:        SearchDepth,
        constraint_density:  ConstraintDensity,
        time_complexity:     TimeComplexity,
        nodes_explored:      NodesExplored,
        backtracks:          Backtracks,
        domain_prunings:     DomainPrunings,
        constraint_checks:   ConstraintChecks,
        assignments_made:    AssignmentsMade
    }.

% ============================================================================
% PART 2: BRANCHING FACTOR
% ============================================================================

% ----------------------------------------------------------------------------
% calculate_branching_factor/2: Average branching factor of the search tree
% ----------------------------------------------------------------------------
% The branching factor is the average number of domain values per variable.
% For CSP: b = avg(|domain(v)|) for all variables.
%
% @param _  - Unused (placeholder for session list)
% @param BF - Output average branching factor
%
calculate_branching_factor(_, BF) :-
    get_all_classes(Classes),
    get_all_subjects(Subjects),
    get_all_teachers(Teachers),
    get_all_rooms(Rooms),
    get_all_timeslots(Slots),
    length(Slots, NumSlots),
    % For each (class, subject) session, domain size = qualified_teachers * suitable_rooms * slots
    findall(DomainSize,
            (member(class(_, _, SubjectList), Classes),
             member(SubjectID, SubjectList),
             count_qualified_teachers(SubjectID, Teachers, QT),
             count_suitable_rooms(SubjectID, Rooms, SR),
             DomainSize is QT * SR * NumSlots),
            DomainSizes),
    (DomainSizes = [] ->
        BF = 0.0
    ;
        sum_list(DomainSizes, Total),
        length(DomainSizes, Count),
        BF is Total / Count
    ).

count_qualified_teachers(SubjectID, Teachers, Count) :-
    findall(T, (member(teacher(T, _, _, _, _), Teachers), qualified(T, SubjectID)), QTs),
    length(QTs, Count).

count_suitable_rooms(SubjectID, Rooms, Count) :-
    findall(R, (member(room(R, _, _, _), Rooms), suitable_room(R, SubjectID)), SRs),
    length(SRs, Count).

% ============================================================================
% PART 3: SEARCH DEPTH
% ============================================================================

% ----------------------------------------------------------------------------
% calculate_search_depth/2: Maximum and average search depth
% ----------------------------------------------------------------------------
% The maximum depth equals the number of sessions (variables) to assign.
% Average depth is estimated from nodes explored and branching factor.
%
% @param _     - Unused
% @param Depth - Output dict with max_depth and avg_depth
%
calculate_search_depth(_, Depth) :-
    get_all_classes(Classes),
    findall(N,
            (member(class(_, _, SubjectList), Classes),
             length(SubjectList, N)),
            SessionCounts),
    sum_list(SessionCounts, MaxDepth),
    get_search_statistics(Stats),
    get_dict(nodes_explored, Stats, Nodes),
    get_dict(backtracks,     Stats, Backtracks),
    (Nodes > 0 ->
        AvgDepth is MaxDepth * (1.0 - (Backtracks / Nodes))
    ;
        AvgDepth is 0.0
    ),
    Depth = _{max_depth: MaxDepth, avg_depth: AvgDepth}.

% ============================================================================
% PART 4: CONSTRAINT DENSITY
% ============================================================================

% ----------------------------------------------------------------------------
% calculate_constraint_density/2: Constraints per variable ratio
% ----------------------------------------------------------------------------
% Constraint density = total_constraints / total_variables.
% Hard constraints: teacher conflict, room conflict, qualification,
%                   room type, capacity, availability = 6 per assignment.
%
% @param _       - Unused
% @param Density - Output dict with variables, constraints, density
%
calculate_constraint_density(_, Density) :-
    get_all_classes(Classes),
    findall(N,
            (member(class(_, _, SubjectList), Classes),
             length(SubjectList, N)),
            SessionCounts),
    sum_list(SessionCounts, NumVariables),
    % 6 hard constraints per variable (teacher conflict, room conflict,
    % qualification, room type, capacity, availability)
    HardConstraintsPerVar = 6,
    TotalConstraints is NumVariables * HardConstraintsPerVar,
    (NumVariables > 0 ->
        D is TotalConstraints / NumVariables
    ;
        D is 0.0
    ),
    Density = _{
        variables:   NumVariables,
        constraints: TotalConstraints,
        density:     D
    }.

% ============================================================================
% PART 5: TIME COMPLEXITY
% ============================================================================

% ----------------------------------------------------------------------------
% calculate_time_complexity/2: Actual vs theoretical complexity
% ----------------------------------------------------------------------------
% Theoretical worst-case: O(d^n) where d = branching factor, n = variables.
% Actual: measured from search statistics.
%
% @param _          - Unused
% @param Complexity - Output dict with theoretical and actual metrics
%
calculate_time_complexity(_, Complexity) :-
    calculate_branching_factor(_, BF),
    calculate_search_depth(_, DepthInfo),
    get_dict(max_depth, DepthInfo, N),
    get_search_statistics(Stats),
    get_dict(nodes_explored, Stats, ActualNodes),
    % Theoretical worst case: b^n (capped to avoid overflow)
    (N > 0, BF > 0 ->
        (N < 20 ->
            TheoreticalNodes is round(BF ** N)
        ;
            TheoreticalNodes = 9999999999
        )
    ;
        TheoreticalNodes = 0
    ),
    (TheoreticalNodes > 0 ->
        Efficiency is ActualNodes / TheoreticalNodes
    ;
        Efficiency = 0.0
    ),
    big_o_notation(BF, N, BigO),
    Complexity = _{
        theoretical_nodes: TheoreticalNodes,
        actual_nodes:      ActualNodes,
        efficiency:        Efficiency,
        big_o:             BigO,
        branching_factor:  BF,
        depth:             N
    }.

% big_o_notation(+BF, +N, -BigO)
% Generate a human-readable Big-O string
big_o_notation(BF, N, BigO) :-
    (BF =:= 0 ; N =:= 0) ->
        BigO = 'O(1)'
    ;
        format(atom(BigO), 'O(~1f^~w)', [BF, N]).

% ============================================================================
% PART 6: COMPLEXITY REPORT
% ============================================================================

% ----------------------------------------------------------------------------
% generate_complexity_report/2: Detailed analysis report as text
% ----------------------------------------------------------------------------
% @param _      - Unused
% @param Report - Output atom with formatted report text
%
generate_complexity_report(_, Report) :-
    analyze_solver_complexity(Metrics),
    get_dict(branching_factor,   Metrics, BF),
    get_dict(search_depth,       Metrics, DepthInfo),
    get_dict(constraint_density, Metrics, DensityInfo),
    get_dict(time_complexity,    Metrics, TimeInfo),
    get_dict(nodes_explored,     Metrics, Nodes),
    get_dict(backtracks,         Metrics, BT),
    get_dict(max_depth,          DepthInfo, MaxD),
    get_dict(avg_depth,          DepthInfo, AvgD),
    get_dict(variables,          DensityInfo, Vars),
    get_dict(constraints,        DensityInfo, Constrs),
    get_dict(density,            DensityInfo, Dens),
    get_dict(big_o,              TimeInfo, BigO),
    get_dict(actual_nodes,       TimeInfo, ActualN),
    get_dict(theoretical_nodes,  TimeInfo, TheoN),
    format(atom(Report),
        'AI Complexity Analysis Report\n\
==============================\n\
Variables (sessions): ~w\n\
Constraints: ~w (density: ~2f per variable)\n\
Branching Factor: ~2f\n\
Search Depth: max=~w, avg=~2f\n\
Big-O Complexity: ~w\n\
Theoretical nodes: ~w\n\
Actual nodes explored: ~w\n\
Backtracks: ~w\n',
        [Vars, Constrs, Dens, BF, MaxD, AvgD, BigO, TheoN, ActualN, BT]).

% ============================================================================
% END OF MODULE
% ============================================================================
