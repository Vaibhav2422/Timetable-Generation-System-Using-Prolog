%% ============================================================================
%% learning_module.pl - Historical Learning System
%% ============================================================================
%% Stores generated timetables in persistent history and learns scheduling
%% patterns from them. Learned preferences can bias future generation toward
%% high-quality assignment patterns.
%%
%% Dynamic predicates:
%%   timetable_history/2  - (Timestamp, Timetable)
%%   learned_pattern/3    - (PatternType, Key, Value)
%%
%% Requirements: Feature 13 (Task 28C)
%% ============================================================================

:- module(learning_module, [
    store_timetable_history/1,
    analyze_scheduling_patterns/2,
    learn_preferred_slots/2,
    learn_successful_assignments/2,
    apply_learned_preferences/2,
    get_learning_statistics/1,
    clear_learning_history/0
]).

:- use_module(knowledge_base).
:- use_module(matrix_model).
:- use_module(logging).

:- multifile teacher/5, subject/5, room/4, timeslot/5, class/3.
:- dynamic   teacher/5, subject/5, room/4, timeslot/5, class/3.

%% ============================================================================
%% Dynamic storage
%% ============================================================================

%% timetable_history(+Timestamp, +Timetable)
%% Stores a previously generated timetable with a timestamp.
:- dynamic timetable_history/2.

%% learned_pattern(+PatternType, +Key, +Value)
%% Stores a learned pattern.
%%   PatternType = preferred_slot | successful_assignment | teacher_preference
%%   Key         = teacher_id-subject_id | teacher_id | class_id-subject_id
%%   Value       = slot_id | score | count
:- dynamic learned_pattern/3.

%% ============================================================================
%% store_timetable_history/1
%% ============================================================================
%% Format: store_timetable_history(+Timetable)
%%
%% Saves a generated timetable to persistent history using assert.
%% Also triggers pattern analysis on the new entry.
%%
store_timetable_history(Timetable) :-
    get_time(Timestamp),
    assertz(timetable_history(Timestamp, Timetable)),
    log_info('Timetable stored in learning history'),
    % Re-analyse patterns after each new entry
    analyze_scheduling_patterns(Timetable, _Patterns).

%% ============================================================================
%% analyze_scheduling_patterns/2
%% ============================================================================
%% Format: analyze_scheduling_patterns(+Timetable, -Patterns)
%%
%% Detects patterns from a single timetable and accumulates them into the
%% learned_pattern store.  Returns a summary list of discovered patterns.
%%
analyze_scheduling_patterns(Timetable, Patterns) :-
    log_info('Analysing scheduling patterns'),
    get_all_assignments(Timetable, Assignments),
    learn_preferred_slots(Assignments, SlotPatterns),
    learn_successful_assignments(Assignments, AssignmentPatterns),
    append(SlotPatterns, AssignmentPatterns, Patterns),
    length(Patterns, N),
    format(atom(Msg), 'Discovered ~w patterns from timetable', [N]),
    log_info(Msg).

%% ============================================================================
%% learn_preferred_slots/2
%% ============================================================================
%% Format: learn_preferred_slots(+Assignments, -Patterns)
%%
%% Identifies which time slots each teacher is most frequently assigned to
%% and records them as preferred_slot patterns.
%%
learn_preferred_slots(Assignments, Patterns) :-
    % Collect teacher-slot pairs
    findall(TeacherID-SlotID,
            member(assigned(_, _, _, TeacherID, SlotID), Assignments),
            Pairs),
    % Count occurrences per teacher-slot combination
    aggregate_counts(Pairs, Counts),
    % Store patterns and build return list
    findall(pattern(preferred_slot, TeacherID-SlotID, Count),
            (member(Count-(TeacherID-SlotID), Counts),
             Count > 0,
             update_learned_pattern(preferred_slot, TeacherID-SlotID, Count)),
            Patterns).

