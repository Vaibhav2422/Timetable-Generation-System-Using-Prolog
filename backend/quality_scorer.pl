%% ============================================================================
%% quality_scorer.pl - Timetable Quality Scoring Module
%% ============================================================================
%% Calculates a comprehensive 0-100 quality score for generated timetables.
%% The score is composed of four weighted metrics:
%%   - Hard constraint satisfaction (40%)
%%   - Teacher workload balance     (25%)
%%   - Room utilization efficiency  (20%)
%%   - Schedule compactness         (15%)
%%
%% Requirements: 5.1, 5.2, 5.3, 5.5, 5.6, 21.1-21.5
%% ============================================================================

:- module(quality_scorer, [
    calculate_quality_score/2,
    hard_constraint_score/2,
    workload_balance_score/2,
    room_utilization_score/2,
    schedule_compactness_score/2,
    quality_breakdown/2,
    count_constraint_violations/3,
    calculate_balance_metric/2,
    count_gaps/2
]).

:- use_module(knowledge_base).
:- use_module(matrix_model).
:- use_module(constraints).
:- use_module(logging).

%% Multifile / dynamic declarations so we can read facts from user module
:- multifile teacher/5, subject/5, room/4, timeslot/5, class/3.
:- dynamic   teacher/5, subject/5, room/4, timeslot/5, class/3.

%% Scoring weights (must sum to 1.0)
:- discontiguous calculate_quality_score/2.

weight(hard_constraints,    0.40).
weight(workload_balance,    0.25).
weight(room_utilization,    0.20).
weight(schedule_compactness, 0.15).

%% ============================================================================
%% calculate_quality_score/2 - Comprehensive 0-100 score
%% ============================================================================
%% Format: calculate_quality_score(+Matrix, -Score)
%%
%% Combines all four sub-scores into a single 0-100 quality score.
%%
%% @param Matrix  The timetable matrix to evaluate
%% @param Score   Output score in range [0, 100]
%%
calculate_quality_score(Matrix, Score) :-
    hard_constraint_score(Matrix, HardScore),
    workload_balance_score(Matrix, WorkloadScore),
    room_utilization_score(Matrix, RoomScore),
    schedule_compactness_score(Matrix, CompactnessScore),
    weight(hard_constraints,    W1),
    weight(workload_balance,    W2),
    weight(room_utilization,    W3),
    weight(schedule_compactness, W4),
    RawScore is (HardScore * W1 + WorkloadScore * W2 + RoomScore * W3 + CompactnessScore * W4),
    Score is round(RawScore * 100).

%% ============================================================================
%% hard_constraint_score/2 - Constraint satisfaction score (0.0-1.0)
%% ============================================================================
%% Format: hard_constraint_score(+Matrix, -Score)
%%
%% Returns 1.0 when there are zero violations, decreasing linearly as
%% violations increase relative to the total number of assignments.
%%
%% @param Matrix  The timetable matrix
%% @param Score   Normalised score in [0.0, 1.0]
%%
hard_constraint_score(Matrix, Score) :-
    get_all_assignments(Matrix, Assignments),
    length(Assignments, Total),
    (Total =:= 0 ->
        Score = 1.0
    ;
        count_constraint_violations(Matrix, Assignments, Violations),
        Score is max(0.0, 1.0 - (Violations / Total))
    ).

%% count_constraint_violations/3
%% Format: count_constraint_violations(+Matrix, +Assignments, -Count)
%%
%% Counts the number of hard-constraint violations across all assignments.
%%
count_constraint_violations(Matrix, Assignments, Count) :-
    findall(1, (
        member(assigned(RoomID, ClassID, SubjectID, TeacherID, SlotID), Assignments),
        \+ check_all_hard_constraints(RoomID, ClassID, SubjectID, TeacherID, SlotID, Matrix)
    ), Violations),
    length(Violations, Count).

%% ============================================================================
%% workload_balance_score/2 - Teacher workload balance (0.0-1.0)
%% ============================================================================
%% Format: workload_balance_score(+Matrix, -Score)
%%
%% Measures how evenly sessions are distributed across teachers.
%% A perfectly balanced workload scores 1.0; high variance scores lower.
%%
%% @param Matrix  The timetable matrix
%% @param Score   Normalised score in [0.0, 1.0]
%%
workload_balance_score(Matrix, Score) :-
    get_all_assignments(Matrix, Assignments),
    get_all_teachers(Teachers),
    (Teachers = [] ->
        Score = 1.0
    ;
        findall(Hours,
                (member(teacher(TID, _, _, _, _), Teachers),
                 count_teacher_sessions(TID, Assignments, Hours)),
                WorkloadList),
        calculate_balance_metric(WorkloadList, Score)
    ).

%% count_teacher_sessions/3
%% Format: count_teacher_sessions(+TeacherID, +Assignments, -Count)
count_teacher_sessions(TeacherID, Assignments, Count) :-
    findall(1, member(assigned(_, _, _, TeacherID, _), Assignments), Hits),
    length(Hits, Count).

