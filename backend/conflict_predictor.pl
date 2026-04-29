% ============================================================================
% conflict_predictor.pl - Conflict Prediction and Risk Assessment Module
% ============================================================================
% This module analyses scheduling resources BEFORE timetable generation to
% predict potential conflicts, identify bottleneck resources, and suggest
% preventive actions.
%
% Key predicates:
%   predict_conflicts/2          - Analyse resources and return predicted risks
%   calculate_conflict_probability/2 - Estimate likelihood of conflicts (0.0-1.0)
%   identify_bottleneck_resources/2  - Find over-demanded resources
%   suggest_preventive_actions/2     - Recommend actions to avoid conflicts
%   risk_assessment/2                - Categorise overall risk (low/medium/high/critical)
%
% Requirements: Feature 28I (Task 28I.1)
%
% Author: AI Timetable Generation System
% ============================================================================

:- module(conflict_predictor, [
    predict_conflicts/2,
    calculate_conflict_probability/2,
    identify_bottleneck_resources/2,
    suggest_preventive_actions/2,
    risk_assessment/2
]).

:- use_module(knowledge_base, [
    get_all_teachers/1,
    get_all_subjects/1,
    get_all_rooms/1,
    get_all_timeslots/1,
    get_all_classes/1,
    qualified/2,
    suitable_room/2,
    teacher_available/2
]).
:- use_module(logging, [log_info/1, log_warning/1]).

% Allow access to dynamic facts from other modules / user space
:- multifile teacher/5, subject/5, room/4, timeslot/5, class/3.
:- dynamic  teacher/5, subject/5, room/4, timeslot/5, class/3.

% ============================================================================
% predict_conflicts/2
% ============================================================================
% Analyse all scheduling resources and return a list of predicted conflict
% risk terms before timetable generation begins.
%
% Format: predict_conflicts(+Sessions, -Risks)
%
%   Sessions : List of session(ClassID, SubjectID) terms, or [] to derive
%              sessions automatically from the knowledge base.
%   Risks    : List of risk terms:
%                teacher_overload_risk(TeacherID, DemandedSlots, AvailableSlots)
%                room_shortage_risk(Type, DemandedRooms, AvailableRooms)
%                timeslot_shortage_risk(DemandedSlots, AvailableSlots)
%                unqualified_subject_risk(SubjectID)
%                no_suitable_room_risk(SubjectID, Type)
%
% ============================================================================

predict_conflicts(Sessions, Risks) :-
    log_info('Starting conflict prediction analysis'),
    resolve_sessions(Sessions, ResolvedSessions),
    findall(Risk, predict_risk(ResolvedSessions, Risk), Risks),
    length(Risks, NumRisks),
    (NumRisks =:= 0
    ->  log_info('No conflict risks detected')
    ;   log_warning('Conflict risks detected before generation')
    ).

%% resolve_sessions(+Sessions, -Resolved)
%  If Sessions is empty, derive sessions from the knowledge base.
resolve_sessions([], Resolved) :-
    !,
    get_all_classes(Classes),
    findall(session(ClassID, SubjectID),
            (member(class(ClassID, _, SubjectList), Classes),
             member(SubjectID, SubjectList)),
            Resolved).
resolve_sessions(Sessions, Sessions).

%% predict_risk(+Sessions, -Risk)
%  Generate individual risk terms for the given session list.
predict_risk(Sessions, teacher_overload_risk(TeacherID, Demanded, Available)) :-
    % Count how many sessions each teacher would need to cover
    findall(T,
            (member(session(_, SubjectID), Sessions),
             (teacher(T, _, QS, _, _) ; user:teacher(T, _, QS, _, _)),
             member(SubjectID, QS)),
            AllTeacherDemands),
    sort(AllTeacherDemands, UniqueTeachers),
    member(TeacherID, UniqueTeachers),
    findall(S, member(session(_, S), Sessions), AllSubjects),
    findall(S,
            (member(S, AllSubjects),
             (teacher(TeacherID, _, QS2, _, _) ; user:teacher(TeacherID, _, QS2, _, _)),
             member(S, QS2)),
            TeacherSubjects),
    length(TeacherSubjects, Demanded),
    (   (teacher(TeacherID, _, _, _, Avail) ; user:teacher(TeacherID, _, _, _, Avail))
    ->  length(Avail, Available)
    ;   Available = 0
    ),
    Demanded > Available.

