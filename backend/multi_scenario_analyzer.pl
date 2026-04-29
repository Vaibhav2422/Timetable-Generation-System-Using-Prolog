% ============================================================================
% multi_scenario_analyzer.pl - What-If Optimization Dashboard Module
% ============================================================================
% This module implements multi-scenario analysis for the What-If Optimization
% Dashboard (Feature 15). It runs multiple scenarios in parallel (sequentially
% in Prolog), compares them via a comparison matrix, ranks them by quality and
% reliability, and recommends the best scenario using AI-based metrics.
%
% Supported predicates:
%   analyze_multiple_scenarios/2   - Run multiple scenarios and collect metrics
%   scenario_comparison_matrix/2   - Build a comparison matrix for all scenarios
%   rank_scenarios_by_quality/2    - Sort scenarios by combined quality+reliability
%   calculate_scenario_metrics/2   - Compute quality, reliability, resource usage
%   recommend_best_scenario/2      - AI recommendation based on metrics
%
% Requirements: Feature 15 (Task 28E)
%
% Author: AI Timetable Generation System
% ============================================================================

:- module(multi_scenario_analyzer, [
    analyze_multiple_scenarios/2,
    scenario_comparison_matrix/2,
    rank_scenarios_by_quality/2,
    calculate_scenario_metrics/2,
    recommend_best_scenario/2
]).

:- use_module(scenario_simulator).
:- use_module(quality_scorer).
:- use_module(probability_module).
:- use_module(matrix_model).
:- use_module(knowledge_base).
:- use_module(logging).

:- multifile teacher/5, subject/5, room/4, timeslot/5, class/3.
:- dynamic   teacher/5, subject/5, room/4, timeslot/5, class/3.

% ============================================================================
% analyze_multiple_scenarios/2
% ============================================================================
% Run multiple scenarios and collect metrics for each.
%
% Format: analyze_multiple_scenarios(+ScenarioList, -Results)
%
% ScenarioList: list of dicts, each with at least a 'scenario' key
%   e.g. [ _{scenario: teacher_absence, teacher_id: t1},
%           _{scenario: room_maintenance, room_id: r2} ]
%
% Results: list of scenario result dicts, each containing:
%   scenario, timetable, reliability, changes, metrics, name
%
% ============================================================================

analyze_multiple_scenarios(ScenarioList, Results) :-
    log_info('Starting multi-scenario analysis'),
    length(ScenarioList, Count),
    format(atom(Msg), 'Analyzing ~w scenarios', [Count]),
    log_info(Msg),
    analyze_scenarios_list(ScenarioList, 1, Results),
    log_info('Multi-scenario analysis complete').

%% analyze_scenarios_list(+Scenarios, +Index, -Results)
analyze_scenarios_list([], _, []).
analyze_scenarios_list([ScenarioParams|Rest], Index, [Result|RestResults]) :-
    get_dict(scenario, ScenarioParams, ScenarioType),
    format(atom(LogMsg), 'Running scenario ~w: ~w', [Index, ScenarioType]),
    log_info(LogMsg),
    % Run the scenario simulation
    (   catch(simulate_scenario(ScenarioType, ScenarioParams, SimResult), _, fail)
    ->  get_dict(timetable, SimResult, Timetable),
        get_dict(reliability, SimResult, Reliability),
        get_dict(changes, SimResult, Changes),
        % Calculate quality metrics
        calculate_scenario_metrics(Timetable, Metrics),
        % Build scenario name
        build_scenario_name(ScenarioType, ScenarioParams, Index, Name),
        Result = _{
            index:       Index,
            name:        Name,
            scenario:    ScenarioType,
            params:      ScenarioParams,
            timetable:   Timetable,
            reliability: Reliability,
            changes:     Changes,
            metrics:     Metrics
        }
    ;   % Simulation failed – record an error result
        build_scenario_name(ScenarioType, ScenarioParams, Index, Name),
        Result = _{
            index:       Index,
            name:        Name,
            scenario:    ScenarioType,
            params:      ScenarioParams,
            timetable:   [],
            reliability: 0.0,
            changes:     [],
            metrics:     _{quality: 0, reliability: 0.0, resource_usage: 0.0,
                           hard_constraints: 0, workload_balance: 0,
                           room_utilization: 0, schedule_compactness: 0}
        }
    ),
    NextIndex is Index + 1,
    analyze_scenarios_list(Rest, NextIndex, RestResults).

%% build_scenario_name(+Type, +Params, +Index, -Name)
build_scenario_name(teacher_absence, Params, _, Name) :-
    (get_dict(teacher_id, Params, TID) ->
        format(atom(Name), 'Teacher Absence (~w)', [TID])
    ;
        Name = 'Teacher Absence'
    ).
build_scenario_name(room_maintenance, Params, _, Name) :-
    (get_dict(room_id, Params, RID) ->
        format(atom(Name), 'Room Maintenance (~w)', [RID])
    ;
        Name = 'Room Maintenance'
    ).
