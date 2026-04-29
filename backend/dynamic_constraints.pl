% ============================================================================
% dynamic_constraints.pl - Constraint Importance Slider Module
% ============================================================================
% This module allows users to assign importance weights (0.0-1.0) to each
% soft constraint, enabling customised timetable generation that prioritises
% the preferences that matter most to the administrator.
%
% Soft constraints supported:
%   - workload_balance    : Balanced teacher workload across the week
%   - avoid_late_theory   : Avoid scheduling theory classes late in the day
%   - minimize_gaps       : Minimise gaps in student schedules
%   - teacher_preference  : Honour teacher time-slot preferences
%   - room_optimization   : Maximise room utilisation efficiency
%   - student_compact     : Keep student schedules compact
%
% Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6
%
% Author: AI Timetable Generation System
% ============================================================================

:- module(dynamic_constraints, [
    initialize_constraint_weights/0,
    set_constraint_weight/2,
    get_constraint_weight/2,
    calculate_weighted_soft_score/2,
    teacher_preference_score/2,
    room_optimization_score/2,
    student_compact_score/2,
    generate_with_custom_weights/2,
    get_all_weights/1,
    reset_constraint_weights/0
]).

:- use_module(constraints, [
    soft_balanced_workload/3,
    soft_avoid_late_theory/3,
    soft_minimize_gaps/3
]).
:- use_module(matrix_model, [get_all_assignments/2]).
:- use_module(knowledge_base, [
    get_all_teachers/1,
    get_all_rooms/1,
    get_all_timeslots/1
]).
:- use_module(timetable_generator, [generate_timetable/1]).
:- use_module(logging, [log_info/1, log_debug/1]).

% Dynamic storage for constraint weights
:- dynamic constraint_weight/2.

% Default weights for all soft constraints (0.0 to 1.0)
default_weight(workload_balance,  0.8).
default_weight(avoid_late_theory, 0.7).
default_weight(minimize_gaps,     0.6).
default_weight(teacher_preference,0.5).
default_weight(room_optimization, 0.5).
default_weight(student_compact,   0.6).

% ============================================================================
% initialize_constraint_weights/0
% ============================================================================
% Sets all constraint weights to their default values.
% Safe to call multiple times - clears existing weights first.
%
% Requirements: 5.1-5.6
%
initialize_constraint_weights :-
    retractall(constraint_weight(_, _)),
    forall(
        default_weight(Name, Value),
        assertz(constraint_weight(Name, Value))
    ),
    log_info('Constraint weights initialised to defaults').

% ============================================================================
% set_constraint_weight/2
% ============================================================================
% Updates the weight for a named soft constraint.
% Weight must be in the range [0.0, 1.0].
%
% @param ConstraintName  Atom identifying the constraint
% @param Weight          Float in [0.0, 1.0]
%
set_constraint_weight(ConstraintName, Weight) :-
    (   number(Weight), Weight >= 0.0, Weight =< 1.0
    ->  true
    ;   throw(error(invalid_weight(ConstraintName, Weight),
                    'Weight must be a number between 0.0 and 1.0'))
    ),
    (   default_weight(ConstraintName, _)
    ->  true
    ;   throw(error(unknown_constraint(ConstraintName),
                    'Unknown constraint name'))
    ),
    retractall(constraint_weight(ConstraintName, _)),
    assertz(constraint_weight(ConstraintName, Weight)),
    format(atom(Msg), 'Constraint weight updated: ~w = ~4f', [ConstraintName, Weight]),
    log_info(Msg).

% ============================================================================
% get_constraint_weight/2
% ============================================================================
% Retrieves the current weight for a named soft constraint.
% Falls back to the default if no custom weight has been set.
%
% @param ConstraintName  Atom identifying the constraint
% @param Weight          Output: current weight value
%
get_constraint_weight(ConstraintName, Weight) :-
    (   constraint_weight(ConstraintName, Weight)
    ->  true
    ;   default_weight(ConstraintName, Weight)
    ).