predict_risk(Sessions, room_shortage_risk(Type, Demanded, Available)) :-
    member(Type, [theory, lab]),
    findall(S,
            (member(session(_, SubjectID), Sessions),
             (subject(SubjectID, _, _, Type, _) ; user:subject(SubjectID, _, _, Type, _)),
             S = SubjectID),
            TypeSessions),
    length(TypeSessions, Demanded),
    (Type = theory -> RoomType = classroom ; RoomType = lab),
    findall(R,
            (room(R, _, _, RoomType) ; user:room(R, _, _, RoomType)),
            TypeRooms),
    length(TypeRooms, Available),
    Demanded > Available.

predict_risk(Sessions, timeslot_shortage_risk(Demanded, Available)) :-
    length(Sessions, Demanded),
    findall(S, (timeslot(S, _, _, _, _) ; user:timeslot(S, _, _, _, _)), AllSlots),
    length(AllSlots, Available),
    Demanded > Available.

predict_risk(Sessions, unqualified_subject_risk(SubjectID)) :-
    member(session(_, SubjectID), Sessions),
    \+ (qualified(_T, SubjectID) ; (teacher(_T, _, QS, _, _), member(SubjectID, QS))),
    \+ user:qualified(SubjectID, _).

predict_risk(Sessions, no_suitable_room_risk(SubjectID, Type)) :-
    member(session(_, SubjectID), Sessions),
    (subject(SubjectID, _, _, Type, _) ; user:subject(SubjectID, _, _, Type, _)),
    \+ suitable_room(_, Type),
    (Type = theory -> RoomType = classroom ; RoomType = lab),
    \+ (room(_, _, _, RoomType) ; user:room(_, _, _, RoomType)).

% ============================================================================
% calculate_conflict_probability/2
% ============================================================================
% Estimate the overall probability (0.0 – 1.0) that conflicts will occur
% during timetable generation, based on resource supply vs demand ratios.
%
% Format: calculate_conflict_probability(+Sessions, -Probability)
%
%   Sessions    : List of session/2 terms (or [] to auto-derive)
%   Probability : Estimated conflict probability in [0.0, 1.0]
%
% The probability is computed as a weighted average of three sub-scores:
%   1. Teacher pressure  = max(0, (Demand - Supply) / Demand)
%   2. Room pressure     = max(0, (Demand - Supply) / Demand)
%   3. Timeslot pressure = max(0, (Demand - Supply) / Demand)
%
% ============================================================================

calculate_conflict_probability(Sessions, Probability) :-
    resolve_sessions(Sessions, ResolvedSessions),
    length(ResolvedSessions, TotalSessions),
    (TotalSessions =:= 0
    ->  Probability = 0.0
    ;   teacher_pressure(ResolvedSessions, TP),
        room_pressure(ResolvedSessions, RP),
        timeslot_pressure(ResolvedSessions, SP),
        % Weighted average: teacher conflicts are most common
        Raw is (0.4 * TP + 0.35 * RP + 0.25 * SP),
        Probability is min(1.0, max(0.0, Raw))
    ).

%% teacher_pressure(+Sessions, -Pressure)
%  Ratio of demanded teacher-slots to available teacher-slots.
teacher_pressure(Sessions, Pressure) :-
    length(Sessions, Demand),
    findall(SlotID,
            (   (teacher(_, _, _, _, Avail) ; user:teacher(_, _, _, _, Avail)),
                member(SlotID, Avail)),
            AllAvailSlots),
    length(AllAvailSlots, Supply),
    (Supply =:= 0
    ->  Pressure = 1.0
    ;   Pressure is max(0.0, (Demand - Supply) / Demand)
    ).

%% room_pressure(+Sessions, -Pressure)
%  Ratio of demanded room-slots to available room-slots.
room_pressure(Sessions, Pressure) :-
    length(Sessions, Demand),
    findall(R, (room(R, _, _, _) ; user:room(R, _, _, _)), Rooms),
    findall(S, (timeslot(S, _, _, _, _) ; user:timeslot(S, _, _, _, _)), Slots),
    length(Rooms, NR),
    length(Slots, NS),
    Supply is NR * NS,
    (Supply =:= 0
    ->  Pressure = 1.0
    ;   Pressure is max(0.0, (Demand - Supply) / Demand)
    ).

%% timeslot_pressure(+Sessions, -Pressure)
%  Ratio of sessions to available timeslots.
timeslot_pressure(Sessions, Pressure) :-
    length(Sessions, Demand),
    findall(S, (timeslot(S, _, _, _, _) ; user:timeslot(S, _, _, _, _)), Slots),
    length(Slots, Supply),
    (Supply =:= 0
    ->  Pressure = 1.0
    ;   Pressure is max(0.0, (Demand - Supply) / Demand)
    ).

