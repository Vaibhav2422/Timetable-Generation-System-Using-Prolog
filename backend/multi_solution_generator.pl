%% ============================================================================
%% multi_solution_generator.pl - Multiple Timetable Generation Module
%% ============================================================================
%% Generates multiple ranked timetable solutions by running the CSP solver
%% with randomised domain ordering, then ranks them by a combined quality
%% and reliability score.
%%
%% Requirements: (Feature 8 - Task 25)
%% ============================================================================

:- module(multi_solution_generator, [
    generate_top_timetables/2,
    generate_multiple_solutions/4,
    generate_solution_variant/3,
    rank_solutions_by_quality/2,
    score_solution/2,
    remove_duplicates/2,
    compare_timetables/3
]).

:- use_module(knowledge_base).
:- use_module(matrix_model).
:- use_module(constraints).
:- use_module(csp_solver).
:- use_module(timetable_generator).
:- use_module(probability_module).
%% Import quality_scorer but exclude count_gaps/2 which is already imported
%% from constraints (both modules define this predicate).
:- use_module(quality_scorer, [
    calculate_quality_score/2,
    hard_constraint_score/2,
    workload_balance_score/2,
    room_utilization_score/2,
    schedule_compactness_score/2,
    quality_breakdown/2,
    count_constraint_violations/3,
    calculate_balance_metric/2
]).
:- use_module(logging).

%% Multifile / dynamic declarations
:- multifile teacher/5, subject/5, room/4, timeslot/5, class/3.
:- dynamic   teacher/5, subject/5, room/4, timeslot/5, class/3.

%% Maximum number of solutions allowed
max_solutions(10).

%% ============================================================================
%% generate_top_timetables/2 - Generate N best timetables
%% ============================================================================
%% Format: generate_top_timetables(+N, -RankedSolutions)
%%
%% Generates up to N distinct timetable solutions and returns them ranked
%% by combined quality + reliability score (highest first).
%% N is capped at max_solutions/1 (10).
%%
%% @param N               Number of solutions requested (1-10)
%% @param RankedSolutions List of solution dicts sorted by score descending
%%
generate_top_timetables(N, RankedSolutions) :-
    max_solutions(MaxN),
    ActualN is min(N, MaxN),
    log_info('Starting multiple timetable generation'),
    format(atom(Msg), 'Generating up to ~w solutions', [ActualN]),
    log_info(Msg),
    retrieve_resources(Teachers, Subjects, Rooms, Slots, Classes),
    validate_resources(Teachers, Subjects, Rooms, Slots, Classes),
    create_sessions(Classes, Subjects, Sessions),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    generate_multiple_solutions(Sessions, EmptyMatrix, ActualN, Solutions),
    remove_duplicates(Solutions, UniqueSolutions),
    rank_solutions_by_quality(UniqueSolutions, RankedSolutions),
    length(RankedSolutions, Found),
    format(atom(DoneMsg), 'Generated ~w unique solutions', [Found]),
    log_info(DoneMsg).

%% ============================================================================
%% generate_multiple_solutions/4 - Generate solution variants
%% ============================================================================
%% Format: generate_multiple_solutions(+Sessions, +EmptyMatrix, +N, -Solutions)
%%
%% Attempts to generate N timetable solutions by repeatedly calling
%% generate_solution_variant/3 with different random seeds.
%%
%% @param Sessions     List of session(ClassID, SubjectID) to schedule
%% @param EmptyMatrix  Initial empty timetable matrix
%% @param N            Number of solutions to attempt
%% @param Solutions    List of generated timetable matrices
%%
generate_multiple_solutions(_, _, 0, []) :- !.
generate_multiple_solutions(Sessions, EmptyMatrix, N, Solutions) :-
    N > 0,
    N1 is N - 1,
    (   catch(
            generate_solution_variant(Sessions, EmptyMatrix, Timetable),
            _,
            fail
        )
    ->  generate_multiple_solutions(Sessions, EmptyMatrix, N1, Rest),
        Solutions = [Timetable | Rest]
    ;   generate_multiple_solutions(Sessions, EmptyMatrix, N1, Solutions)
    ).

%% ============================================================================
%% generate_solution_variant/3 - Randomised single solution
%% ============================================================================
%% Format: generate_solution_variant(+Sessions, +EmptyMatrix, -Timetable)
%%
%% Generates one timetable solution by shuffling the session list before
%% passing it to the CSP solver, producing a different search path each time.
%%
%% @param Sessions    List of session(ClassID, SubjectID)
%% @param EmptyMatrix Initial empty timetable matrix
%% @param Timetable   Output timetable matrix
%%
generate_solution_variant(Sessions, EmptyMatrix, Timetable) :-
    random_permutation(Sessions, ShuffledSessions),
    solve_csp(ShuffledSessions, EmptyMatrix, Timetable).