%% calculate_balance_metric/2
%% Format: calculate_balance_metric(+Values, -Score)
%%
%% Converts a list of numeric values into a balance score using
%% coefficient of variation (lower CV = higher score).
%%
calculate_balance_metric([], 1.0) :- !.
calculate_balance_metric(Values, Score) :-
    length(Values, N),
    N > 0,
    sum_list(Values, Sum),
    Mean is Sum / N,
    (Mean =:= 0 ->
        Score = 1.0
    ;
        findall(D, (member(V, Values), D is (V - Mean) * (V - Mean)), Diffs),
        sum_list(Diffs, SumDiffs),
        Variance is SumDiffs / N,
        StdDev is sqrt(Variance),
        CV is StdDev / Mean,
        Score is max(0.0, 1.0 - min(1.0, CV))
    ).

%% ============================================================================
%% room_utilization_score/2 - Room efficiency score (0.0-1.0)
%% ============================================================================
%% Format: room_utilization_score(+Matrix, -Score)
%%
%% Measures how efficiently rooms are used.  A room that is used for every
%% available slot scores 1.0; unused rooms lower the score.
%%
%% @param Matrix  The timetable matrix
%% @param Score   Normalised score in [0.0, 1.0]
%%
room_utilization_score(Matrix, Score) :-
    get_all_rooms(Rooms),
    get_all_timeslots(Slots),
    length(Rooms, NumRooms),
    length(Slots, NumSlots),
    TotalCapacity is NumRooms * NumSlots,
    (TotalCapacity =:= 0 ->
        Score = 1.0
    ;
        get_all_assignments(Matrix, Assignments),
        length(Assignments, Used),
        Score is min(1.0, Used / TotalCapacity)
    ).

%% ============================================================================
%% schedule_compactness_score/2 - Minimize gaps (0.0-1.0)
%% ============================================================================
%% Format: schedule_compactness_score(+Matrix, -Score)
%%
%% Measures how compact each class's daily schedule is.
%% Fewer gaps between sessions = higher score.
%%
%% @param Matrix  The timetable matrix
%% @param Score   Normalised score in [0.0, 1.0]
%%
schedule_compactness_score(Matrix, Score) :-
    get_all_assignments(Matrix, Assignments),
    get_all_classes(Classes),
    (Classes = [] ->
        Score = 1.0
    ;
        findall(ClassScore,
                (member(class(CID, _, _), Classes),
                 class_compactness(CID, Assignments, ClassScore)),
                ClassScores),
        (ClassScores = [] ->
            Score = 1.0
        ;
            sum_list(ClassScores, Sum),
            length(ClassScores, Len),
            Score is Sum / Len
        )
    ).

%% class_compactness/3
%% Format: class_compactness(+ClassID, +Assignments, -Score)
%%
%% Computes a compactness score for a single class.
%%
class_compactness(ClassID, Assignments, Score) :-
    findall(SlotID,
            member(assigned(_, ClassID, _, _, SlotID), Assignments),
            SlotIDs),
    (SlotIDs = [] ->
        Score = 1.0
    ;
        count_gaps(SlotIDs, GapCount),
        length(SlotIDs, NumSessions),
        Score is max(0.0, 1.0 - (GapCount / (NumSessions + GapCount + 1)))
    ).

%% count_gaps/2
%% Format: count_gaps(+SlotIDs, -GapCount)
%%
%% Counts the total number of empty periods between scheduled sessions
%% across all days.
%%
count_gaps(SlotIDs, GapCount) :-
    findall(Day,
            (member(S, SlotIDs),
             (timeslot(S, Day, _, _, _) ; user:timeslot(S, Day, _, _, _))),
            Days),
    sort(Days, UniqueDays),
    findall(Gaps,
            (member(Day, UniqueDays),
             count_day_gaps(Day, SlotIDs, Gaps)),
            GapsList),
    sum_list(GapsList, GapCount).

%% count_day_gaps/3
%% Format: count_day_gaps(+Day, +SlotIDs, -Gaps)
count_day_gaps(Day, SlotIDs, Gaps) :-
    findall(Period,
            (member(S, SlotIDs),
             (timeslot(S, Day, Period, _, _) ; user:timeslot(S, Day, Period, _, _))),
            Periods),
    (Periods = [] ->
        Gaps = 0
    ;
        sort(Periods, Sorted),
        min_list(Sorted, MinP),
        max_list(Sorted, MaxP),
        Range is MaxP - MinP + 1,
        length(Sorted, NumP),
        Gaps is Range - NumP
    ).

%% ============================================================================
%% quality_breakdown/2 - Detailed score breakdown
%% ============================================================================
%% Format: quality_breakdown(+Matrix, -Breakdown)
%%
%% Returns a dict with individual sub-scores and the overall score.
%%
%% @param Matrix     The timetable matrix
%% @param Breakdown  Dict: {overall, hard_constraints, workload_balance,
%%                          room_utilization, schedule_compactness}
%%
quality_breakdown(Matrix, Breakdown) :-
    hard_constraint_score(Matrix, HardScore),
    workload_balance_score(Matrix, WorkloadScore),
    room_utilization_score(Matrix, RoomScore),
    schedule_compactness_score(Matrix, CompactnessScore),
    calculate_quality_score(Matrix, Overall),
    HardPct      is round(HardScore      * 100),
    WorkloadPct  is round(WorkloadScore  * 100),
    RoomPct      is round(RoomScore      * 100),
    CompactPct   is round(CompactnessScore * 100),
    Breakdown = _{
        overall:              Overall,
        hard_constraints:     HardPct,
        workload_balance:     WorkloadPct,
        room_utilization:     RoomPct,
        schedule_compactness: CompactPct
    }.

%% ============================================================================
%% End of quality_scorer.pl
%% ============================================================================