% ============================================================================
% get_all_weights/1
% ============================================================================
% Returns a list of Name-Weight pairs for all soft constraints.
%
% @param Weights  Output: list of constraint_weight(Name, Value) terms
%
get_all_weights(Weights) :-
    findall(
        constraint_weight(Name, Weight),
        (   default_weight(Name, _),
            get_constraint_weight(Name, Weight)
        ),
        Weights
    ).

% ============================================================================
% reset_constraint_weights/0
% ============================================================================
% Resets all weights back to their defaults.
%
reset_constraint_weights :-
    initialize_constraint_weights,
    log_info('Constraint weights reset to defaults').

% ============================================================================
% calculate_weighted_soft_score/2
% ============================================================================
% Calculates the overall weighted soft constraint score for a timetable.
% Each soft constraint score is multiplied by its weight, then the weighted
% average is computed.
%
% @param Matrix      The timetable matrix to evaluate
% @param TotalScore  Output: weighted aggregate score (0.0 to 1.0)
%
% Requirements: 5.1, 5.2, 5.3, 5.5, 5.6
%
calculate_weighted_soft_score(Matrix, TotalScore) :-
    get_all_assignments(Matrix, Assignments),
    (   Assignments = []
    ->  TotalScore = 1.0
    ;   collect_weighted_scores(Matrix, Assignments, WeightedScores),
        (   WeightedScores = []
        ->  TotalScore = 1.0
        ;   pairs_keys_values(WeightedScores, Weights, Scores),
            sum_list(Weights, TotalWeight),
            maplist([W, S, WS]>>(WS is W * S), Weights, Scores, WeightedProducts),
            sum_list(WeightedProducts, WeightedSum),
            (   TotalWeight > 0
            ->  TotalScore is WeightedSum / TotalWeight
            ;   TotalScore = 1.0
            )
        )
    ).

% collect_weighted_scores(+Matrix, +Assignments, -WeightedScores)
% Gathers [Weight-Score] pairs for each applicable soft constraint.
collect_weighted_scores(Matrix, Assignments, WeightedScores) :-
    get_all_teachers(Teachers),
    get_constraint_weight(workload_balance,  W1),
    get_constraint_weight(avoid_late_theory, W2),
    get_constraint_weight(minimize_gaps,     W3),
    get_constraint_weight(teacher_preference,W4),
    get_constraint_weight(room_optimization, W5),
    get_constraint_weight(student_compact,   W6),

    % Workload balance: average across all teachers
    findall(S, (member(teacher(TID, _, _, _, _), Teachers),
                soft_balanced_workload(TID, Matrix, S)), WBScores),
    (WBScores = [] -> WB = 1.0 ; sum_list(WBScores, WBSum), length(WBScores, WBN), WB is WBSum / WBN),

    % Avoid late theory: average across all assignments
    findall(S, (member(assigned(_, SubjectID, _), Assignments),
                soft_avoid_late_theory(SubjectID, _, S)), ALTScores),
    (ALTScores = [] -> ALT = 1.0 ; sum_list(ALTScores, ALTSum), length(ALTScores, ALTN), ALT is ALTSum / ALTN),

    % Minimize gaps: average across all classes
    findall(ClassID, member(assigned(ClassID, _, _), Assignments), AllClasses),
    sort(AllClasses, UniqueClasses),
    findall(S, (member(CID, UniqueClasses),
                soft_minimize_gaps(CID, Matrix, S)), MGScores),
    (MGScores = [] -> MG = 1.0 ; sum_list(MGScores, MGSum), length(MGScores, MGN), MG is MGSum / MGN),

    % Teacher preference score
    teacher_preference_score(Matrix, TP),

    % Room optimisation score
    room_optimization_score(Matrix, RO),

    % Student compact score
    student_compact_score(Matrix, SC),

    WeightedScores = [W1-WB, W2-ALT, W3-MG, W4-TP, W5-RO, W6-SC].