%% ============================================================================
%% rank_solutions_by_quality/2 - Sort solutions by combined score
%% ============================================================================
%% Format: rank_solutions_by_quality(+Solutions, -RankedSolutions)
%%
%% Scores each solution and returns them sorted highest-score first.
%% Each element of RankedSolutions is a dict:
%%   { timetable, quality_score, reliability, combined_score }
%%
%% @param Solutions       List of timetable matrices
%% @param RankedSolutions Sorted list of scored solution dicts
%%
rank_solutions_by_quality(Solutions, RankedSolutions) :-
    findall(Score-SolutionDict,
            (member(Timetable, Solutions),
             score_solution(Timetable, SolutionDict),
             get_dict(combined_score, SolutionDict, Score)),
            Pairs),
    sort(1, @>=, Pairs, SortedPairs),
    pairs_values(SortedPairs, RankedSolutions).

%% ============================================================================
%% score_solution/2 - Combined quality + reliability score
%% ============================================================================
%% Format: score_solution(+Timetable, -SolutionDict)
%%
%% Computes a combined score = 0.6 * quality_score + 0.4 * reliability.
%% Both inputs are normalised to [0, 1] before combining.
%%
%% @param Timetable    A timetable matrix
%% @param SolutionDict Dict: { timetable, quality_score, reliability, combined_score }
%%
score_solution(Timetable, SolutionDict) :-
    calculate_quality_score(Timetable, QualityInt),
    QualityNorm is QualityInt / 100.0,
    schedule_reliability(Timetable, Reliability),
    CombinedScore is 0.6 * QualityNorm + 0.4 * Reliability,
    SolutionDict = _{
        timetable:      Timetable,
        quality_score:  QualityInt,
        reliability:    Reliability,
        combined_score: CombinedScore
    }.

%% ============================================================================
%% remove_duplicates/2 - Eliminate equivalent timetables
%% ============================================================================
%% Format: remove_duplicates(+Solutions, -UniqueSolutions)
%%
%% Two timetables are considered equivalent when their assignment sets are
%% identical (same class, subject, teacher, room, slot for every entry).
%%
%% @param Solutions       List of timetable matrices (may contain duplicates)
%% @param UniqueSolutions List with duplicates removed
%%
remove_duplicates([], []).
remove_duplicates([H|T], [H|Unique]) :-
    exclude(timetable_equal(H), T, Filtered),
    remove_duplicates(Filtered, Unique).

%% timetable_equal(+T1, +T2)
%% Succeeds when T1 and T2 have identical assignment sets.
timetable_equal(T1, T2) :-
    get_all_assignments(T1, A1),
    get_all_assignments(T2, A2),
    msort(A1, Sorted),
    msort(A2, Sorted).

%% ============================================================================
%% compare_timetables/3 - Detailed comparison of two timetables
%% ============================================================================
%% Format: compare_timetables(+Timetable1, +Timetable2, -Comparison)
%%
%% Returns a dict describing the differences between two timetables:
%%   { added, removed, changed, quality_delta, reliability_delta }
%%
%% @param Timetable1  First timetable matrix (baseline)
%% @param Timetable2  Second timetable matrix (comparison)
%% @param Comparison  Dict with diff information
%%
compare_timetables(Timetable1, Timetable2, Comparison) :-
    get_all_assignments(Timetable1, A1),
    get_all_assignments(Timetable2, A2),
    % Assignments in T2 but not T1 (added)
    findall(A, (member(A, A2), \+ member(A, A1)), Added),
    % Assignments in T1 but not T2 (removed)
    findall(A, (member(A, A1), \+ member(A, A2)), Removed),
    length(Added,   NumAdded),
    length(Removed, NumRemoved),
    % Quality and reliability deltas
    calculate_quality_score(Timetable1, Q1),
    calculate_quality_score(Timetable2, Q2),
    schedule_reliability(Timetable1, R1),
    schedule_reliability(Timetable2, R2),
    QDelta is Q2 - Q1,
    RDelta is R2 - R1,
    Comparison = _{
        added:             Added,
        removed:           Removed,
        added_count:       NumAdded,
        removed_count:     NumRemoved,
        quality_delta:     QDelta,
        reliability_delta: RDelta
    }.

%% ============================================================================
%% Helper: pairs_values/2
%% ============================================================================
pairs_values([], []).
pairs_values([_-V|T], [V|Vs]) :-
    pairs_values(T, Vs).

%% ============================================================================
%% End of multi_solution_generator.pl
%% ============================================================================