% ============================================================================
% identify_bottleneck_resources/2
% ============================================================================
% Find resources (teachers / rooms / timeslots) that are over-demanded
% relative to their supply.
%
% Format: identify_bottleneck_resources(+Sessions, -Bottlenecks)
%
%   Sessions    : List of session/2 terms (or [] to auto-derive)
%   Bottlenecks : List of bottleneck terms:
%                   teacher_bottleneck(TeacherID, Name, Demand, Capacity)
%                   room_bottleneck(Type, Demand, Supply)
%                   timeslot_bottleneck(Demand, Supply)
%
% ============================================================================

identify_bottleneck_resources(Sessions, Bottlenecks) :-
    log_info('Identifying bottleneck resources'),
    resolve_sessions(Sessions, ResolvedSessions),
    findall(B, bottleneck(ResolvedSessions, B), Bottlenecks).

%% bottleneck(+Sessions, -Bottleneck)
%  Generate individual bottleneck terms.

% Teacher bottleneck: teacher's max load < sessions they are needed for
bottleneck(Sessions, teacher_bottleneck(TeacherID, Name, Demand, MaxLoad)) :-
    (teacher(TeacherID, Name, QS, MaxLoad, _) ; user:teacher(TeacherID, Name, QS, MaxLoad, _)),
    findall(SubjectID,
            (member(session(_, SubjectID), Sessions),
             member(SubjectID, QS)),
            TeacherSessions),
    length(TeacherSessions, Demand),
    Demand > MaxLoad.

% Room type bottleneck: more sessions of a type than rooms of that type
bottleneck(Sessions, room_bottleneck(Type, Demand, Supply)) :-
    member(Type, [theory, lab]),
    (Type = theory -> RoomType = classroom ; RoomType = lab),
    findall(S,
            (member(session(_, S), Sessions),
             (subject(S, _, _, Type, _) ; user:subject(S, _, _, Type, _))),
            TypeSessions),
    length(TypeSessions, Demand),
    findall(R,
            (room(R, _, _, RoomType) ; user:room(R, _, _, RoomType)),
            TypeRooms),
    length(TypeRooms, Supply),
    Demand > Supply.

% Timeslot bottleneck: more sessions than available timeslots
bottleneck(Sessions, timeslot_bottleneck(Demand, Supply)) :-
    length(Sessions, Demand),
    findall(S, (timeslot(S, _, _, _, _) ; user:timeslot(S, _, _, _, _)), Slots),
    length(Slots, Supply),
    Demand > Supply.

% ============================================================================
% suggest_preventive_actions/2
% ============================================================================
% Based on identified bottlenecks and predicted risks, recommend concrete
% actions an administrator can take to avoid conflicts before generation.
%
% Format: suggest_preventive_actions(+Sessions, -Actions)
%
%   Sessions : List of session/2 terms (or [] to auto-derive)
%   Actions  : List of action terms:
%                action(Priority, Description)
%              Priority is one of: critical, high, medium, low
%
% ============================================================================

suggest_preventive_actions(Sessions, Actions) :-
    log_info('Generating preventive action suggestions'),
    resolve_sessions(Sessions, ResolvedSessions),
    % Use internal helpers directly to avoid recursive call back into predict_conflicts
    findall(B, bottleneck(ResolvedSessions, B), Bottlenecks),
    findall(Risk, predict_risk(ResolvedSessions, Risk), Risks),
    findall(Action, generate_action(Bottlenecks, Risks, Action), AllActions),
    sort(AllActions, Actions).  % deduplicate

%% generate_action(+Bottlenecks, +Risks, -Action)
%  Map each bottleneck / risk to a concrete preventive action.

generate_action(Bottlenecks, _, action(critical, Desc)) :-
    member(teacher_bottleneck(_, Name, Demand, MaxLoad), Bottlenecks),
    format(atom(Desc),
           'Reduce load for teacher ~w: ~w sessions demanded but max load is ~w. Consider adding a qualified teacher.',
           [Name, Demand, MaxLoad]).

generate_action(Bottlenecks, _, action(high, Desc)) :-
    member(room_bottleneck(theory, Demand, Supply), Bottlenecks),
    format(atom(Desc),
           'Add more classrooms: ~w theory sessions but only ~w classrooms available.',
           [Demand, Supply]).

