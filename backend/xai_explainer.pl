%% ============================================================================
%% xai_explainer.pl - Explainable AI (XAI) Module
%% ============================================================================
%% Provides detailed step-by-step explanations for timetable assignments by
%% tracing logical inference steps, constraint checks, and quality scoring.
%%
%% MFAI Concept: Explainable AI (XAI) - proof tracing, constraint justification
%% Requirements: 9.1, 9.2, 9.3
%% ============================================================================

:- module(xai_explainer, [
    explain_assignment/6,
    trace_assignment_reason/6,
    format_explanation_steps/2,
    calculate_assignment_quality/4,
    teacher_workload_score/2,
    room_utilization_score/2,
    time_preference_score/2
]).

:- use_module(knowledge_base).
:- use_module(matrix_model).
:- use_module(library(lists)).

%% ============================================================================
%% explain_assignment/6
%% Main XAI predicate - produces a full structured explanation
%%
%% explain_assignment(+ClassID, +SubjectID, +TeacherID, +RoomID, +SlotID, -Explanation)
%%   Explanation = explanation{
%%     summary: atom,
%%     steps: [step{type, description, satisfied}],
%%     quality: float,
%%     quality_breakdown: quality_breakdown{...}
%%   }
%% ============================================================================
explain_assignment(ClassID, SubjectID, TeacherID, RoomID, SlotID, Explanation) :-
    % Collect all reasoning steps
    trace_assignment_reason(ClassID, SubjectID, TeacherID, RoomID, SlotID, Steps),
    % Format steps as human-readable text
    format_explanation_steps(Steps, FormattedSteps),
    % Calculate quality score
    calculate_assignment_quality(TeacherID, RoomID, SlotID, QualityBreakdown),
    QualityBreakdown = quality_breakdown{
        teacher_workload: TWScore,
        room_utilization: RUScore,
        time_preference: TPScore,
        overall: Overall
    },
    % Build summary sentence
    (   teacher(TeacherID, TName, _, _, _) -> true ; TName = TeacherID ),
    (   subject(SubjectID, SName, _, _, _) -> true ; SName = SubjectID ),
    (   room(RoomID, RName, _, _)          -> true ; RName = RoomID   ),
    (   timeslot(SlotID, Day, Period, StartTime, _) -> true
    ;   Day = unknown, Period = 0, StartTime = '??' ),
    (   class(ClassID, CName, _)           -> true ; CName = ClassID  ),
    format(atom(Summary),
        'Class ~w: ~w assigned to ~w in ~w at ~w period ~w (Day: ~w). Quality: ~2f',
        [CName, SName, TName, RName, StartTime, Period, Day, Overall]),
    Explanation = explanation{
        summary:           Summary,
        steps:             FormattedSteps,
        quality:           Overall,
        quality_breakdown: QualityBreakdown
    }.

%% ============================================================================
%% trace_assignment_reason/6
%% Collects all reasoning steps that justify an assignment.
%% Each step is a term: step(Type, Description, Satisfied)
%%   Type       : atom (qualification | room_type | availability | capacity |
%%                       no_teacher_conflict | no_room_conflict | weekly_hours)
%%   Description: atom (human-readable explanation)
%%   Satisfied  : true | false
%% ============================================================================
trace_assignment_reason(ClassID, SubjectID, TeacherID, RoomID, SlotID, Steps) :-
    findall(Step, check_step(ClassID, SubjectID, TeacherID, RoomID, SlotID, Step), Steps).

%% --- Individual reasoning steps ---

%% Step 1: Teacher qualification
check_step(_, SubjectID, TeacherID, _, _, step(qualification, Desc, Satisfied)) :-
    (   teacher(TeacherID, TName, _, _, _) -> true ; TName = TeacherID ),
    (   subject(SubjectID, SName, _, _, _) -> true ; SName = SubjectID ),
    (   qualified(TeacherID, SubjectID)
    ->  Satisfied = true,
        format(atom(Desc), '~w is qualified to teach ~w', [TName, SName])
    ;   Satisfied = false,
        format(atom(Desc), '~w is NOT qualified to teach ~w', [TName, SName])
    ).

%% Step 2: Room type compatibility
check_step(_, SubjectID, _, RoomID, _, step(room_type, Desc, Satisfied)) :-
    (   room(RoomID, RName, _, RType)      -> true ; RName = RoomID, RType = unknown ),
    (   subject(SubjectID, SName, _, SType, _) -> true ; SName = SubjectID, SType = unknown ),
    (   suitable_room(RoomID, SType)
    ->  Satisfied = true,
        format(atom(Desc), 'Room ~w (~w) is suitable for ~w sessions', [RName, RType, SType])
    ;   Satisfied = false,
        format(atom(Desc), 'Room ~w (~w) is NOT suitable for ~w sessions', [RName, RType, SType])
    ).

