%% ============================================================================
%% pattern_analyzer.pl - Automatic Constraint Discovery Module
%% ============================================================================
%% Analyses a generated timetable to discover hidden scheduling patterns and
%% suggest new soft constraints based on observed regularities.
%%
%% Pattern types discovered:
%%   1. Temporal patterns  – e.g., "AI classes usually scheduled in the morning"
%%   2. Resource patterns  – e.g., "Labs rarely used on Fridays"
%%   3. Teacher patterns   – e.g., "Dr. Smith prefers consecutive slots"
%%
%% Each pattern is returned as:
%%   pattern(Type, Description, Confidence, SuggestedConstraint)
%%
%% Requirements: Feature 14 (Task 28D)
%% ============================================================================

:- module(pattern_analyzer, [
    discover_patterns/2,
    detect_temporal_patterns/2,
    detect_resource_patterns/2,
    detect_teacher_patterns/2,
    suggest_new_constraints/2,
    validate_discovered_pattern/2
]).

:- use_module(knowledge_base).
:- use_module(matrix_model).
:- use_module(logging).

:- multifile teacher/5, subject/5, room/4, timeslot/5, class/3.
:- dynamic   teacher/5, subject/5, room/4, timeslot/5, class/3.

%% Confidence threshold – patterns below this are discarded
confidence_threshold(0.6).

%% "Morning" periods are 1-4; "afternoon" are 5+
morning_period_threshold(4).

%% A day is considered "rarely used" for a resource type when its share of
%% total assignments is below this fraction.
rare_day_threshold(0.1).

%% A teacher is considered to "prefer consecutive slots" when the fraction of
%% their days that contain at least one consecutive pair exceeds this value.
consecutive_preference_threshold(0.5).

%% ============================================================================
%% discover_patterns/2 – main entry point
%% ============================================================================
%% Format: discover_patterns(+Matrix, -Patterns)
%%
%% Runs all three analyses, validates each pattern, and returns the combined
%% list sorted by descending confidence.
%%
discover_patterns(Matrix, ValidatedPatterns) :-
    log_info('Starting automatic constraint discovery'),
    detect_temporal_patterns(Matrix, TemporalPatterns),
    detect_resource_patterns(Matrix, ResourcePatterns),
    detect_teacher_patterns(Matrix, TeacherPatterns),
    append([TemporalPatterns, ResourcePatterns, TeacherPatterns], AllPatterns),
    include(validate_discovered_pattern_bool, AllPatterns, ValidatedPatterns0),
    % Sort by confidence descending: extract confidence, sort, return patterns
    findall(Conf-P,
            (member(P, ValidatedPatterns0), P = pattern(_, _, Conf, _)),
            ConfPairs),
    sort(1, @>=, ConfPairs, SortedPairs),
    pairs_values(SortedPairs, ValidatedPatterns),
    length(ValidatedPatterns, N),
    format(atom(Msg), 'Discovered ~w significant patterns', [N]),
    log_info(Msg).

%% Helper used with include/3 – succeeds when pattern passes validation
validate_discovered_pattern_bool(Pattern) :-
    validate_discovered_pattern(Pattern, true).

%% ============================================================================
%% detect_temporal_patterns/2
%% ============================================================================
%% Format: detect_temporal_patterns(+Matrix, -Patterns)
%%
%% Detects whether particular subject types (theory / lab) are predominantly
%% scheduled in morning or afternoon slots.
%%
detect_temporal_patterns(Matrix, Patterns) :-
    get_all_assignments(Matrix, Assignments),
    Assignments \= [],
    findall(Pattern,
            detect_subject_time_preference(Assignments, Pattern),
            Patterns).

detect_temporal_patterns(_, []).

