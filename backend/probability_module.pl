% probability_module.pl
% Probabilistic reliability estimation module
% Demonstrates Probabilistic Reasoning through conditional probability calculations
%
% Probability Model:
% - Teacher availability: P(teacher_available) = 0.95
% - Room maintenance failure: P(room_unavailable) = 0.02 (availability = 0.98)
% - Class cancellation: P(class_cancelled) = 0.01 (occurrence = 0.99)
% - Dependencies: If teacher unavailable, all their sessions affected
%
% Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7

:- module(probability_module, [
    schedule_reliability/2,
    calculate_assignment_reliabilities/2,
    assignment_reliability/2,
    combine_probabilities/2,
    conditional_reliability/3,
    bayesian_reliability/3,
    expected_disruptions/2,
    risk_category/2,
    teacher_availability_prob/2,
    room_availability_prob/2,
    class_occurrence_prob/2
]).

:- use_module(matrix_model, [get_all_assignments/2]).

%% schedule_reliability(+Matrix, -Reliability)
%  Calculate overall schedule reliability score
%  Uses product rule for independent events: P(A and B and C) = P(A) * P(B) * P(C)
%  @param Matrix The timetable matrix
%  @param Reliability Overall reliability score (0.0 to 1.0)
%  Requirements: 8.4, 8.5, 8.7
schedule_reliability(Matrix, Reliability) :-
    get_all_assignments(Matrix, Assignments),
    calculate_assignment_reliabilities(Assignments, Probabilities),
    combine_probabilities(Probabilities, Reliability).

%% calculate_assignment_reliabilities(+Assignments, -Probabilities)
%  Calculate reliability for each assignment in the list
%  @param Assignments List of assignments
%  @param Probabilities List of reliability scores for each assignment
%  Requirements: 8.5
calculate_assignment_reliabilities([], []).
calculate_assignment_reliabilities([Assignment|Rest], [Prob|Probs]) :-
    assignment_reliability(Assignment, Prob),
    calculate_assignment_reliabilities(Rest, Probs).

%% assignment_reliability(+Assignment, -Probability)
%  Calculate reliability of a single assignment
%  Assignment format: assigned(RoomID, ClassID, SubjectID, TeacherID, SlotID)
%  Uses product rule for independent events
%  @param Assignment Single assignment structure
%  @param Probability Reliability score for this assignment
%  Requirements: 8.1, 8.2, 8.3, 8.5
assignment_reliability(assigned(RoomID, ClassID, _SubjectID, TeacherID, _SlotID), Probability) :-
    teacher_availability_prob(TeacherID, PTeacher),
    room_availability_prob(RoomID, PRoom),
    class_occurrence_prob(ClassID, PClass),
    % Independent events: P(A and B and C) = P(A) * P(B) * P(C)
    Probability is PTeacher * PRoom * PClass.

%% teacher_availability_prob(+TeacherID, -Probability)
%  Get teacher availability probability
%  Default: 95% availability
%  @param TeacherID Teacher identifier
%  @param Probability Availability probability (0.95)
%  Requirements: 8.1
teacher_availability_prob(_, 0.95).

%% room_availability_prob(+RoomID, -Probability)
%  Get room availability probability
%  Default: 98% availability (2% maintenance failure)
%  @param RoomID Room identifier
%  @param Probability Availability probability (0.98)
%  Requirements: 8.2
room_availability_prob(_, 0.98).

%% class_occurrence_prob(+ClassID, -Probability)
%  Get class occurrence probability
%  Default: 99% occurrence (1% cancellation)
%  @param ClassID Class identifier
%  @param Probability Occurrence probability (0.99)
%  Requirements: 8.3
class_occurrence_prob(_, 0.99).

%% combine_probabilities(+Probabilities, -Total)
%  Combine individual probabilities using product rule for independent events
%  P(A and B and C) = P(A) * P(B) * P(C)
%  @param Probabilities List of individual probabilities
%  @param Total Combined probability
%  Requirements: 8.5
combine_probabilities([], 1.0).
combine_probabilities([P|Rest], Total) :-
    combine_probabilities(Rest, RestTotal),
    Total is P * RestTotal.

%% conditional_reliability(+Matrix, +TeacherID, -ConditionalProb)
%  Calculate conditional probability: P(Schedule valid | Teacher T unavailable)
%  If teacher unavailable, all their sessions fail (probability = 0)
%  @param Matrix The timetable matrix
%  @param TeacherID Teacher identifier
%  @param ConditionalProb Conditional reliability score
%  Requirements: 8.6
conditional_reliability(Matrix, TeacherID, ConditionalProb) :-
    get_all_assignments(Matrix, Assignments),
    findall(A, (member(A, Assignments), assignment_teacher(A, TeacherID)), TeacherAssignments),
    findall(A, (member(A, Assignments), \+ assignment_teacher(A, TeacherID)), OtherAssignments),
    length(TeacherAssignments, NumTeacherSessions),
    calculate_assignment_reliabilities(OtherAssignments, OtherProbs),
    combine_probabilities(OtherProbs, OtherReliability),
    % If teacher unavailable, their sessions fail (prob = 0)
    % 0^N = 0 for N > 0, so conditional probability is 0 if teacher has sessions
    (NumTeacherSessions > 0 -> ConditionalProb = 0.0 ; ConditionalProb = OtherReliability).