%% Step 3: Teacher availability
check_step(_, _, TeacherID, _, SlotID, step(availability, Desc, Satisfied)) :-
    (   teacher(TeacherID, TName, _, _, _) -> true ; TName = TeacherID ),
    (   timeslot(SlotID, Day, Period, _, _) -> true ; Day = unknown, Period = 0 ),
    (   teacher_available(TeacherID, SlotID)
    ->  Satisfied = true,
        format(atom(Desc), '~w is available on ~w period ~w', [TName, Day, Period])
    ;   Satisfied = false,
        format(atom(Desc), '~w is NOT available on ~w period ~w', [TName, Day, Period])
    ).

%% Step 4: Room capacity
check_step(ClassID, _, _, RoomID, _, step(capacity, Desc, Satisfied)) :-
    (   room(RoomID, RName, Capacity, _) -> true ; RName = RoomID, Capacity = 0 ),
    (   class_size(ClassID, Size)        -> true ; Size = 0 ),
    (   Size =< Capacity
    ->  Satisfied = true,
        format(atom(Desc), 'Room ~w (capacity ~w) fits class size ~w', [RName, Capacity, Size])
    ;   Satisfied = false,
        format(atom(Desc), 'Room ~w (capacity ~w) is too small for class size ~w', [RName, Capacity, Size])
    ).

%% ============================================================================
%% format_explanation_steps/2
%% Converts a list of step/3 terms into JSON-compatible dicts.
%% ============================================================================
format_explanation_steps([], []).
format_explanation_steps([step(Type, Desc, Satisfied)|Rest], [Dict|FormattedRest]) :-
    (Satisfied = true -> SatAtom = true ; SatAtom = false),
    Dict = step{type: Type, description: Desc, satisfied: SatAtom},
    format_explanation_steps(Rest, FormattedRest).

%% ============================================================================
%% calculate_assignment_quality/4
%% Produces a quality_breakdown dict with scores in [0.0, 1.0].
%%
%% calculate_assignment_quality(+TeacherID, +RoomID, +SlotID, -QualityBreakdown)
%% ============================================================================
calculate_assignment_quality(TeacherID, RoomID, SlotID, QualityBreakdown) :-
    teacher_workload_score(TeacherID, TWScore),
    room_utilization_score(RoomID, RUScore),
    time_preference_score(SlotID, TPScore),
    Overall is (TWScore + RUScore + TPScore) / 3.0,
    QualityBreakdown = quality_breakdown{
        teacher_workload: TWScore,
        room_utilization: RUScore,
        time_preference:  TPScore,
        overall:          Overall
    }.

%% ============================================================================
%% teacher_workload_score/2
%% Score in [0.0, 1.0]: higher when teacher has lighter current load.
%% Uses ratio of remaining capacity to max load.
%% ============================================================================
teacher_workload_score(TeacherID, Score) :-
    (   teacher(TeacherID, _, _, MaxLoad, _), MaxLoad > 0
    ->  % Count how many sessions this teacher already has in the current timetable
        (   current_timetable(Timetable)
        ->  get_all_assignments(Timetable, Assignments),
            findall(1, member(assigned(_, _, _, TeacherID, _), Assignments), Hits),
            length(Hits, CurrentLoad)
        ;   CurrentLoad = 0
        ),
        Remaining is MaxLoad - CurrentLoad,
        (Remaining >= 0 -> Score is Remaining / MaxLoad ; Score = 0.0)
    ;   Score = 0.5   % default when no data
    ).

%% ============================================================================
%% room_utilization_score/2
%% Score in [0.0, 1.0]: higher when room is less utilised (more available).
%% ============================================================================
room_utilization_score(RoomID, Score) :-
    (   get_all_timeslots(Slots), length(Slots, TotalSlots), TotalSlots > 0
    ->  (   current_timetable(Timetable)
        ->  get_all_assignments(Timetable, Assignments),
            findall(1, member(assigned(RoomID, _, _, _, _), Assignments), Hits),
            length(Hits, UsedSlots)
        ;   UsedSlots = 0
        ),
        FreeSlots is TotalSlots - UsedSlots,
        Score is FreeSlots / TotalSlots
    ;   Score = 0.5
    ).

%% ============================================================================
%% time_preference_score/2
%% Score in [0.0, 1.0]: penalises late-afternoon slots (period > 6).
%% ============================================================================
time_preference_score(SlotID, Score) :-
    (   timeslot(SlotID, _, Period, _, _)
    ->  (Period =< 4 -> Score = 1.0
        ; Period =< 6 -> Score = 0.75
        ; Period =< 8 -> Score = 0.5
        ;                Score = 0.25
        )
    ;   Score = 0.5
    ).

%% ============================================================================
%% Helper: current_timetable/1 - soft reference (may not exist)
%% ============================================================================
:- dynamic current_timetable/1.