%% detect_subject_time_preference(+Assignments, -Pattern)
detect_subject_time_preference(Assignments, Pattern) :-
    % Collect all unique subject types present
    findall(Type,
            (member(assigned(_, _, SubjectID, _, _), Assignments),
             (subject(SubjectID, _, _, Type, _) ; user:subject(SubjectID, _, _, Type, _))),
            AllTypes),
    sort(AllTypes, UniqueTypes),
    member(SubjectType, UniqueTypes),
    % Count morning vs afternoon assignments for this type
    morning_period_threshold(MorningMax),
    findall(1,
            (member(assigned(_, _, SID, _, SlotID), Assignments),
             (subject(SID, _, _, SubjectType, _) ; user:subject(SID, _, _, SubjectType, _)),
             (timeslot(SlotID, _, Period, _, _) ; user:timeslot(SlotID, _, Period, _, _)),
             Period =< MorningMax),
            MorningHits),
    findall(1,
            (member(assigned(_, _, SID, _, SlotID), Assignments),
             (subject(SID, _, _, SubjectType, _) ; user:subject(SID, _, _, SubjectType, _)),
             (timeslot(SlotID, _, Period, _, _) ; user:timeslot(SlotID, _, Period, _, _)),
             Period > MorningMax),
            AfternoonHits),
    length(MorningHits, MorningCount),
    length(AfternoonHits, AfternoonCount),
    Total is MorningCount + AfternoonCount,
    Total > 0,
    % Determine dominant time preference
    (MorningCount >= AfternoonCount ->
        Dominant = morning,
        Confidence is MorningCount / Total
    ;
        Dominant = afternoon,
        Confidence is AfternoonCount / Total
    ),
    Confidence >= 0.6,   % only report if clearly dominant
    format(atom(Desc),
           '~w sessions are predominantly scheduled in the ~w (~1f% of assignments)',
           [SubjectType, Dominant, Confidence * 100]),
    SuggestedConstraint = prefer_time_of_day(SubjectType, Dominant, Confidence),
    Pattern = pattern(temporal, Desc, Confidence, SuggestedConstraint).

%% ============================================================================
%% detect_resource_patterns/2
%% ============================================================================
%% Format: detect_resource_patterns(+Matrix, -Patterns)
%%
%% Detects rooms or room types that are rarely used on specific days of the
%% week (e.g., "Labs rarely scheduled on Fridays").
%%
detect_resource_patterns(Matrix, Patterns) :-
    get_all_assignments(Matrix, Assignments),
    Assignments \= [],
    findall(Pattern,
            detect_room_day_pattern(Assignments, Pattern),
            Patterns).

detect_resource_patterns(_, []).

%% detect_room_day_pattern(+Assignments, -Pattern)
detect_room_day_pattern(Assignments, Pattern) :-
    % Collect all unique room types
    findall(RType,
            (member(assigned(RID, _, _, _, _), Assignments),
             (room(RID, _, _, RType) ; user:room(RID, _, _, RType))),
            AllRTypes),
    sort(AllRTypes, UniqueRTypes),
    member(RoomType, UniqueRTypes),
    % Collect all days that appear in the timetable
    findall(Day,
            (member(assigned(_, _, _, _, SlotID), Assignments),
             (timeslot(SlotID, Day, _, _, _) ; user:timeslot(SlotID, Day, _, _, _))),
            AllDays),
    sort(AllDays, UniqueDays),
    UniqueDays \= [],
    % Count total assignments for this room type
    findall(1,
            (member(assigned(RID, _, _, _, _), Assignments),
             (room(RID, _, _, RoomType) ; user:room(RID, _, _, RoomType))),
            TotalHits),
    length(TotalHits, TotalCount),
    TotalCount > 0,
    % Find a day with very low usage for this room type
    member(Day, UniqueDays),
    findall(1,
            (member(assigned(RID, _, _, _, SlotID), Assignments),
             (room(RID, _, _, RoomType) ; user:room(RID, _, _, RoomType)),
             (timeslot(SlotID, Day, _, _, _) ; user:timeslot(SlotID, Day, _, _, _))),
            DayHits),
    length(DayHits, DayCount),
    DayFraction is DayCount / TotalCount,
    rare_day_threshold(RareThreshold),
    DayFraction < RareThreshold,
    Confidence is 1.0 - DayFraction,
    format(atom(Desc),
           '~w rooms are rarely used on ~w (~1f% of their assignments)',
           [RoomType, Day, DayFraction * 100]),
    SuggestedConstraint = avoid_room_type_on_day(RoomType, Day, Confidence),
    Pattern = pattern(resource, Desc, Confidence, SuggestedConstraint).