%% ============================================================================
%% learn_successful_assignments/2
%% ============================================================================
%% Format: learn_successful_assignments(+Assignments, -Patterns)
%%
%% Identifies teacher-subject pairings that appear in the history and records
%% them as successful_assignment patterns with a frequency count.
%%
learn_successful_assignments(Assignments, Patterns) :-
    findall(TeacherID-SubjectID,
            member(assigned(_, _, SubjectID, TeacherID, _), Assignments),
            Pairs),
    aggregate_counts(Pairs, Counts),
    findall(pattern(successful_assignment, TeacherID-SubjectID, Count),
            (member(Count-(TeacherID-SubjectID), Counts),
             Count > 0,
             update_learned_pattern(successful_assignment, TeacherID-SubjectID, Count)),
            Patterns).

%% ============================================================================
%% apply_learned_preferences/2
%% ============================================================================
%% Format: apply_learned_preferences(+Assignments, -ScoredAssignments)
%%
%% Takes a list of candidate assignments and returns them annotated with a
%% preference score derived from learned patterns.  Higher score = more
%% preferred by the learning system.
%%
apply_learned_preferences(Assignments, ScoredAssignments) :-
    findall(Score-Assignment,
            (member(Assignment, Assignments),
             score_assignment_by_history(Assignment, Score)),
            ScoredAssignments).

%% score_assignment_by_history(+Assignment, -Score)
%% Compute a preference score for a single assignment.
score_assignment_by_history(assigned(_, _, SubjectID, TeacherID, SlotID), Score) :-
    % Preferred slot score
    (learned_pattern(preferred_slot, TeacherID-SlotID, SlotCount) -> SC = SlotCount ; SC = 0),
    % Successful assignment score
    (learned_pattern(successful_assignment, TeacherID-SubjectID, AssCount) -> AC = AssCount ; AC = 0),
    Score is SC + AC.

%% ============================================================================
%% get_learning_statistics/1
%% ============================================================================
%% Format: get_learning_statistics(-Stats)
%%
%% Returns a dict summarising what the system has learned:
%%   - timetables_analysed: number of stored timetables
%%   - patterns_discovered: total number of learned patterns
%%   - preferred_slots:     list of {teacher_id, slot_id, count}
%%   - successful_assignments: list of {teacher_id, subject_id, count}
%%
get_learning_statistics(Stats) :-
    aggregate_all(count, timetable_history(_, _), TimetableCount),
    aggregate_all(count, learned_pattern(_, _, _), PatternCount),
    % Preferred slots
    findall(_{teacher_id: TID, slot_id: SID, count: C},
            learned_pattern(preferred_slot, TID-SID, C),
            PreferredSlots),
    % Successful assignments
    findall(_{teacher_id: TID, subject_id: SubID, count: C},
            learned_pattern(successful_assignment, TID-SubID, C),
            SuccessfulAssignments),
    Stats = _{
        timetables_analysed:    TimetableCount,
        patterns_discovered:    PatternCount,
        preferred_slots:        PreferredSlots,
        successful_assignments: SuccessfulAssignments
    }.

%% ============================================================================
%% clear_learning_history/0
%% ============================================================================
%% Removes all stored history and learned patterns.
%%
clear_learning_history :-
    retractall(timetable_history(_, _)),
    retractall(learned_pattern(_, _, _)),
    log_info('Learning history cleared').

%% ============================================================================
%% Internal helpers
%% ============================================================================

%% aggregate_counts(+Pairs, -CountedPairs)
%% Given a list of Key-Value pairs, returns Count-Key pairs sorted descending.
aggregate_counts(Pairs, Counted) :-
    msort(Pairs, Sorted),
    count_runs(Sorted, Counted).

count_runs([], []).
count_runs([H|T], [Count-H|Rest]) :-
    count_prefix(H, [H|T], Count, Remaining),
    count_runs(Remaining, Rest).

count_prefix(_, [], 0, []) :- !.
count_prefix(X, [X|T], Count, Remaining) :-
    !,
    count_prefix(X, T, Count1, Remaining),
    Count is Count1 + 1.
count_prefix(_, List, 0, List).

%% update_learned_pattern(+Type, +Key, +NewCount)
%% Merge new count into existing learned_pattern fact (take max).
update_learned_pattern(Type, Key, NewCount) :-
    (   retract(learned_pattern(Type, Key, OldCount))
    ->  UpdatedCount is max(OldCount, NewCount)
    ;   UpdatedCount = NewCount
    ),
    assertz(learned_pattern(Type, Key, UpdatedCount)).

%% ============================================================================
%% End of learning_module.pl
%% ============================================================================