build_scenario_name(extra_class, Params, _, Name) :-
    (get_dict(class_id, Params, CID) ->
        format(atom(Name), 'Extra Class (~w)', [CID])
    ;
        Name = 'Extra Class'
    ).
build_scenario_name(exam_week, _, _, 'Exam Week').
build_scenario_name(baseline, _, _, 'Baseline (Current)').
build_scenario_name(Unknown, _, Index, Name) :-
    format(atom(Name), 'Scenario ~w (~w)', [Index, Unknown]).

% ============================================================================
% calculate_scenario_metrics/2
% ============================================================================
% Compute quality, reliability, and resource usage metrics for a timetable.
%
% Format: calculate_scenario_metrics(+Timetable, -Metrics)
%
% Metrics dict:
%   quality            - overall quality score (0-100)
%   reliability        - reliability score (0.0-1.0)
%   resource_usage     - fraction of slots used (0.0-1.0)
%   hard_constraints   - hard constraint satisfaction score (0-100)
%   workload_balance   - workload balance score (0-100)
%   room_utilization   - room utilization score (0-100)
%   schedule_compactness - schedule compactness score (0-100)
%
% ============================================================================

calculate_scenario_metrics(Timetable, Metrics) :-
    % Quality breakdown
    (   catch(quality_breakdown(Timetable, Breakdown), _, fail)
    ->  get_dict(overall,              Breakdown, Quality),
        get_dict(hard_constraints,     Breakdown, HardScore),
        get_dict(workload_balance,     Breakdown, WorkloadScore),
        get_dict(room_utilization,     Breakdown, RoomScore),
        get_dict(schedule_compactness, Breakdown, CompactnessScore)
    ;   Quality = 0,
        HardScore = 0,
        WorkloadScore = 0,
        RoomScore = 0,
        CompactnessScore = 0
    ),
    % Reliability
    (   catch(schedule_reliability(Timetable, Reliability), _, fail)
    ->  true
    ;   Reliability = 0.0
    ),
    % Resource usage: fraction of total slots that are assigned
    (   catch(calculate_resource_usage(Timetable, ResourceUsage), _, fail)
    ->  true
    ;   ResourceUsage = 0.0
    ),
    Metrics = _{
        quality:              Quality,
        reliability:          Reliability,
        resource_usage:       ResourceUsage,
        hard_constraints:     HardScore,
        workload_balance:     WorkloadScore,
        room_utilization:     RoomScore,
        schedule_compactness: CompactnessScore
    }.

%% calculate_resource_usage(+Timetable, -Usage)
%% Fraction of room×slot cells that are occupied.
calculate_resource_usage(Timetable, Usage) :-
    get_all_rooms(Rooms),
    get_all_timeslots(Slots),
    length(Rooms, NumRooms),
    length(Slots, NumSlots),
    TotalCells is NumRooms * NumSlots,
    (TotalCells =:= 0 ->
        Usage = 0.0
    ;
        get_all_assignments(Timetable, Assignments),
        length(Assignments, Used),
        Usage is Used / TotalCells
    ).

% ============================================================================
% scenario_comparison_matrix/2
% ============================================================================
% Build a comparison matrix from a list of analyzed scenario results.
%
% Format: scenario_comparison_matrix(+Results, -Matrix)
%
% Matrix: list of comparison rows, each containing:
%   name, quality, reliability, resource_usage, changes_count,
%   hard_constraints, workload_balance, room_utilization, schedule_compactness
%
% ============================================================================

scenario_comparison_matrix(Results, Matrix) :-
    log_info('Building scenario comparison matrix'),
    maplist(result_to_matrix_row, Results, Matrix).

%% result_to_matrix_row(+Result, -Row)
result_to_matrix_row(Result, Row) :-
    get_dict(name,        Result, Name),
    get_dict(scenario,    Result, Scenario),
    get_dict(reliability, Result, Reliability),
    get_dict(changes,     Result, Changes),
    get_dict(metrics,     Result, Metrics),
    length(Changes, ChangesCount),
    get_dict(quality,              Metrics, Quality),
    get_dict(resource_usage,       Metrics, ResourceUsage),
    get_dict(hard_constraints,     Metrics, HardScore),
    get_dict(workload_balance,     Metrics, WorkloadScore),
    get_dict(room_utilization,     Metrics, RoomScore),
    get_dict(schedule_compactness, Metrics, CompactnessScore),
    ReliabilityPct is round(Reliability * 100),
    ResourcePct    is round(ResourceUsage * 100),
    Row = _{
        name:                 Name,
        scenario:             Scenario,
        quality:              Quality,
        reliability:          Reliability,
        reliability_pct:      ReliabilityPct,
        resource_usage:       ResourceUsage,
        resource_usage_pct:   ResourcePct,
        changes_count:        ChangesCount,
        hard_constraints:     HardScore,
        workload_balance:     WorkloadScore,
        room_utilization:     RoomScore,
        schedule_compactness: CompactnessScore
    }.