%% ============================================================================
%% detect_teacher_patterns/2
%% ============================================================================
%% Format: detect_teacher_patterns(+Matrix, -Patterns)
%%
%% Detects teachers who tend to have consecutive teaching slots on the same day
%% (indicating a preference for back-to-back sessions).
%%
detect_teacher_patterns(Matrix, Patterns) :-
    get_all_assignments(Matrix, Assignments),
    Assignments \= [],
    get_all_teachers(Teachers),
    Teachers \= [],
    findall(Pattern,
            detect_teacher_consecutive_preference(Assignments, Teachers, Pattern),
            Patterns).

detect_teacher_patterns(_, []).

%% detect_teacher_consecutive_preference(+Assignments, +Teachers, -Pattern)
detect_teacher_consecutive_preference(Assignments, Teachers, Pattern) :-
    member(teacher(TID, TName, _, _, _), Teachers),
    % Get all slots assigned to this teacher
    findall(SlotID,
            member(assigned(_, _, _, TID, SlotID), Assignments),
            TeacherSlots),
    TeacherSlots \= [],
    % Group by day
    findall(Day,
            (member(S, TeacherSlots),
             (timeslot(S, Day, _, _, _) ; user:timeslot(S, Day, _, _, _))),
            AllDays),
    sort(AllDays, UniqueDays),
    UniqueDays \= [],
    % Count days with at least one consecutive pair
    findall(1,
            (member(Day, UniqueDays),
             has_consecutive_slots_on_day(TID, Day, Assignments)),
            ConsecDays),
    length(ConsecDays, ConsecCount),
    length(UniqueDays, TotalDays),
    TotalDays > 0,
    Confidence is ConsecCount / TotalDays,
    consecutive_preference_threshold(Threshold),
    Confidence >= Threshold,
    format(atom(Desc),
           'Teacher ~w prefers consecutive slots (~1f% of teaching days have back-to-back sessions)',
           [TName, Confidence * 100]),
    SuggestedConstraint = prefer_consecutive_slots(TID, Confidence),
    Pattern = pattern(teacher, Desc, Confidence, SuggestedConstraint).

%% has_consecutive_slots_on_day(+TeacherID, +Day, +Assignments)
%% Succeeds if the teacher has at least two consecutive periods on the given day.
has_consecutive_slots_on_day(TeacherID, Day, Assignments) :-
    findall(Period,
            (member(assigned(_, _, _, TeacherID, SlotID), Assignments),
             (timeslot(SlotID, Day, Period, _, _) ; user:timeslot(SlotID, Day, Period, _, _))),
            Periods),
    sort(Periods, Sorted),
    consecutive_pair_exists(Sorted).

%% consecutive_pair_exists(+SortedPeriods)
consecutive_pair_exists([P1, P2 | _]) :-
    P2 is P1 + 1, !.
consecutive_pair_exists([_ | Rest]) :-
    consecutive_pair_exists(Rest).

%% ============================================================================
%% suggest_new_constraints/2
%% ============================================================================
%% Format: suggest_new_constraints(+Matrix, -Constraints)
%%
%% Convenience predicate: discovers patterns and extracts the suggested
%% constraint term from each validated pattern.
%%
suggest_new_constraints(Matrix, Constraints) :-
    discover_patterns(Matrix, Patterns),
    findall(Constraint,
            member(pattern(_, _, _, Constraint), Patterns),
            Constraints).

%% ============================================================================
%% validate_discovered_pattern/2
%% ============================================================================
%% Format: validate_discovered_pattern(+Pattern, -Valid)
%%
%% Checks that a pattern's confidence exceeds the configured threshold.
%% Valid is unified with `true` or `false`.
%%
validate_discovered_pattern(pattern(_, _, Confidence, _), true) :-
    confidence_threshold(Threshold),
    Confidence >= Threshold,
    !.
validate_discovered_pattern(_, false).

%% ============================================================================
%% End of pattern_analyzer.pl
%% ============================================================================
