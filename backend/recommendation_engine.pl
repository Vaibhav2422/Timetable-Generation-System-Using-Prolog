%% ============================================================================
%% recommendation_engine.pl - AI Recommendation Engine
%% ============================================================================
%% Analyses a generated timetable and produces prioritised, actionable
%% recommendations for improving schedule quality.
%%
%% Analysis categories:
%%   1. Workload imbalance  – teachers with significantly more/fewer sessions
%%   2. Room underutilisation – rooms that are rarely used
%%   3. Schedule gaps        – classes with large gaps between sessions
%%   4. Late theory classes  – theory sessions scheduled in late periods
%%
%% Each recommendation is returned as a dict-like term:
%%   recommendation(Priority, Category, Description, ActionData)
%%
%% Requirements: Feature 5 (Task 22)
%% ============================================================================

:- module(recommendation_engine, [
    generate_recommendations/2,
    analyze_workload_imbalance/2,
    analyze_room_underutilization/2,
    analyze_schedule_gaps/2,
    analyze_late_theory_classes/2,
    format_recommendation/2,
    apply_recommendation/2
]).

:- use_module(knowledge_base).
:- use_module(matrix_model).
:- use_module(constraints).
:- use_module(logging).

:- multifile teacher/5, subject/5, room/4, timeslot/5, class/3.
:- dynamic   teacher/5, subject/5, room/4, timeslot/5, class/3.

%% Thresholds
workload_imbalance_threshold(1.5).   % ratio of max/min sessions to flag imbalance
room_underutilization_threshold(0.2). % rooms used < 20 % of slots are flagged
gap_threshold(2).                     % more than 2 gaps per day is flagged
late_period_threshold(6).             % periods > 6 are considered "late"

%% ============================================================================
%% generate_recommendations/2
%% ============================================================================
%% Format: generate_recommendations(+Matrix, -Recommendations)
%%
%% Runs all four analyses, collects the resulting recommendations, sorts them
%% by priority (1 = highest), and returns the list.
%%
generate_recommendations(Matrix, Recommendations) :-
    log_info('Generating AI recommendations'),
    analyze_workload_imbalance(Matrix, WorkloadRecs),
    analyze_room_underutilization(Matrix, RoomRecs),
    analyze_schedule_gaps(Matrix, GapRecs),
    analyze_late_theory_classes(Matrix, LateRecs),
    append([WorkloadRecs, RoomRecs, GapRecs, LateRecs], AllRecs),
    sort(AllRecs, Recommendations),
    length(Recommendations, N),
    format(atom(Msg), 'Generated ~w recommendations', [N]),
    log_info(Msg).

%% ============================================================================
%% analyze_workload_imbalance/2
%% ============================================================================
%% Format: analyze_workload_imbalance(+Matrix, -Recommendations)
%%
%% Detects teachers whose session count deviates significantly from the mean.
%%
analyze_workload_imbalance(Matrix, Recommendations) :-
    get_all_assignments(Matrix, Assignments),
    get_all_teachers(Teachers),
    Teachers \= [],
    findall(TID-Count,
            (member(teacher(TID, _, _, _, _), Teachers),
             findall(1, member(assigned(_, _, _, TID, _), Assignments), Hits),
             length(Hits, Count)),
            Pairs),
    pairs_values(Pairs, Counts),
    sum_list(Counts, Sum),
    length(Counts, N),
    N > 0,
    Mean is Sum / N,
    workload_imbalance_threshold(Threshold),
    findall(Rec,
            (member(TID-Count, Pairs),
             Count > 0,
             Ratio is Count / max(1, Mean),
             (Ratio > Threshold ->
                 format(atom(Desc),
                        'Teacher ~w has ~w sessions (~1f× average). Consider redistributing sessions.',
                        [TID, Count, Ratio]),
                 Rec = recommendation(1, workload_imbalance, Desc,
                                      action(redistribute_sessions, teacher_id-TID, session_count-Count))
             ; Mean > 0, Count =:= 0 ->
                 format(atom(Desc),
                        'Teacher ~w has no sessions assigned. Check qualifications or availability.',
                        [TID]),
                 Rec = recommendation(2, workload_imbalance, Desc,
                                      action(check_teacher, teacher_id-TID, session_count-0))
             ; fail
             )),
            Recommendations).

analyze_workload_imbalance(_, []).