%% assignment_teacher(+Assignment, +TeacherID)
%  Helper predicate to check if an assignment belongs to a specific teacher
%  @param Assignment Assignment structure
%  @param TeacherID Teacher identifier
assignment_teacher(assigned(_, _, _, TeacherID, _), TeacherID).

%% bayesian_reliability(+Matrix, +Evidence, -PosteriorProb)
%  Calculate reliability using Bayesian inference
%  P(Schedule valid | Evidence) = P(Evidence | Schedule valid) * P(Schedule valid) / P(Evidence)
%  @param Matrix The timetable matrix
%  @param Evidence Evidence structure (e.g., evidence(teacher_absent, TeacherID))
%  @param PosteriorProb Posterior probability given evidence
%  Requirements: 8.6
bayesian_reliability(Matrix, Evidence, PosteriorProb) :-
    schedule_reliability(Matrix, PriorProb),
    likelihood(Evidence, Matrix, Likelihood),
    evidence_probability(Evidence, PEvidence),
    PosteriorProb is (Likelihood * PriorProb) / PEvidence.

%% likelihood(+Evidence, +Matrix, -Likelihood)
%  Calculate P(Evidence | Schedule valid)
%  @param Evidence Evidence structure
%  @param Matrix The timetable matrix
%  @param Likelihood Likelihood probability
likelihood(evidence(teacher_absent, TeacherID), _Matrix, Likelihood) :-
    % Probability that teacher is absent given schedule is valid
    teacher_availability_prob(TeacherID, AvailProb),
    Likelihood is 1.0 - AvailProb.  % P(absent) = 1 - P(available)

likelihood(evidence(room_maintenance, RoomID), _, Likelihood) :-
    % Probability that room is under maintenance
    room_availability_prob(RoomID, AvailProb),
    Likelihood is 1.0 - AvailProb.  % P(maintenance) = 1 - P(available)

likelihood(evidence(class_cancelled, ClassID), _, Likelihood) :-
    % Probability that class is cancelled
    class_occurrence_prob(ClassID, OccurProb),
    Likelihood is 1.0 - OccurProb.  % P(cancelled) = 1 - P(occurs)

%% evidence_probability(+Evidence, -PEvidence)
%  Calculate P(Evidence) - marginal probability of evidence
%  @param Evidence Evidence structure
%  @param PEvidence Marginal probability
evidence_probability(evidence(teacher_absent, TeacherID), PEvidence) :-
    teacher_availability_prob(TeacherID, AvailProb),
    PEvidence is 1.0 - AvailProb.

evidence_probability(evidence(room_maintenance, RoomID), PEvidence) :-
    room_availability_prob(RoomID, AvailProb),
    PEvidence is 1.0 - AvailProb.

evidence_probability(evidence(class_cancelled, ClassID), PEvidence) :-
    class_occurrence_prob(ClassID, OccurProb),
    PEvidence is 1.0 - OccurProb.

%% expected_disruptions(+Matrix, -ExpectedCount)
%  Calculate expected number of disruptions (failed sessions)
%  ExpectedCount = Total sessions * (1 - Reliability)
%  @param Matrix The timetable matrix
%  @param ExpectedCount Expected number of disruptions
%  Requirements: 8.6
expected_disruptions(Matrix, ExpectedCount) :-
    get_all_assignments(Matrix, Assignments),
    length(Assignments, Total),
    schedule_reliability(Matrix, Reliability),
    ExpectedCount is Total * (1.0 - Reliability).

%% risk_category(+Reliability, -Category)
%  Classify reliability score into risk categories
%  - low: >= 0.95 (95% or higher)
%  - medium: >= 0.85 (85% to 94.9%)
%  - high: >= 0.70 (70% to 84.9%)
%  - critical: < 0.70 (below 70%)
%  @param Reliability Reliability score (0.0 to 1.0)
%  @param Category Risk category (low/medium/high/critical)
%  Requirements: 8.6
risk_category(Reliability, Category) :-
    (   Reliability >= 0.95 -> Category = low
    ;   Reliability >= 0.85 -> Category = medium
    ;   Reliability >= 0.70 -> Category = high
    ;   Category = critical
    ).