% ============================================================================
% rank_scenarios_by_quality/2
% ============================================================================
% Rank scenario results by a combined quality + reliability score.
%
% Format: rank_scenarios_by_quality(+Results, -RankedResults)
%
% The combined score is: 0.6 * quality_normalised + 0.4 * reliability
% where quality_normalised = quality / 100.
%
% ============================================================================

rank_scenarios_by_quality(Results, RankedResults) :-
    log_info('Ranking scenarios by quality'),
    % Compute combined score for each result
    maplist(add_combined_score, Results, ScoredResults),
    % Sort descending by combined score
    sort_by_combined_score(ScoredResults, RankedResults).

%% add_combined_score(+Result, -ScoredResult)
add_combined_score(Result, ScoredResult) :-
    get_dict(metrics,     Result, Metrics),
    get_dict(reliability, Result, Reliability),
    get_dict(quality, Metrics, Quality),
    QualityNorm is Quality / 100.0,
    CombinedScore is 0.6 * QualityNorm + 0.4 * Reliability,
    put_dict(combined_score, Result, CombinedScore, ScoredResult).

%% sort_by_combined_score(+List, -Sorted)
%% Sort descending by combined_score.
sort_by_combined_score(List, Sorted) :-
    maplist([R, Score-R]>>(get_dict(combined_score, R, Score)), List, Pairs),
    sort(1, @>=, Pairs, SortedPairs),
    pairs_values(SortedPairs, Sorted).

% ============================================================================
% recommend_best_scenario/2
% ============================================================================
% Produce an AI recommendation for the best scenario based on metrics.
%
% Format: recommend_best_scenario(+RankedResults, -Recommendation)
%
% Recommendation dict:
%   recommended_index  - index of the recommended scenario
%   recommended_name   - name of the recommended scenario
%   combined_score     - combined quality+reliability score
%   reason             - human-readable explanation
%   trade_offs         - list of trade-off observations
%
% ============================================================================

recommend_best_scenario([], Recommendation) :-
    Recommendation = _{
        recommended_index: -1,
        recommended_name:  'None',
        combined_score:    0.0,
        reason:            'No scenarios were provided for analysis.',
        trade_offs:        []
    }.

recommend_best_scenario([Best|Rest], Recommendation) :-
    % Best is already the top-ranked scenario (first in ranked list)
    get_dict(index,          Best, BestIndex),
    get_dict(name,           Best, BestName),
    get_dict(combined_score, Best, BestScore),
    get_dict(metrics,        Best, BestMetrics),
    get_dict(reliability,    Best, BestReliability),
    get_dict(quality,        BestMetrics, BestQuality),
    % Build reason text
    format(atom(Reason),
           'Scenario "~w" achieves the highest combined score (~2f) with quality ~w/100 and reliability ~1f%. It best balances constraint satisfaction, workload distribution, and schedule reliability.',
           [BestName, BestScore, BestQuality, BestReliability * 100]),
    % Identify trade-offs by comparing with other scenarios
    collect_trade_offs(Best, Rest, TradeOffs),
    Recommendation = _{
        recommended_index: BestIndex,
        recommended_name:  BestName,
        combined_score:    BestScore,
        reason:            Reason,
        trade_offs:        TradeOffs
    }.

%% collect_trade_offs(+Best, +Others, -TradeOffs)
collect_trade_offs(_, [], []).
collect_trade_offs(Best, [Other|Rest], [TradeOff|RestTradeOffs]) :-
    get_dict(name,           Best,  BestName),
    get_dict(name,           Other, OtherName),
    get_dict(combined_score, Best,  BestScore),
    get_dict(combined_score, Other, OtherScore),
    get_dict(metrics,        Best,  BestMetrics),
    get_dict(metrics,        Other, OtherMetrics),
    get_dict(reliability,    Best,  BestRel),
    get_dict(reliability,    Other, OtherRel),
    get_dict(quality,        BestMetrics,  BestQ),
    get_dict(quality,        OtherMetrics, OtherQ),
    ScoreDiff is BestScore - OtherScore,
    QDiff     is BestQ - OtherQ,
    RelDiff   is (BestRel - OtherRel) * 100,
    format(atom(TradeOff),
           '"~w" scores ~2f lower than "~w" (quality diff: ~w, reliability diff: ~1f%)',
           [OtherName, ScoreDiff, BestName, QDiff, RelDiff]),
    collect_trade_offs(Best, Rest, RestTradeOffs).
collect_trade_offs(Best, [_|Rest], TradeOffs) :-
    collect_trade_offs(Best, Rest, TradeOffs).

% ============================================================================
% END OF MODULE
% ============================================================================