%% ============================================================================
%% analyze_room_underutilization/2
%% ============================================================================
%% Format: analyze_room_underutilization(+Matrix, -Recommendations)
%%
%% Flags rooms whose utilisation falls below the configured threshold.
%%
analyze_room_underutilization(Matrix, Recommendations) :-
    get_all_assignments(Matrix, Assignments),
    get_all_rooms(Rooms),
    get_all_timeslots(Slots),
    length(Slots, TotalSlots),
    TotalSlots > 0,
    room_underutilization_threshold(Threshold),
    findall(Rec,
            (member(room(RID, RName, _, _), Rooms),
             findall(1, member(assigned(RID, _, _, _, _), Assignments), Hits),
             length(Hits, Used),
             Utilization is Used / TotalSlots,
             Utilization < Threshold,
             UsedPct is round(Utilization * 100),
             format(atom(Desc),
                    'Room ~w (~w) is only ~w% utilised (~w/~w slots). Consider removing or repurposing it.',
                    [RID, RName, UsedPct, Used, TotalSlots]),
             Rec = recommendation(2, room_underutilization, Desc,
                                  action(review_room, room_id-RID, utilization-Utilization))),
            Recommendations).

analyze_room_underutilization(_, []).

%% ============================================================================
%% analyze_schedule_gaps/2
%% ============================================================================
%% Format: analyze_schedule_gaps(+Matrix, -Recommendations)
%%
%% Detects classes that have excessive gaps between sessions on the same day.
%%
analyze_schedule_gaps(Matrix, Recommendations) :-
    get_all_assignments(Matrix, Assignments),
    get_all_classes(Classes),
    gap_threshold(GapThreshold),
    findall(Rec,
            (member(class(CID, CName, _), Classes),
             findall(SlotID, member(assigned(_, CID, _, _, SlotID), Assignments), SlotIDs),
             SlotIDs \= [],
             count_total_gaps(SlotIDs, TotalGaps),
             TotalGaps > GapThreshold,
             format(atom(Desc),
                    'Class ~w (~w) has ~w schedule gaps. Compacting the timetable would improve student experience.',
                    [CID, CName, TotalGaps]),
             Rec = recommendation(2, schedule_gaps, Desc,
                                  action(compact_schedule, class_id-CID, gap_count-TotalGaps))),
            Recommendations).

analyze_schedule_gaps(_, []).

%% count_total_gaps/2
%% Format: count_total_gaps(+SlotIDs, -TotalGaps)
count_total_gaps(SlotIDs, TotalGaps) :-
    findall(Day,
            (member(S, SlotIDs),
             (timeslot(S, Day, _, _, _) ; user:timeslot(S, Day, _, _, _))),
            Days),
    sort(Days, UniqueDays),
    findall(Gaps,
            (member(Day, UniqueDays),
             findall(Period,
                     (member(S, SlotIDs),
                      (timeslot(S, Day, Period, _, _) ; user:timeslot(S, Day, Period, _, _))),
                     Periods),
             sort(Periods, Sorted),
             (Sorted = [] -> Gaps = 0
             ;
                 min_list(Sorted, MinP),
                 max_list(Sorted, MaxP),
                 Range is MaxP - MinP + 1,
                 length(Sorted, NumP),
                 Gaps is Range - NumP
             )),
            GapsList),
    sum_list(GapsList, TotalGaps).

%% ============================================================================
%% analyze_late_theory_classes/2
%% ============================================================================
%% Format: analyze_late_theory_classes(+Matrix, -Recommendations)
%%
%% Detects theory sessions scheduled in late periods (period > threshold).
%%
analyze_late_theory_classes(Matrix, Recommendations) :-
    get_all_assignments(Matrix, Assignments),
    late_period_threshold(LatePeriod),
    findall(Rec,
            (member(assigned(_, ClassID, SubjectID, TeacherID, SlotID), Assignments),
             (subject(SubjectID, _, _, theory, _) ; user:subject(SubjectID, _, _, theory, _)),
             (timeslot(SlotID, Day, Period, _, _) ; user:timeslot(SlotID, Day, Period, _, _)),
             Period > LatePeriod,
             format(atom(Desc),
                    'Theory session ~w for class ~w is scheduled late (Period ~w on ~w). Move to an earlier slot for better engagement.',
                    [SubjectID, ClassID, Period, Day]),
             Rec = recommendation(3, late_theory, Desc,
                                  action(move_to_earlier_slot,
                                         class_id-ClassID,
                                         subject_id-SubjectID,
                                         teacher_id-TeacherID,
                                         slot_id-SlotID))),
            Recommendations).

analyze_late_theory_classes(_, []).

%% ============================================================================
%% format_recommendation/2
%% ============================================================================
%% Format: format_recommendation(+Recommendation, -Dict)
%%
%% Converts an internal recommendation/4 term into a JSON-friendly dict.
%%
format_recommendation(recommendation(Priority, Category, Description, ActionData),
                       _{priority: Priority,
                         category: Category,
                         description: Description,
                         action: ActionDict}) :-
    action_to_dict(ActionData, ActionDict).

%% action_to_dict/2 – convert action term to a dict
action_to_dict(action(Type, Pairs), Dict) :-
    !,
    action_to_dict(action(Type, Pairs), Dict).