generate_action(Bottlenecks, _, action(high, Desc)) :-
    member(room_bottleneck(lab, Demand, Supply), Bottlenecks),
    format(atom(Desc),
           'Add more lab rooms: ~w lab sessions but only ~w labs available.',
           [Demand, Supply]).

generate_action(Bottlenecks, _, action(critical, Desc)) :-
    member(timeslot_bottleneck(Demand, Supply), Bottlenecks),
    format(atom(Desc),
           'Add more timeslots: ~w sessions but only ~w timeslots available.',
           [Demand, Supply]).

generate_action(_, Risks, action(high, Desc)) :-
    member(unqualified_subject_risk(SubjectID), Risks),
    format(atom(Desc),
           'Assign a qualified teacher for subject ~w before generation.',
           [SubjectID]).

generate_action(_, Risks, action(high, Desc)) :-
    member(no_suitable_room_risk(SubjectID, Type), Risks),
    format(atom(Desc),
           'Add a ~w room for subject ~w before generation.',
           [Type, SubjectID]).

generate_action(_, Risks, action(medium, Desc)) :-
    member(teacher_overload_risk(TeacherID, Demanded, Available), Risks),
    format(atom(Desc),
           'Teacher ~w has ~w sessions demanded but only ~w available slots. Extend availability or reduce load.',
           [TeacherID, Demanded, Available]).

generate_action(_, Risks, action(medium, Desc)) :-
    member(room_shortage_risk(Type, Demanded, Available), Risks),
    format(atom(Desc),
           'Room shortage for ~w sessions: ~w needed, ~w available. Consider adding rooms.',
           [Type, Demanded, Available]).

generate_action(_, Risks, action(low, Desc)) :-
    member(timeslot_shortage_risk(Demanded, Available), Risks),
    format(atom(Desc),
           'Timeslot pressure: ~w sessions for ~w slots. Consider spreading sessions across more days.',
           [Demanded, Available]).

% ============================================================================
% risk_assessment/2
% ============================================================================
% Categorise the overall scheduling risk level based on the conflict
% probability and the number/severity of identified bottlenecks.
%
% Format: risk_assessment(+Sessions, -RiskLevel)
%
%   Sessions  : List of session/2 terms (or [] to auto-derive)
%   RiskLevel : One of: low | medium | high | critical
%
% Thresholds (aligned with probability_module.pl risk_category/2):
%   critical : probability >= 0.30  OR  any critical-priority action exists
%   high     : probability >= 0.15  OR  any high-priority action exists
%   medium   : probability >= 0.05  OR  any medium-priority action exists
%   low      : otherwise
%
% ============================================================================

risk_assessment(Sessions, RiskLevel) :-
    log_info('Performing risk assessment'),
    resolve_sessions(Sessions, ResolvedSessions),
    calculate_conflict_probability(ResolvedSessions, Probability),
    findall(B, bottleneck(ResolvedSessions, B), Bottlenecks),
    findall(Risk, predict_risk(ResolvedSessions, Risk), Risks),
    findall(Action, generate_action(Bottlenecks, Risks, Action), AllActions),
    sort(AllActions, Actions),
    determine_risk_level(Probability, Actions, RiskLevel).

%% determine_risk_level(+Probability, +Actions, -Level)
%  Derive the risk level from probability and action priorities.
determine_risk_level(Probability, Actions, critical) :-
    (   Probability >= 0.30
    ;   member(action(critical, _), Actions)
    ), !.
determine_risk_level(Probability, Actions, high) :-
    (   Probability >= 0.15
    ;   member(action(high, _), Actions)
    ), !.
determine_risk_level(Probability, Actions, medium) :-
    (   Probability >= 0.05
    ;   member(action(medium, _), Actions)
    ), !.
determine_risk_level(_, _, low).

% ============================================================================
% END OF MODULE
% ============================================================================
% conflict_predictor.pl provides pre-generation conflict analysis for the
% AI-Based Timetable Generation System.  It demonstrates:
%
%   - Probabilistic Reasoning: conflict probability estimation from supply/demand
%   - First Order Logic: resource queries via knowledge_base predicates
%   - Constraint Satisfaction: bottleneck detection mirrors CSP domain analysis
%
% Public API summary:
%   predict_conflicts/2          - Full risk list from resource analysis
%   calculate_conflict_probability/2 - Single probability score
%   identify_bottleneck_resources/2  - Bottleneck resource list
%   suggest_preventive_actions/2     - Actionable recommendations
%   risk_assessment/2                - Overall risk category
% ============================================================================