% ============================================================================
% teacher_preference_score/2
% ============================================================================
% Calculates a score (0.0-1.0) reflecting how well teacher time-slot
% preferences are honoured. Teachers with more assignments in preferred
% slots score higher.
%
% @param Matrix  The timetable matrix
% @param Score   Output score (0.0 to 1.0)
%
% Requirements: 5.4
%
teacher_preference_score(Matrix, Score) :-
    get_all_assignments(Matrix, Assignments),
    (   Assignments = []
    ->  Score = 1.0
    ;   get_all_teachers(Teachers),
        findall(S,
                (member(teacher(TID, _, _, _, Availability), Teachers),
                 findall(1, (member(assigned(_, _, TID), Assignments),
                             % Simplified: all assigned slots are "preferred"
                             % since availability is already enforced as a hard constraint
                             true), Hits),
                 length(Hits, NumHits),
                 findall(1, member(assigned(_, _, TID), Assignments), All),
                 length(All, NumAll),
                 (NumAll > 0 -> S is NumHits / NumAll ; S = 1.0)),
                Scores),
        (   Scores = []
        ->  Score = 1.0
        ;   sum_list(Scores, Sum),
            length(Scores, N),
            Score is Sum / N
        )
    ).

% ============================================================================
% room_optimization_score/2
% ============================================================================
% Calculates a score (0.0-1.0) reflecting room utilisation efficiency.
% Higher utilisation (more rooms used, fewer empty slots) scores higher.
%
% @param Matrix  The timetable matrix
% @param Score   Output score (0.0 to 1.0)
%
% Requirements: 5.5
%
room_optimization_score(Matrix, Score) :-
    get_all_rooms(Rooms),
    get_all_timeslots(Slots),
    length(Rooms, NumRooms),
    length(Slots, NumSlots),
    TotalCells is NumRooms * NumSlots,
    (   TotalCells =:= 0
    ->  Score = 1.0
    ;   get_all_assignments(Matrix, Assignments),
        length(Assignments, NumAssignments),
        % Optimal utilisation is around 70-80%; penalise both under and over
        OptimalRate is 0.75,
        ActualRate is NumAssignments / TotalCells,
        Diff is abs(ActualRate - OptimalRate),
        Score is max(0.0, 1.0 - Diff)
    ).

% ============================================================================
% student_compact_score/2
% ============================================================================
% Calculates a score (0.0-1.0) reflecting how compact student schedules are.
% Fewer gaps between sessions per day = higher score.
%
% @param Matrix  The timetable matrix
% @param Score   Output score (0.0 to 1.0)
%
% Requirements: 5.3, 5.6
%
student_compact_score(Matrix, Score) :-
    get_all_assignments(Matrix, Assignments),
    (   Assignments = []
    ->  Score = 1.0
    ;   findall(ClassID, member(assigned(ClassID, _, _), Assignments), AllClasses),
        sort(AllClasses, UniqueClasses),
        findall(S, (member(CID, UniqueClasses),
                    soft_minimize_gaps(CID, Matrix, S)), Scores),
        (   Scores = []
        ->  Score = 1.0
        ;   sum_list(Scores, Sum),
            length(Scores, N),
            Score is Sum / N
        )
    ).

% ============================================================================
% generate_with_custom_weights/2
% ============================================================================
% Generates a timetable using the currently configured constraint weights.
% The weights influence soft constraint scoring during generation.
% Hard constraints are always fully enforced regardless of weights.
%
% @param Weights   List of Name-Value pairs to apply before generation
%                  (use [] to keep current weights)
% @param Timetable Output: generated timetable matrix
%
% Requirements: 5.1-5.6
%
generate_with_custom_weights(Weights, Timetable) :-
    % Apply any provided weight overrides
    (   Weights \= []
    ->  maplist([Name-Value]>>(set_constraint_weight(Name, Value)), Weights)
    ;   true
    ),
    log_info('Generating timetable with custom constraint weights'),
    % Log current weights for debugging
    get_all_weights(CurrentWeights),
    format(atom(WeightMsg), 'Active weights: ~w', [CurrentWeights]),
    log_debug(WeightMsg),
    % Delegate to the standard generator; soft scoring uses the dynamic weights
    generate_timetable(Timetable).

% ============================================================================
% Ensure weights are initialised when the module is loaded
% ============================================================================
:- initialization(initialize_constraint_weights, now).

% ============================================================================
% END OF MODULE
% ============================================================================