action_to_dict(Action, Dict) :-
    Action =.. [action | AllArgs],
    (AllArgs = [Type | Pairs] -> true ; Type = unknown, Pairs = []),
    pairs_to_action_dict(Pairs, PairsDict),
    put_dict(type, PairsDict, Type, Dict).

pairs_to_action_dict([], _{}).
pairs_to_action_dict([Key-Value | Rest], Dict) :-
    pairs_to_action_dict(Rest, RestDict),
    put_dict(Key, RestDict, Value, Dict).

%% ============================================================================
%% apply_recommendation/2
%% ============================================================================
%% Format: apply_recommendation(+Recommendation, -UpdatedMatrix)
%%
%% Attempts to execute the recommended action against the current timetable.
%% Currently supports: move_to_earlier_slot, compact_schedule.
%% Other action types return the matrix unchanged with a log warning.
%%
apply_recommendation(recommendation(_, _, _, ActionData), UpdatedMatrix) :-
    (   current_timetable_data(Matrix)
    ->  true
    ;   throw(error(no_timetable, 'No timetable available to apply recommendation'))
    ),
    execute_recommendation(ActionData, Matrix, UpdatedMatrix).

%% execute_recommendation/3
execute_recommendation(action(move_to_earlier_slot, Args), Matrix, UpdatedMatrix) :-
    !,
    member(class_id-ClassID,   Args),
    member(subject_id-SubjectID, Args),
    member(teacher_id-TeacherID, Args),
    member(slot_id-CurrentSlot, Args),
    % Find an earlier slot where teacher is free and room is suitable
    (timeslot(CurrentSlot, Day, CurrentPeriod, _, _) ; user:timeslot(CurrentSlot, Day, CurrentPeriod, _, _)),
    get_all_assignments(Matrix, Assignments),
    (   findall(EarlySlot,
                (   (timeslot(EarlySlot, Day, EarlyPeriod, _, _) ; user:timeslot(EarlySlot, Day, EarlyPeriod, _, _)),
                    EarlyPeriod < CurrentPeriod,
                    \+ member(assigned(_, _, _, TeacherID, EarlySlot), Assignments),
                    suitable_room_free_at_slot(SubjectID, EarlySlot, Assignments)
                ),
                EarlySlots),
        EarlySlots \= [],
        EarlySlots = [TargetSlot | _]
    ->
        % Move the assignment
        member(assigned(RoomID, ClassID, SubjectID, TeacherID, CurrentSlot), Assignments),
        find_room_index_rec(RoomID, RoomIdx),
        find_slot_index_rec(CurrentSlot, OldSlotIdx),
        find_slot_index_rec(TargetSlot, NewSlotIdx),
        set_cell(Matrix, RoomIdx, OldSlotIdx, empty, TempMatrix),
        set_cell(TempMatrix, RoomIdx, NewSlotIdx,
                 assigned(RoomID, ClassID, SubjectID, TeacherID, TargetSlot),
                 UpdatedMatrix),
        log_info('Applied move_to_earlier_slot recommendation')
    ;
        log_warning('No earlier slot available for recommendation; timetable unchanged'),
        UpdatedMatrix = Matrix
    ).

execute_recommendation(action(compact_schedule, Args), Matrix, Matrix) :-
    !,
    member(class_id-ClassID, Args),
    format(atom(Msg), 'Compact schedule for class ~w: manual review recommended', [ClassID]),
    log_info(Msg).

execute_recommendation(action(Type, _), Matrix, Matrix) :-
    format(atom(Msg), 'Recommendation action ~w noted; no automatic fix applied', [Type]),
    log_info(Msg).

%% ============================================================================
%% Helper predicates
%% ============================================================================

%% current_timetable_data(-Matrix)
current_timetable_data(Matrix) :-
    (   catch(api_server:current_timetable(Matrix), _, fail)
    ->  true
    ;   catch(user:current_timetable(Matrix), _, fail)
    ).

%% suitable_room_free_at_slot(+SubjectID, +SlotID, +Assignments)
suitable_room_free_at_slot(SubjectID, SlotID, Assignments) :-
    (   (subject(SubjectID, _, _, Type, _) ; user:subject(SubjectID, _, _, Type, _))
    ->  true
    ;   Type = theory
    ),
    (   room(RoomID, _, _, RoomType)
    ;   user:room(RoomID, _, _, RoomType)
    ),
    compatible_type(Type, RoomType),
    \+ member(assigned(RoomID, _, _, _, SlotID), Assignments).

%% find_room_index_rec(+RoomID, -Index)
find_room_index_rec(RoomID, Index) :-
    get_all_rooms(Rooms),
    nth0(Index, Rooms, room(RoomID, _, _, _)).

%% find_slot_index_rec(+SlotID, -Index)
find_slot_index_rec(SlotID, Index) :-
    get_all_timeslots(Slots),
    nth0(Index, Slots, timeslot(SlotID, _, _, _, _)).

%% ============================================================================
%% End of recommendation_engine.pl
%% ============================================================================
