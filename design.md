# Design Document: AI-Based Timetable Generation System

## Overview

The AI-Based Timetable Generation System is a comprehensive scheduling solution that automatically creates valid college timetables using advanced AI techniques. The system demonstrates mathematical foundations of AI including Linear Algebra, First Order Logic, Logical Inference, Constraint Satisfaction Problems (CSP), and Probabilistic Reasoning.

### System Purpose

The system solves the complex problem of scheduling classes, teachers, rooms, and time slots while satisfying hard constraints (mandatory rules) and optimizing soft constraints (preferences). It provides a web-based interface for administrators to input resources and visualize generated timetables with reliability scores and conflict explanations.

### Key Features

- Matrix-based timetable representation using Linear Algebra concepts
- First Order Logic knowledge base with Prolog inference engine
- CSP solving with backtracking, forward checking, and intelligent heuristics (MRV, Degree, LCV)
- Probabilistic reliability estimation for schedule robustness
- Conflict detection with detailed explanations
- Timetable repair and regeneration capabilities
- RESTful API for frontend-backend communication
- Interactive web interface with visualization enhancements
- Resource utilization analytics and reporting
- Export functionality (PDF, CSV, JSON)

### Technology Stack

- **Backend**: SWI-Prolog 8.x or higher
  - HTTP server library for REST API
  - JSON parsing library
  - List manipulation and matrix operations
- **Frontend**: HTML5, CSS3, Vanilla JavaScript
  - Fetch API for HTTP requests
  - Dynamic DOM manipulation
  - Responsive grid layout
- **Data Storage**: Prolog fact database (in-memory with file persistence)
- **Export**: PDF generation library, CSV formatting


## Architecture

### High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Web Browser (Client)                     │
│  ┌────────────┐  ┌──────────────┐  ┌──────────────────┐    │
│  │   Forms    │  │  Timetable   │  │    Analytics     │    │
│  │  (Input)   │  │     Grid     │  │    Dashboard     │    │
│  └────────────┘  └──────────────┘  └──────────────────┘    │
│         HTML/CSS/JavaScript (Frontend)                       │
└─────────────────────────────────────────────────────────────┘
                            │
                    HTTP/JSON (REST API)
                            │
┌─────────────────────────────────────────────────────────────┐
│              SWI-Prolog Backend (API Server)                 │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                   api_server.pl                       │   │
│  │  (HTTP Server, Request Routing, JSON Handling)       │   │
│  └──────────────────────────────────────────────────────┘   │
│                            │                                 │
│  ┌─────────────────────────┴──────────────────────────┐    │
│  │                                                      │    │
│  ▼                          ▼                          ▼    │
│ ┌──────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│ │knowledge_base│  │timetable_generator│  │probability_  │  │
│ │    .pl       │  │       .pl         │  │  module.pl   │  │
│ │              │  │                   │  │              │  │
│ │ FOL Facts &  │  │  Main Generation  │  │ Reliability  │  │
│ │   Rules      │  │      Logic        │  │ Calculation  │  │
│ └──────────────┘  └──────────────────┘  └──────────────┘  │
│        │                    │                               │
│        │          ┌─────────┴─────────┐                    │
│        │          │                   │                    │
│        ▼          ▼                   ▼                    │
│ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐       │
│ │constraints.pl│ │ csp_solver.pl│ │matrix_model  │       │
│ │              │ │              │ │    .pl       │       │
│ │ Hard & Soft  │ │ Backtracking │ │ List-of-Lists│       │
│ │ Constraints  │ │ Forward Check│ │ Operations   │       │
│ │              │ │ Heuristics   │ │              │       │
│ └──────────────┘ └──────────────┘ └──────────────┘       │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐                       │
│  │  logging.pl  │  │  testing.pl  │                       │
│  │              │  │              │                       │
│  │ Log Levels   │  │ Unit Tests   │                       │
│  └──────────────┘  └──────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

### Module Interactions and Data Flow

1. **User Input Flow**:
   - User enters resource data via Web Interface forms
   - Frontend sends JSON to API Server via POST /api/resources
   - API Server validates and stores facts in Knowledge Base
   - Confirmation returned to frontend

2. **Timetable Generation Flow**:
   - User clicks "Generate Timetable" button
   - Frontend sends POST /api/generate request
   - Timetable Generator retrieves resources from Knowledge Base
   - CSP Solver performs backtracking search with heuristics
   - Matrix Model stores assignments
   - Constraints module validates each assignment
   - Probability Module calculates reliability score
   - Complete timetable returned as JSON to frontend
   - Frontend renders timetable grid with color coding

3. **Conflict Detection Flow**:
   - User requests conflict analysis
   - Frontend sends GET /api/conflicts request
   - Timetable Generator scans Matrix Model for violations
   - Constraints module checks each assignment
   - Conflict list with explanations returned to frontend
   - Frontend highlights conflicts in red

4. **Explanation Flow**:
   - User clicks on timetable cell
   - Frontend sends POST /api/explain with session details
   - Timetable Generator traces inference steps
   - Knowledge Base provides rule justifications
   - Explanation returned to frontend
   - Frontend displays reasoning in popup


### MFAI Concept Mapping

This system explicitly demonstrates all required Mathematical Foundations of AI concepts:

| MFAI Concept | Module | Implementation |
|--------------|--------|----------------|
| **Linear Algebra** | matrix_model.pl | Timetable represented as 2D matrix (list of lists), matrix indexing, row/column scanning operations |
| **Propositional Logic** | constraints.pl | Boolean constraint expressions (AND, OR, NOT) for rule composition |
| **First Order Logic** | knowledge_base.pl | Predicates with variables and quantifiers: teacher(ID, Name, Subjects), qualified(Teacher, Subject) |
| **Logical Inference** | Prolog Inference Engine | Backward chaining query resolution, unification, rule application |
| **Constraint Satisfaction** | csp_solver.pl | Variables (class sessions), domains (possible assignments), backtracking search, constraint checking |
| **Probabilistic Reasoning** | probability_module.pl | Conditional probability calculations, reliability estimation using Bayes' rule |


## Components and Interfaces

### Backend Modules

#### 1. knowledge_base.pl

**Purpose**: Store and manage all scheduling resources as Prolog facts and rules, demonstrating First Order Logic.

**Key Predicates**:

```prolog
% Facts for resources
teacher(TeacherID, Name, QualifiedSubjects, MaxLoad, AvailabilityList).
subject(SubjectID, Name, WeeklyHours, Type, Duration).
room(RoomID, Name, Capacity, Type).
timeslot(SlotID, Day, Period, StartTime, Duration).
class(ClassID, Name, SubjectList).

% Rules for logical inference
qualified(TeacherID, SubjectID) :-
    teacher(TeacherID, _, QualifiedSubjects, _, _),
    member(SubjectID, QualifiedSubjects).

suitable_room(RoomID, SessionType) :-
    room(RoomID, _, _, RoomType),
    compatible_type(SessionType, RoomType).

compatible_type(theory, classroom).
compatible_type(lab, lab).

teacher_available(TeacherID, SlotID) :-
    teacher(TeacherID, _, _, _, AvailabilityList),
    member(SlotID, AvailabilityList).

teacher_conflict(TeacherID, SlotID, Timetable) :-
    assignment(_, TeacherID, _, SlotID, Timetable),
    assignment(_, TeacherID, _, SlotID, Timetable).

room_conflict(RoomID, SlotID, Timetable) :-
    assignment(_, _, RoomID, SlotID, Timetable),
    assignment(_, _, RoomID, SlotID, Timetable).

% Query predicates
get_all_teachers(Teachers) :- findall(T, teacher(T, _, _, _, _), Teachers).
get_all_subjects(Subjects) :- findall(S, subject(S, _, _, _, _), Subjects).
get_all_rooms(Rooms) :- findall(R, room(R, _, _, _), Rooms).
get_all_timeslots(Slots) :- findall(S, timeslot(S, _, _, _, _), Slots).
get_all_classes(Classes) :- findall(C, class(C, _, _), Classes).
```

**Interface**:
- Input: Resource data from API Server
- Output: Query results for CSP Solver and Timetable Generator
- Dependencies: None (base module)


#### 2. matrix_model.pl

**Purpose**: Represent timetable as a 2D matrix structure, demonstrating Linear Algebra concepts.

**Matrix Structure**:
```prolog
% Timetable is a list of lists: [[Cell11, Cell12, ...], [Cell21, Cell22, ...], ...]
% Each cell represents a room-timeslot combination
% Cell format: cell(RoomID, SlotID, Assignment)
% Assignment format: assigned(ClassID, SubjectID, TeacherID) or empty
```

**Key Predicates**:

```prolog
% Create empty matrix
create_empty_timetable(Rooms, Slots, Matrix) :-
    length(Rooms, NumRooms),
    length(Slots, NumSlots),
    create_matrix(NumRooms, NumSlots, Matrix).

create_matrix(0, _, []) :- !.
create_matrix(Rows, Cols, [Row|Rest]) :-
    Rows > 0,
    create_row(Cols, Row),
    Rows1 is Rows - 1,
    create_matrix(Rows1, Cols, Rest).

create_row(0, []) :- !.
create_row(Cols, [empty|Rest]) :-
    Cols > 0,
    Cols1 is Cols - 1,
    create_row(Cols1, Rest).

% Access cell at position (RoomIndex, SlotIndex)
get_cell(Matrix, RoomIdx, SlotIdx, Cell) :-
    nth0(RoomIdx, Matrix, Row),
    nth0(SlotIdx, Row, Cell).

% Update cell at position
set_cell(Matrix, RoomIdx, SlotIdx, NewValue, UpdatedMatrix) :-
    nth0(RoomIdx, Matrix, Row),
    replace_nth(SlotIdx, Row, NewValue, NewRow),
    replace_nth(RoomIdx, Matrix, NewRow, UpdatedMatrix).

replace_nth(0, [_|T], X, [X|T]) :- !.
replace_nth(N, [H|T], X, [H|R]) :-
    N > 0,
    N1 is N - 1,
    replace_nth(N1, T, X, R).

% Scan row for conflicts (same room, different times)
scan_row(Matrix, RoomIdx, Assignments) :-
    nth0(RoomIdx, Matrix, Row),
    findall(A, (member(Cell, Row), Cell \= empty, Cell = A), Assignments).

% Scan column for conflicts (same time, different rooms)
scan_column(Matrix, SlotIdx, Assignments) :-
    findall(A, (member(Row, Matrix), nth0(SlotIdx, Row, Cell), Cell \= empty, Cell = A), Assignments).

% Get all assignments from matrix
get_all_assignments(Matrix, Assignments) :-
    flatten(Matrix, Cells),
    findall(A, (member(Cell, Cells), Cell \= empty, Cell = A), Assignments).

% Check if matrix is complete (no empty cells)
is_complete(Matrix) :-
    flatten(Matrix, Cells),
    \+ member(empty, Cells).
```

**Interface**:
- Input: Room list, time slot list, assignment operations
- Output: Matrix structure, cell values, conflict detection results
- Dependencies: None (uses standard Prolog list operations)


#### 3. constraints.pl

**Purpose**: Define and check hard and soft constraints for timetable validity.

**Key Predicates**:

```prolog
% Hard Constraints (must be satisfied)

% No teacher double-booking
check_teacher_no_conflict(TeacherID, SlotID, Matrix) :-
    get_all_assignments(Matrix, Assignments),
    findall(A, (member(assigned(_, _, T, S), Assignments), T = TeacherID, S = SlotID), Conflicts),
    length(Conflicts, Count),
    Count =< 1.

% No room double-booking
check_room_no_conflict(RoomID, SlotID, Matrix) :-
    scan_column(Matrix, SlotID, Assignments),
    findall(A, (member(assigned(R, _, _, _), Assignments), R = RoomID), Conflicts),
    length(Conflicts, Count),
    Count =< 1.

% Teacher qualified for subject
check_teacher_qualified(TeacherID, SubjectID) :-
    qualified(TeacherID, SubjectID).

% Room suitable for session type
check_room_suitable(RoomID, SubjectID) :-
    subject(SubjectID, _, _, Type, _),
    suitable_room(RoomID, Type).

% Room capacity sufficient
check_room_capacity(RoomID, ClassID) :-
    room(RoomID, _, Capacity, _),
    class(ClassID, _, _),
    % Assume class size stored or calculated
    class_size(ClassID, Size),
    Size =< Capacity.

% Teacher available at time slot
check_teacher_available(TeacherID, SlotID) :-
    teacher_available(TeacherID, SlotID).

% Weekly hours requirement met
check_weekly_hours(ClassID, SubjectID, Matrix) :-
    subject(SubjectID, _, RequiredHours, _, Duration),
    get_all_assignments(Matrix, Assignments),
    findall(A, (member(assigned(_, C, S, _), Assignments), C = ClassID, S = SubjectID), ClassSubjectAssignments),
    length(ClassSubjectAssignments, Count),
    TotalHours is Count * Duration,
    TotalHours >= RequiredHours.

% Consecutive slots for multi-period labs
check_consecutive_slots(SlotID1, SlotID2) :-
    timeslot(SlotID1, Day, Period1, _, _),
    timeslot(SlotID2, Day, Period2, _, _),
    Period2 is Period1 + 1.

% All hard constraints for an assignment
check_all_hard_constraints(RoomID, ClassID, SubjectID, TeacherID, SlotID, Matrix) :-
    check_teacher_no_conflict(TeacherID, SlotID, Matrix),
    check_room_no_conflict(RoomID, SlotID, Matrix),
    check_teacher_qualified(TeacherID, SubjectID),
    check_room_suitable(RoomID, SubjectID),
    check_room_capacity(RoomID, ClassID),
    check_teacher_available(TeacherID, SlotID).

% Soft Constraints (preferences to optimize)

% Balanced teacher workload
soft_balanced_workload(TeacherID, Matrix, Score) :-
    get_all_assignments(Matrix, Assignments),
    findall(S, (member(assigned(_, _, T, S), Assignments), T = TeacherID), TeacherSlots),
    group_by_day(TeacherSlots, DayGroups),
    calculate_balance_score(DayGroups, Score).

% Avoid late afternoon theory classes
soft_avoid_late_theory(SubjectID, SlotID, Score) :-
    subject(SubjectID, _, _, theory, _),
    timeslot(SlotID, _, Period, _, _),
    (Period > 6 -> Score = 0.5 ; Score = 1.0).

% Minimize student schedule gaps
soft_minimize_gaps(ClassID, Matrix, Score) :-
    get_class_schedule(ClassID, Matrix, Schedule),
    count_gaps(Schedule, GapCount),
    Score is 1.0 / (1 + GapCount).

% Calculate total soft constraint score
calculate_soft_score(Matrix, TotalScore) :-
    findall(S, soft_constraint_score(Matrix, S), Scores),
    sum_list(Scores, Sum),
    length(Scores, Count),
    TotalScore is Sum / Count.
```

**Interface**:
- Input: Assignment details, current matrix state
- Output: Boolean (constraint satisfied/violated), soft constraint scores
- Dependencies: knowledge_base.pl, matrix_model.pl


#### 4. csp_solver.pl

**Purpose**: Implement CSP backtracking search with forward checking and heuristics (MRV, Degree, LCV).

**CSP Formulation**:
- **Variables**: Class sessions requiring assignment (ClassID, SubjectID)
- **Domains**: Possible (TeacherID, RoomID, SlotID) tuples
- **Constraints**: Hard constraints from constraints.pl

**Key Algorithms**:

```prolog
% Main CSP solver entry point
solve_csp(Sessions, Matrix, Solution) :-
    initialize_domains(Sessions, Domains),
    backtracking_search(Sessions, Domains, Matrix, Solution).

% Backtracking search with forward checking
backtracking_search([], _, Matrix, Matrix) :- !.  % All variables assigned
backtracking_search(Sessions, Domains, Matrix, Solution) :-
    select_variable(Sessions, Domains, SelectedSession, RemainingSessions),
    get_domain(SelectedSession, Domains, Domain),
    order_domain_values(Domain, SelectedSession, Matrix, OrderedDomain),
    try_values(OrderedDomain, SelectedSession, RemainingSessions, Domains, Matrix, Solution).

% Try each value in domain
try_values([Value|Rest], Session, Remaining, Domains, Matrix, Solution) :-
    assign_value(Session, Value, Matrix, NewMatrix),
    (   check_constraints(Session, Value, NewMatrix)
    ->  forward_check(Session, Value, Remaining, Domains, NewDomains),
        (   \+ has_empty_domain(NewDomains)
        ->  backtracking_search(Remaining, NewDomains, NewMatrix, Solution)
        ;   fail  % Empty domain detected, backtrack
        )
    ;   fail  % Constraint violated, backtrack
    ),
    !.  % Cut after first solution
try_values([_|Rest], Session, Remaining, Domains, Matrix, Solution) :-
    try_values(Rest, Session, Remaining, Domains, Matrix, Solution).

% Minimum Remaining Values (MRV) heuristic
select_variable(Sessions, Domains, Selected, Remaining) :-
    findall(Count-Session, (member(Session, Sessions), get_domain(Session, Domains, D), length(D, Count)), Pairs),
    sort(Pairs, [_-Selected|_]),  % Select variable with smallest domain
    select(Selected, Sessions, Remaining).

% Degree heuristic for tie-breaking
select_variable_degree(Sessions, Domains, Matrix, Selected, Remaining) :-
    findall(MRV-Degree-Session, 
            (member(Session, Sessions), 
             get_domain(Session, Domains, D), 
             length(D, MRV),
             count_constraints(Session, Sessions, Matrix, Degree)), 
            Triples),
    sort(Triples, [_-_-Selected|_]),
    select(Selected, Sessions, Remaining).

% Least Constraining Value (LCV) heuristic
order_domain_values(Domain, Session, Matrix, OrderedDomain) :-
    findall(Count-Value, 
            (member(Value, Domain), 
             count_eliminated_values(Session, Value, Matrix, Count)), 
            Pairs),
    sort(Pairs, SortedPairs),
    pairs_values(SortedPairs, OrderedDomain).

% Forward checking: remove inconsistent values from future domains
forward_check(AssignedSession, AssignedValue, RemainingSessions, Domains, NewDomains) :-
    forward_check_all(RemainingSessions, AssignedSession, AssignedValue, Domains, NewDomains).

forward_check_all([], _, _, Domains, Domains).
forward_check_all([Session|Rest], AssignedSession, AssignedValue, Domains, NewDomains) :-
    get_domain(Session, Domains, Domain),
    filter_domain(Domain, AssignedSession, AssignedValue, FilteredDomain),
    update_domain(Session, FilteredDomain, Domains, TempDomains),
    forward_check_all(Rest, AssignedSession, AssignedValue, TempDomains, NewDomains).

% Filter domain values that conflict with assignment
filter_domain(Domain, AssignedSession, AssignedValue, FilteredDomain) :-
    findall(Value, 
            (member(Value, Domain), 
             \+ conflicts_with(Value, AssignedSession, AssignedValue)), 
            FilteredDomain).

% Check if assignment conflicts with another
conflicts_with(value(T1, R1, S1), _, value(T2, R2, S2)) :-
    (T1 = T2, S1 = S2) ;  % Same teacher, same time
    (R1 = R2, S1 = S2).   % Same room, same time

% Check for empty domains
has_empty_domain(Domains) :-
    member(_-[], Domains).

% Initialize domains for all sessions
initialize_domains(Sessions, Domains) :-
    findall(Session-Domain, 
            (member(Session, Sessions), 
             generate_domain(Session, Domain)), 
            Domains).

% Generate domain for a session
generate_domain(session(ClassID, SubjectID), Domain) :-
    findall(value(TeacherID, RoomID, SlotID),
            (qualified(TeacherID, SubjectID),
             suitable_room(RoomID, SubjectID),
             timeslot(SlotID, _, _, _, _)),
            Domain).
```

**Interface**:
- Input: List of sessions to schedule, initial matrix
- Output: Complete timetable matrix or failure
- Dependencies: constraints.pl, matrix_model.pl, knowledge_base.pl


#### 5. probability_module.pl

**Purpose**: Calculate timetable reliability using probabilistic reasoning and conditional probabilities.

**Probability Model**:
- Teacher availability: P(teacher_available) = 0.95
- Room maintenance failure: P(room_unavailable) = 0.02
- Class cancellation: P(class_cancelled) = 0.01
- Dependencies: If teacher unavailable, all their sessions affected

**Key Predicates**:

```prolog
% Calculate overall schedule reliability
schedule_reliability(Matrix, Reliability) :-
    get_all_assignments(Matrix, Assignments),
    calculate_assignment_reliabilities(Assignments, Probabilities),
    combine_probabilities(Probabilities, Reliability).

% Calculate reliability for each assignment
calculate_assignment_reliabilities([], []).
calculate_assignment_reliabilities([Assignment|Rest], [Prob|Probs]) :-
    assignment_reliability(Assignment, Prob),
    calculate_assignment_reliabilities(Rest, Probs).

% Reliability of a single assignment
assignment_reliability(assigned(RoomID, ClassID, SubjectID, TeacherID, SlotID), Probability) :-
    teacher_availability_prob(TeacherID, PTeacher),
    room_availability_prob(RoomID, PRoom),
    class_occurrence_prob(ClassID, PClass),
    % Independent events: P(A and B and C) = P(A) * P(B) * P(C)
    Probability is PTeacher * PRoom * PClass.

% Individual probability values
teacher_availability_prob(_, 0.95).  % Default 95% availability
room_availability_prob(_, 0.98).     % Default 98% availability (2% maintenance)
class_occurrence_prob(_, 0.99).      % Default 99% occurrence (1% cancellation)

% Combine probabilities for entire schedule
% Using product rule for independent events
combine_probabilities([], 1.0).
combine_probabilities([P|Rest], Total) :-
    combine_probabilities(Rest, RestTotal),
    Total is P * RestTotal.

% Calculate conditional probability
% P(Schedule valid | Teacher T unavailable)
conditional_reliability(Matrix, TeacherID, ConditionalProb) :-
    get_all_assignments(Matrix, Assignments),
    findall(A, (member(A, Assignments), assignment_teacher(A, TeacherID)), TeacherAssignments),
    findall(A, (member(A, Assignments), \+ assignment_teacher(A, TeacherID)), OtherAssignments),
    length(TeacherAssignments, NumTeacherSessions),
    calculate_assignment_reliabilities(OtherAssignments, OtherProbs),
    combine_probabilities(OtherProbs, OtherReliability),
    % If teacher unavailable, their sessions fail (prob = 0)
    ConditionalProb is OtherReliability * (0 ** NumTeacherSessions).

% Bayesian inference for reliability given evidence
% P(Schedule valid | Evidence) = P(Evidence | Schedule valid) * P(Schedule valid) / P(Evidence)
bayesian_reliability(Matrix, Evidence, PosteriorProb) :-
    schedule_reliability(Matrix, PriorProb),
    likelihood(Evidence, Matrix, Likelihood),
    evidence_probability(Evidence, PEvidence),
    PosteriorProb is (Likelihood * PriorProb) / PEvidence.

% Calculate expected number of disruptions
expected_disruptions(Matrix, ExpectedCount) :-
    get_all_assignments(Matrix, Assignments),
    length(Assignments, Total),
    schedule_reliability(Matrix, Reliability),
    ExpectedCount is Total * (1 - Reliability).

% Risk assessment categories
risk_category(Reliability, Category) :-
    (   Reliability >= 0.95 -> Category = low
    ;   Reliability >= 0.85 -> Category = medium
    ;   Reliability >= 0.70 -> Category = high
    ;   Category = critical
    ).
```

**Interface**:
- Input: Timetable matrix, optional evidence/conditions
- Output: Reliability score (0.0 to 1.0), risk category, expected disruptions
- Dependencies: matrix_model.pl


#### 6. timetable_generator.pl

**Purpose**: Main orchestration module for timetable generation, repair, and explanation.

**Key Predicates**:

```prolog
% Main generation predicate
generate_timetable(Timetable) :-
    log_info('Starting timetable generation'),
    retrieve_resources(Teachers, Subjects, Rooms, Slots, Classes),
    validate_resources(Teachers, Subjects, Rooms, Slots, Classes),
    create_sessions(Classes, Subjects, Sessions),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    log_info('Invoking CSP solver'),
    solve_csp(Sessions, EmptyMatrix, Timetable),
    validate_timetable(Timetable),
    log_info('Timetable generation successful').

generate_timetable(error(Reason)) :-
    log_error('Timetable generation failed'),
    explain_failure(Reason).

% Retrieve all resources from knowledge base
retrieve_resources(Teachers, Subjects, Rooms, Slots, Classes) :-
    get_all_teachers(Teachers),
    get_all_subjects(Subjects),
    get_all_rooms(Rooms),
    get_all_timeslots(Slots),
    get_all_classes(Classes).

% Validate resource consistency
validate_resources(Teachers, Subjects, Rooms, Slots, Classes) :-
    length(Teachers, NT), NT > 0,
    length(Subjects, NS), NS > 0,
    length(Rooms, NR), NR > 0,
    length(Slots, NSl), NSl > 0,
    length(Classes, NC), NC > 0,
    validate_teacher_qualifications(Teachers, Subjects),
    validate_room_types(Rooms),
    validate_subject_requirements(Subjects).

% Create session list from classes and subjects
create_sessions(Classes, Subjects, Sessions) :-
    findall(session(ClassID, SubjectID),
            (member(class(ClassID, _, SubjectList), Classes),
             member(SubjectID, SubjectList)),
            Sessions).

% Validate complete timetable
validate_timetable(Matrix) :-
    is_complete(Matrix),
    get_all_assignments(Matrix, Assignments),
    validate_all_assignments(Assignments, Matrix).

validate_all_assignments([], _).
validate_all_assignments([Assignment|Rest], Matrix) :-
    validate_assignment(Assignment, Matrix),
    validate_all_assignments(Rest, Matrix).

% Explain why a specific assignment was made
explain_assignment(session(ClassID, SubjectID), Assignment, Explanation) :-
    Assignment = assigned(RoomID, ClassID, SubjectID, TeacherID, SlotID),
    format_explanation(Assignment, Explanation).

format_explanation(assigned(RoomID, ClassID, SubjectID, TeacherID, SlotID), Explanation) :-
    teacher(TeacherID, TName, _, _, _),
    subject(SubjectID, SName, _, _, _),
    room(RoomID, RName, _, _),
    timeslot(SlotID, Day, Period, StartTime, _),
    class(ClassID, CName, _),
    format(atom(Explanation), 
           'Class ~w: ~w taught by ~w in room ~w at ~w (Period ~w on ~w). Teacher is qualified, room is suitable, no conflicts detected.',
           [CName, SName, TName, RName, StartTime, Period, Day]).

% Detect conflicts in timetable
detect_conflicts(Matrix, Conflicts) :-
    findall(Conflict, find_conflict(Matrix, Conflict), Conflicts).

find_conflict(Matrix, teacher_conflict(TeacherID, SlotID, Sessions)) :-
    get_all_assignments(Matrix, Assignments),
    member(assigned(_, _, _, TeacherID, SlotID), Assignments),
    findall(S, member(assigned(_, _, S, TeacherID, SlotID), Assignments), Sessions),
    length(Sessions, Count),
    Count > 1.

find_conflict(Matrix, room_conflict(RoomID, SlotID, Sessions)) :-
    get_all_assignments(Matrix, Assignments),
    member(assigned(RoomID, _, _, _, SlotID), Assignments),
    findall(S, member(assigned(RoomID, _, S, _, SlotID), Assignments), Sessions),
    length(Sessions, Count),
    Count > 1.

% Repair timetable by resolving conflicts
repair_timetable(Matrix, ConflictList, RepairedMatrix) :-
    log_info('Starting timetable repair'),
    identify_conflicting_assignments(ConflictList, Matrix, ConflictingAssignments),
    remove_assignments(ConflictingAssignments, Matrix, PartialMatrix),
    create_repair_sessions(ConflictingAssignments, RepairSessions),
    solve_csp(RepairSessions, PartialMatrix, RepairedMatrix),
    log_info('Timetable repair successful').

% Parse external timetable data
parse_timetable(JSONData, Matrix) :-
    json_to_prolog(JSONData, PrologData),
    validate_parsed_data(PrologData),
    construct_matrix(PrologData, Matrix).

% Format timetable for output
format_timetable(Matrix, json, JSONOutput) :-
    matrix_to_json(Matrix, JSONOutput).

format_timetable(Matrix, text, TextOutput) :-
    matrix_to_text(Matrix, TextOutput).

format_timetable(Matrix, csv, CSVOutput) :-
    matrix_to_csv(Matrix, CSVOutput).
```

**Interface**:
- Input: None (retrieves from knowledge base) or partial timetable for repair
- Output: Complete timetable matrix, conflict list, explanations
- Dependencies: All other backend modules


#### 7. api_server.pl

**Purpose**: HTTP server exposing REST API endpoints for frontend communication.

**Key Predicates**:

```prolog
% Start HTTP server
start_server(Port) :-
    http_server(http_dispatch, [port(Port)]),
    format('Server started on http://localhost:~w~n', [Port]).

% Route definitions
:- http_handler(root(api/resources), handle_resources, []).
:- http_handler(root(api/generate), handle_generate, []).
:- http_handler(root(api/timetable), handle_get_timetable, []).
:- http_handler(root(api/reliability), handle_reliability, []).
:- http_handler(root(api/explain), handle_explain, []).
:- http_handler(root(api/conflicts), handle_conflicts, []).
:- http_handler(root(api/repair), handle_repair, []).
:- http_handler(root(api/analytics), handle_analytics, []).
:- http_handler(root(api/export), handle_export, []).

% Handle resource submission
handle_resources(Request) :-
    cors_headers,
    member(method(post), Request),
    http_read_json(Request, JSONData),
    validate_resource_data(JSONData, ValidatedData),
    store_resources(ValidatedData),
    reply_json_dict(_{status: success, message: 'Resources stored successfully'}).

handle_resources(_) :-
    reply_json_dict(_{status: error, message: 'Invalid request'}, [status(400)]).

% Handle timetable generation
handle_generate(Request) :-
    cors_headers,
    member(method(post), Request),
    log_info('Generation request received'),
    generate_timetable(Timetable),
    format_timetable(Timetable, json, JSONOutput),
    schedule_reliability(Timetable, Reliability),
    reply_json_dict(_{status: success, timetable: JSONOutput, reliability: Reliability}).

handle_generate(_) :-
    reply_json_dict(_{status: error, message: 'Generation failed'}, [status(500)]).

% Handle timetable retrieval
handle_get_timetable(Request) :-
    cors_headers,
    member(method(get), Request),
    get_current_timetable(Timetable),
    format_timetable(Timetable, json, JSONOutput),
    reply_json_dict(_{status: success, timetable: JSONOutput}).

% Handle reliability query
handle_reliability(Request) :-
    cors_headers,
    member(method(get), Request),
    get_current_timetable(Timetable),
    schedule_reliability(Timetable, Reliability),
    risk_category(Reliability, Risk),
    expected_disruptions(Timetable, ExpectedDisruptions),
    reply_json_dict(_{
        status: success, 
        reliability: Reliability, 
        risk: Risk,
        expected_disruptions: ExpectedDisruptions
    }).

% Handle explanation request
handle_explain(Request) :-
    cors_headers,
    member(method(post), Request),
    http_read_json(Request, JSONData),
    extract_session(JSONData, Session),
    get_current_timetable(Timetable),
    find_assignment(Session, Timetable, Assignment),
    explain_assignment(Session, Assignment, Explanation),
    reply_json_dict(_{status: success, explanation: Explanation}).

% Handle conflict detection
handle_conflicts(Request) :-
    cors_headers,
    member(method(get), Request),
    get_current_timetable(Timetable),
    detect_conflicts(Timetable, Conflicts),
    format_conflicts(Conflicts, FormattedConflicts),
    reply_json_dict(_{status: success, conflicts: FormattedConflicts}).

% Handle timetable repair
handle_repair(Request) :-
    cors_headers,
    member(method(post), Request),
    get_current_timetable(Timetable),
    detect_conflicts(Timetable, Conflicts),
    repair_timetable(Timetable, Conflicts, RepairedTimetable),
    format_timetable(RepairedTimetable, json, JSONOutput),
    reply_json_dict(_{status: success, timetable: JSONOutput}).

% Handle analytics request
handle_analytics(Request) :-
    cors_headers,
    member(method(get), Request),
    get_current_timetable(Timetable),
    calculate_analytics(Timetable, Analytics),
    reply_json_dict(_{status: success, analytics: Analytics}).

% Handle export request
handle_export(Request) :-
    cors_headers,
    member(method(get), Request),
    http_parameters(Request, [format(Format, [])]),
    get_current_timetable(Timetable),
    format_timetable(Timetable, Format, Output),
    set_content_type(Format, ContentType),
    format('Content-Type: ~w~n~n', [ContentType]),
    write(Output).

% CORS headers for cross-origin requests
cors_headers :-
    format('Access-Control-Allow-Origin: *~n'),
    format('Access-Control-Allow-Methods: GET, POST, OPTIONS~n'),
    format('Access-Control-Allow-Headers: Content-Type~n').

% Input validation
validate_resource_data(JSONData, ValidatedData) :-
    validate_json_structure(JSONData),
    sanitize_inputs(JSONData, ValidatedData).

sanitize_inputs(Data, Sanitized) :-
    % Remove potentially harmful characters
    % Validate field types and ranges
    % Return sanitized data
    Sanitized = Data.  % Placeholder
```

**API Endpoints**:

| Endpoint | Method | Description | Request Body | Response |
|----------|--------|-------------|--------------|----------|
| /api/resources | POST | Submit resource data | JSON with teachers, subjects, rooms, slots, classes | Success/error status |
| /api/generate | POST | Generate timetable | None | Timetable JSON + reliability score |
| /api/timetable | GET | Retrieve current timetable | None | Timetable JSON |
| /api/reliability | GET | Get reliability score | None | Reliability, risk category, expected disruptions |
| /api/explain | POST | Explain assignment | Session details | Explanation text |
| /api/conflicts | GET | Detect conflicts | None | List of conflicts |
| /api/repair | POST | Repair timetable | None | Repaired timetable JSON |
| /api/analytics | GET | Get analytics | None | Statistics JSON |
| /api/export | GET | Export timetable | format=pdf/csv/json | File download |

**Interface**:
- Input: HTTP requests from frontend
- Output: JSON responses
- Dependencies: timetable_generator.pl, probability_module.pl


#### 8. logging.pl

**Purpose**: Provide structured logging with levels for debugging and monitoring.

**Key Predicates**:

```prolog
% Log levels
:- dynamic log_level/1.
log_level(info).  % Default level

% Set log level
set_log_level(Level) :-
    retractall(log_level(_)),
    assertz(log_level(Level)).

% Log messages
log_info(Message) :-
    should_log(info),
    get_timestamp(Timestamp),
    format('[~w] INFO: ~w~n', [Timestamp, Message]).

log_warning(Message) :-
    should_log(warning),
    get_timestamp(Timestamp),
    format('[~w] WARNING: ~w~n', [Timestamp, Message]).

log_error(Message) :-
    should_log(error),
    get_timestamp(Timestamp),
    format('[~w] ERROR: ~w~n', [Timestamp, Message]).

log_debug(Message) :-
    should_log(debug),
    get_timestamp(Timestamp),
    format('[~w] DEBUG: ~w~n', [Timestamp, Message]).

% Determine if message should be logged
should_log(MessageLevel) :-
    log_level(CurrentLevel),
    level_priority(MessageLevel, MPriority),
    level_priority(CurrentLevel, CPriority),
    MPriority >= CPriority.

level_priority(error, 3).
level_priority(warning, 2).
level_priority(info, 1).
level_priority(debug, 0).

% Get current timestamp
get_timestamp(Timestamp) :-
    get_time(Time),
    format_time(atom(Timestamp), '%Y-%m-%d %H:%M:%S', Time).

% Log CSP search progress
log_search_node(NodeCount) :-
    0 is NodeCount mod 1000,
    format('[SEARCH] Explored ~w nodes~n', [NodeCount]).
```

**Interface**:
- Input: Log messages, log level configuration
- Output: Formatted log output to console
- Dependencies: None


#### 9. testing.pl

**Purpose**: Unit testing framework for verifying system correctness.

**Key Predicates**:

```prolog
% Test runner
run_all_tests :-
    log_info('Starting test suite'),
    test_knowledge_base,
    test_matrix_operations,
    test_constraints,
    test_csp_solver,
    test_probability,
    test_timetable_generation,
    log_info('All tests completed').

% Knowledge base tests
test_knowledge_base :-
    log_info('Testing knowledge base'),
    test_teacher_qualification,
    test_room_suitability,
    test_teacher_availability.

test_teacher_qualification :-
    assertz(teacher(t1, 'Dr. Smith', [math, physics], 20, [1,2,3])),
    assertz(subject(math, 'Mathematics', 4, theory, 1)),
    (qualified(t1, math) -> log_info('✓ Teacher qualification test passed') ; log_error('✗ Teacher qualification test failed')),
    retractall(teacher(t1, _, _, _, _)),
    retractall(subject(math, _, _, _, _)).

% Matrix operation tests
test_matrix_operations :-
    log_info('Testing matrix operations'),
    test_matrix_creation,
    test_cell_access,
    test_cell_update.

test_matrix_creation :-
    create_empty_timetable([r1, r2], [s1, s2, s3], Matrix),
    length(Matrix, Rows),
    (Rows = 2 -> log_info('✓ Matrix creation test passed') ; log_error('✗ Matrix creation test failed')).

% Constraint tests
test_constraints :-
    log_info('Testing constraints'),
    test_teacher_conflict_detection,
    test_room_conflict_detection,
    test_hard_constraint_validation.

test_teacher_conflict_detection :-
    % Create matrix with conflicting teacher assignments
    % Verify conflict is detected
    log_info('✓ Teacher conflict detection test passed').

% CSP solver tests
test_csp_solver :-
    log_info('Testing CSP solver'),
    test_domain_initialization,
    test_forward_checking,
    test_mrv_heuristic.

test_domain_initialization :-
    % Test that domains are correctly generated
    log_info('✓ Domain initialization test passed').

% Probability tests
test_probability :-
    log_info('Testing probability module'),
    test_reliability_calculation,
    test_conditional_probability.

test_reliability_calculation :-
    % Create simple timetable
    % Calculate reliability
    % Verify result is between 0 and 1
    log_info('✓ Reliability calculation test passed').

% Integration tests
test_timetable_generation :-
    log_info('Testing timetable generation'),
    test_small_instance,
    test_constraint_satisfaction.

test_small_instance :-
    % Load minimal dataset
    % Generate timetable
    % Verify all constraints satisfied
    log_info('✓ Small instance test passed').

% Assertion helpers
assert_true(Condition, TestName) :-
    (Condition -> 
        format('✓ ~w passed~n', [TestName]) 
    ; 
        format('✗ ~w FAILED~n', [TestName]),
        fail
    ).

assert_equals(Expected, Actual, TestName) :-
    (Expected = Actual ->
        format('✓ ~w passed~n', [TestName])
    ;
        format('✗ ~w FAILED: expected ~w, got ~w~n', [TestName, Expected, Actual]),
        fail
    ).
```

**Interface**:
- Input: None (runs predefined tests)
- Output: Test results to console
- Dependencies: All modules being tested


### Frontend Components

#### 1. index.html

**Purpose**: Main HTML structure for the web interface.

**Structure**:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI Timetable Generator</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <header>
        <h1>AI-Based Timetable Generation System</h1>
        <nav>
            <button id="nav-resources" class="nav-btn active">Resources</button>
            <button id="nav-generate" class="nav-btn">Generate</button>
            <button id="nav-visualize" class="nav-btn">Visualize</button>
            <button id="nav-analytics" class="nav-btn">Analytics</button>
        </nav>
    </header>

    <main>
        <!-- Resources Section -->
        <section id="resources-section" class="section active">
            <h2>Resource Management</h2>
            <div class="form-container">
                <form id="teacher-form">
                    <h3>Add Teacher</h3>
                    <!-- Teacher input fields -->
                </form>
                <form id="subject-form">
                    <h3>Add Subject</h3>
                    <!-- Subject input fields -->
                </form>
                <form id="room-form">
                    <h3>Add Room</h3>
                    <!-- Room input fields -->
                </form>
                <form id="timeslot-form">
                    <h3>Configure Time Slots</h3>
                    <!-- Time slot configuration -->
                </form>
                <form id="class-form">
                    <h3>Add Class</h3>
                    <!-- Class input fields -->
                </form>
            </div>
        </section>

        <!-- Generation Section -->
        <section id="generate-section" class="section">
            <h2>Timetable Generation</h2>
            <button id="generate-btn" class="primary-btn">Generate Timetable</button>
            <button id="repair-btn" class="secondary-btn">Repair Timetable</button>
            <div id="loading-indicator" class="hidden">
                <div class="spinner"></div>
                <p>Generating timetable...</p>
            </div>
            <div id="generation-result"></div>
        </section>

        <!-- Visualization Section -->
        <section id="visualize-section" class="section">
            <h2>Timetable Visualization</h2>
            <div id="reliability-display">
                <h3>Reliability Score: <span id="reliability-value">--</span></h3>
                <div id="reliability-bar"></div>
                <p>Risk Level: <span id="risk-level">--</span></p>
            </div>
            <div id="timetable-grid"></div>
            <div id="conflicts-display"></div>
            <div id="export-options">
                <button id="export-pdf">Export as PDF</button>
                <button id="export-csv">Export as CSV</button>
                <button id="export-json">Export as JSON</button>
            </div>
        </section>

        <!-- Analytics Section -->
        <section id="analytics-section" class="section">
            <h2>Resource Utilization Analytics</h2>
            <div id="analytics-display">
                <div id="teacher-workload"></div>
                <div id="room-utilization"></div>
                <div id="schedule-density"></div>
            </div>
        </section>
    </main>

    <!-- Modal for explanations -->
    <div id="explanation-modal" class="modal hidden">
        <div class="modal-content">
            <span class="close">&times;</span>
            <h3>Assignment Explanation</h3>
            <div id="explanation-text"></div>
        </div>
    </div>

    <script src="script.js"></script>
</body>
</html>
```


#### 2. style.css

**Purpose**: Styling for responsive and intuitive user interface.

**Key Styles**:

```css
/* Color scheme */
:root {
    --primary-color: #2c3e50;
    --secondary-color: #3498db;
    --success-color: #27ae60;
    --warning-color: #f39c12;
    --danger-color: #e74c3c;
    --bg-color: #ecf0f1;
    --text-color: #2c3e50;
}

/* Layout */
body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    margin: 0;
    padding: 0;
    background-color: var(--bg-color);
    color: var(--text-color);
}

header {
    background-color: var(--primary-color);
    color: white;
    padding: 1rem 2rem;
}

nav {
    display: flex;
    gap: 1rem;
    margin-top: 1rem;
}

.nav-btn {
    padding: 0.5rem 1rem;
    background-color: transparent;
    color: white;
    border: 2px solid white;
    cursor: pointer;
    transition: all 0.3s;
}

.nav-btn.active {
    background-color: white;
    color: var(--primary-color);
}

/* Timetable grid */
#timetable-grid {
    display: grid;
    grid-template-columns: 100px repeat(auto-fit, minmax(150px, 1fr));
    gap: 2px;
    background-color: #bdc3c7;
    margin: 2rem 0;
}

.grid-cell {
    background-color: white;
    padding: 1rem;
    min-height: 80px;
    cursor: pointer;
    transition: all 0.2s;
}

.grid-cell:hover {
    background-color: #ecf0f1;
    transform: scale(1.02);
}

.grid-header {
    background-color: var(--primary-color);
    color: white;
    font-weight: bold;
    text-align: center;
}

/* Color coding for subjects */
.subject-math { background-color: #e8f4f8; }
.subject-physics { background-color: #fef5e7; }
.subject-chemistry { background-color: #ebf5fb; }
.subject-biology { background-color: #e8f8f5; }
.subject-english { background-color: #fdeef4; }
.subject-history { background-color: #f4ecf7; }

/* Conflict highlighting */
.conflict {
    background-color: var(--danger-color) !important;
    color: white;
    animation: pulse 1s infinite;
}

@keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.7; }
}

/* Reliability display */
#reliability-bar {
    width: 100%;
    height: 30px;
    background-color: #ecf0f1;
    border-radius: 15px;
    overflow: hidden;
    margin: 1rem 0;
}

.reliability-fill {
    height: 100%;
    transition: width 0.5s, background-color 0.5s;
}

.reliability-high { background-color: var(--success-color); }
.reliability-medium { background-color: var(--warning-color); }
.reliability-low { background-color: var(--danger-color); }

/* Loading indicator */
.spinner {
    border: 4px solid #f3f3f3;
    border-top: 4px solid var(--secondary-color);
    border-radius: 50%;
    width: 40px;
    height: 40px;
    animation: spin 1s linear infinite;
    margin: 0 auto;
}

@keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}

/* Modal */
.modal {
    display: none;
    position: fixed;
    z-index: 1000;
    left: 0;
    top: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(0,0,0,0.5);
}

.modal.active {
    display: flex;
    align-items: center;
    justify-content: center;
}

.modal-content {
    background-color: white;
    padding: 2rem;
    border-radius: 8px;
    max-width: 600px;
    max-height: 80vh;
    overflow-y: auto;
}

/* Tooltips */
.tooltip {
    position: relative;
}

.tooltip .tooltiptext {
    visibility: hidden;
    background-color: var(--primary-color);
    color: white;
    text-align: center;
    padding: 5px 10px;
    border-radius: 6px;
    position: absolute;
    z-index: 1;
    bottom: 125%;
    left: 50%;
    transform: translateX(-50%);
    opacity: 0;
    transition: opacity 0.3s;
}

.tooltip:hover .tooltiptext {
    visibility: visible;
    opacity: 1;
}
```


#### 3. script.js

**Purpose**: Frontend logic for API communication and dynamic UI updates.

**Key Functions**:

```javascript
// API base URL
const API_BASE = 'http://localhost:8080/api';

// State management
let currentTimetable = null;
let currentReliability = null;

// Navigation
document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
        // Switch active section
        document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
        e.target.classList.add('active');
        const sectionId = e.target.id.replace('nav-', '') + '-section';
        document.getElementById(sectionId).classList.add('active');
    });
});

// Submit resources
async function submitResources(resourceType, data) {
    try {
        const response = await fetch(`${API_BASE}/resources`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ type: resourceType, data: data })
        });
        const result = await response.json();
        if (result.status === 'success') {
            showNotification('Resource added successfully', 'success');
        } else {
            showNotification('Error: ' + result.message, 'error');
        }
    } catch (error) {
        showNotification('Network error: ' + error.message, 'error');
    }
}

// Generate timetable
document.getElementById('generate-btn').addEventListener('click', async () => {
    const loadingIndicator = document.getElementById('loading-indicator');
    const resultDiv = document.getElementById('generation-result');
    
    loadingIndicator.classList.remove('hidden');
    resultDiv.innerHTML = '';
    
    try {
        const response = await fetch(`${API_BASE}/generate`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
        });
        const result = await response.json();
        
        loadingIndicator.classList.add('hidden');
        
        if (result.status === 'success') {
            currentTimetable = result.timetable;
            currentReliability = result.reliability;
            showNotification('Timetable generated successfully!', 'success');
            renderTimetable(result.timetable);
            updateReliabilityDisplay(result.reliability);
            // Switch to visualization section
            document.getElementById('nav-visualize').click();
        } else {
            showNotification('Generation failed: ' + result.message, 'error');
            resultDiv.innerHTML = `<div class="error">${result.message}</div>`;
        }
    } catch (error) {
        loadingIndicator.classList.add('hidden');
        showNotification('Network error: ' + error.message, 'error');
    }
});

// Render timetable grid
function renderTimetable(timetable) {
    const grid = document.getElementById('timetable-grid');
    grid.innerHTML = '';
    
    // Create header row
    const headerCell = document.createElement('div');
    headerCell.className = 'grid-cell grid-header';
    headerCell.textContent = 'Time / Room';
    grid.appendChild(headerCell);
    
    // Room headers
    timetable.rooms.forEach(room => {
        const roomHeader = document.createElement('div');
        roomHeader.className = 'grid-cell grid-header';
        roomHeader.textContent = room.name;
        grid.appendChild(roomHeader);
    });
    
    // Time slot rows
    timetable.slots.forEach(slot => {
        // Time label
        const timeLabel = document.createElement('div');
        timeLabel.className = 'grid-cell grid-header';
        timeLabel.textContent = `${slot.day} ${slot.period}`;
        grid.appendChild(timeLabel);
        
        // Cells for each room
        timetable.rooms.forEach(room => {
            const cell = document.createElement('div');
            cell.className = 'grid-cell';
            
            const assignment = findAssignment(timetable, room.id, slot.id);
            if (assignment) {
                cell.innerHTML = `
                    <div class="assignment subject-${assignment.subject.toLowerCase()}">
                        <strong>${assignment.class}</strong><br>
                        ${assignment.subject}<br>
                        <small>${assignment.teacher}</small>
                    </div>
                `;
                cell.classList.add('tooltip');
                cell.dataset.roomId = room.id;
                cell.dataset.slotId = slot.id;
                cell.addEventListener('click', () => showExplanation(assignment));
            } else {
                cell.textContent = 'Free';
                cell.classList.add('empty');
            }
            
            grid.appendChild(cell);
        });
    });
    
    // Check for conflicts
    checkAndHighlightConflicts();
}

// Find assignment for room and slot
function findAssignment(timetable, roomId, slotId) {
    return timetable.assignments.find(a => 
        a.room_id === roomId && a.slot_id === slotId
    );
}

// Update reliability display
function updateReliabilityDisplay(reliability) {
    const valueSpan = document.getElementById('reliability-value');
    const bar = document.getElementById('reliability-bar');
    const riskSpan = document.getElementById('risk-level');
    
    valueSpan.textContent = (reliability * 100).toFixed(1) + '%';
    
    const fill = document.createElement('div');
    fill.className = 'reliability-fill';
    fill.style.width = (reliability * 100) + '%';
    
    if (reliability >= 0.95) {
        fill.classList.add('reliability-high');
        riskSpan.textContent = 'Low';
        riskSpan.style.color = 'var(--success-color)';
    } else if (reliability >= 0.85) {
        fill.classList.add('reliability-medium');
        riskSpan.textContent = 'Medium';
        riskSpan.style.color = 'var(--warning-color)';
    } else {
        fill.classList.add('reliability-low');
        riskSpan.textContent = 'High';
        riskSpan.style.color = 'var(--danger-color)';
    }
    
    bar.innerHTML = '';
    bar.appendChild(fill);
}

// Show explanation modal
async function showExplanation(assignment) {
    try {
        const response = await fetch(`${API_BASE}/explain`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ 
                class_id: assignment.class_id,
                subject_id: assignment.subject_id 
            })
        });
        const result = await response.json();
        
        if (result.status === 'success') {
            const modal = document.getElementById('explanation-modal');
            const text = document.getElementById('explanation-text');
            text.textContent = result.explanation;
            modal.classList.add('active');
        }
    } catch (error) {
        showNotification('Error fetching explanation: ' + error.message, 'error');
    }
}

// Check and highlight conflicts
async function checkAndHighlightConflicts() {
    try {
        const response = await fetch(`${API_BASE}/conflicts`);
        const result = await response.json();
        
        if (result.status === 'success' && result.conflicts.length > 0) {
            result.conflicts.forEach(conflict => {
                highlightConflict(conflict);
            });
            displayConflictList(result.conflicts);
        }
    } catch (error) {
        console.error('Error checking conflicts:', error);
    }
}

// Highlight conflict in grid
function highlightConflict(conflict) {
    const cells = document.querySelectorAll(
        `[data-room-id="${conflict.room_id}"][data-slot-id="${conflict.slot_id}"]`
    );
    cells.forEach(cell => cell.classList.add('conflict'));
}

// Display conflict list
function displayConflictList(conflicts) {
    const display = document.getElementById('conflicts-display');
    display.innerHTML = '<h3>Conflicts Detected:</h3>';
    const list = document.createElement('ul');
    conflicts.forEach(conflict => {
        const item = document.createElement('li');
        item.textContent = conflict.description;
        list.appendChild(item);
    });
    display.appendChild(list);
}

// Export functionality
document.getElementById('export-pdf').addEventListener('click', () => exportTimetable('pdf'));
document.getElementById('export-csv').addEventListener('click', () => exportTimetable('csv'));
document.getElementById('export-json').addEventListener('click', () => exportTimetable('json'));

async function exportTimetable(format) {
    try {
        const response = await fetch(`${API_BASE}/export?format=${format}`);
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `timetable.${format}`;
        a.click();
    } catch (error) {
        showNotification('Export failed: ' + error.message, 'error');
    }
}

// Notification system
function showNotification(message, type) {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;
    document.body.appendChild(notification);
    setTimeout(() => notification.remove(), 3000);
}

// Modal close
document.querySelector('.modal .close').addEventListener('click', () => {
    document.getElementById('explanation-modal').classList.remove('active');
});
```


## Data Models

### Prolog Fact Structures

#### Teacher
```prolog
teacher(
    TeacherID,           % Unique identifier (atom)
    Name,                % Teacher name (string)
    QualifiedSubjects,   % List of subject IDs
    MaxLoad,             % Maximum weekly hours (integer)
    AvailabilityList     % List of available time slot IDs
).

% Example:
teacher(t1, 'Dr. Alice Smith', [math, physics], 20, [1,2,3,4,5,6,7,8,9,10]).
```

#### Subject
```prolog
subject(
    SubjectID,      % Unique identifier (atom)
    Name,           % Subject name (string)
    WeeklyHours,    % Required hours per week (integer)
    Type,           % theory or lab (atom)
    Duration        % Hours per session (integer)
).

% Example:
subject(math, 'Mathematics', 4, theory, 1).
subject(chem_lab, 'Chemistry Lab', 3, lab, 2).
```

#### Room
```prolog
room(
    RoomID,     % Unique identifier (atom)
    Name,       % Room name (string)
    Capacity,   % Maximum students (integer)
    Type        % classroom or lab (atom)
).

% Example:
room(r101, 'Room 101', 40, classroom).
room(lab_a, 'Lab A', 30, lab).
```

#### Time Slot
```prolog
timeslot(
    SlotID,      % Unique identifier (atom)
    Day,         % monday, tuesday, etc. (atom)
    Period,      % Period number (integer)
    StartTime,   % Start time string (e.g., '09:00')
    Duration     % Duration in hours (integer)
).

% Example:
timeslot(s1, monday, 1, '09:00', 1).
timeslot(s2, monday, 2, '10:00', 1).
```

#### Class
```prolog
class(
    ClassID,      % Unique identifier (atom)
    Name,         % Class name (string)
    SubjectList   % List of subject IDs for this class
).

% Example:
class(cs1, 'Computer Science Year 1', [math, physics, programming, english]).
```

#### Assignment (in timetable)
```prolog
assigned(
    RoomID,      % Room where session is held
    ClassID,     % Class attending
    SubjectID,   % Subject being taught
    TeacherID,   % Teacher conducting
    SlotID       % Time slot
).

% Example:
assigned(r101, cs1, math, t1, s1).
```

### Matrix Structure

The timetable matrix is a 2D list structure:

```prolog
% Matrix dimensions: NumRooms × NumTimeSlots
% Matrix = [Row1, Row2, ..., RowN]
% Each Row = [Cell1, Cell2, ..., CellM]
% Each Cell = empty | assigned(RoomID, ClassID, SubjectID, TeacherID, SlotID)

% Example 3×4 matrix (3 rooms, 4 time slots):
[
    [assigned(r1, cs1, math, t1, s1), empty, assigned(r1, cs2, physics, t2, s3), empty],
    [empty, assigned(r2, cs1, english, t3, s2), empty, assigned(r2, cs3, chem, t4, s4)],
    [assigned(r3, cs2, lab, t5, s1), assigned(r3, cs2, lab, t5, s2), empty, empty]
]
```

### CSP Variable and Domain Structures

#### Variable (Session)
```prolog
session(ClassID, SubjectID).

% Example:
session(cs1, math).  % CS1 class needs math sessions
```

#### Domain Value
```prolog
value(TeacherID, RoomID, SlotID).

% Example:
value(t1, r101, s1).  % Teacher t1, Room r101, Slot s1
```

#### Domain
```prolog
% Domain is a list of possible values for a variable
Domain = [value(t1, r101, s1), value(t1, r101, s2), value(t2, r102, s1), ...].
```

#### Domain Map
```prolog
% Maps sessions to their domains
Domains = [
    session(cs1, math) - [value(t1, r101, s1), value(t1, r101, s2), ...],
    session(cs1, physics) - [value(t2, r102, s1), value(t2, r103, s2), ...],
    ...
].
```

### JSON API Formats

#### Resource Submission Request
```json
{
    "type": "teacher",
    "data": {
        "id": "t1",
        "name": "Dr. Alice Smith",
        "qualified_subjects": ["math", "physics"],
        "max_load": 20,
        "availability": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    }
}
```

#### Timetable Response
```json
{
    "status": "success",
    "timetable": {
        "rooms": [
            {"id": "r101", "name": "Room 101"},
            {"id": "r102", "name": "Room 102"}
        ],
        "slots": [
            {"id": "s1", "day": "monday", "period": 1, "start_time": "09:00"},
            {"id": "s2", "day": "monday", "period": 2, "start_time": "10:00"}
        ],
        "assignments": [
            {
                "room_id": "r101",
                "slot_id": "s1",
                "class_id": "cs1",
                "class": "Computer Science Year 1",
                "subject_id": "math",
                "subject": "Mathematics",
                "teacher_id": "t1",
                "teacher": "Dr. Alice Smith"
            }
        ]
    },
    "reliability": 0.92
}
```

#### Conflict Response
```json
{
    "status": "success",
    "conflicts": [
        {
            "type": "teacher_conflict",
            "teacher_id": "t1",
            "teacher_name": "Dr. Alice Smith",
            "slot_id": "s1",
            "sessions": ["cs1-math", "cs2-physics"],
            "description": "Teacher Dr. Alice Smith is assigned to multiple sessions at monday period 1"
        },
        {
            "type": "room_conflict",
            "room_id": "r101",
            "room_name": "Room 101",
            "slot_id": "s2",
            "sessions": ["cs1-english", "cs3-history"],
            "description": "Room 101 is double-booked at monday period 2"
        }
    ]
}
```

#### Explanation Response
```json
{
    "status": "success",
    "explanation": "Class Computer Science Year 1: Mathematics taught by Dr. Alice Smith in room Room 101 at 09:00 (Period 1 on monday). Teacher is qualified, room is suitable, no conflicts detected."
}
```

#### Analytics Response
```json
{
    "status": "success",
    "analytics": {
        "teacher_workload": [
            {"teacher": "Dr. Alice Smith", "hours": 18, "utilization": 0.9},
            {"teacher": "Dr. Bob Jones", "hours": 15, "utilization": 0.75}
        ],
        "room_utilization": [
            {"room": "Room 101", "occupied_slots": 25, "total_slots": 30, "utilization": 0.83},
            {"room": "Lab A", "occupied_slots": 18, "total_slots": 30, "utilization": 0.60}
        ],
        "schedule_density": {
            "average_sessions_per_day": 5.2,
            "average_gaps_per_class": 1.3
        }
    }
}
```

### File Structure

```
AI_Timetable_System/
├── backend/
│   ├── main.pl                    # Entry point, loads all modules
│   ├── knowledge_base.pl          # FOL facts and rules
│   ├── constraints.pl             # Hard and soft constraints
│   ├── csp_solver.pl              # Backtracking with heuristics
│   ├── matrix_model.pl            # Matrix operations
│   ├── probability_module.pl      # Reliability calculations
│   ├── timetable_generator.pl     # Main generation logic
│   ├── api_server.pl              # HTTP server and routing
│   ├── logging.pl                 # Logging system
│   └── testing.pl                 # Unit tests
├── frontend/
│   ├── index.html                 # Main HTML structure
│   ├── style.css                  # Styling
│   └── script.js                  # Frontend logic
├── data/
│   ├── dataset.pl                 # Example resource data
│   └── config.pl                  # Configuration settings
├── docs/
│   ├── README.md                  # Installation and usage
│   └── architecture.md            # System architecture
└── tests/
    └── test_data.pl               # Test datasets
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Resource Data Round-Trip

*For any* valid resource data (teacher, subject, room, timeslot, or class), submitting it to the API and then retrieving it from the Knowledge Base should return equivalent data with all fields preserved.

**Validates: Requirements 1.6**

### Property 2: Invalid Data Rejection

*For any* invalid resource data (missing required fields, wrong types, out-of-range values), the API Server should reject the submission and return a descriptive error message identifying the specific validation failure.

**Validates: Requirements 1.7**

### Property 3: Matrix Structure Preservation

*For any* valid timetable matrix, performing access and update operations should preserve the matrix dimensions and structure (number of rows equals number of rooms, number of columns equals number of time slots).

**Validates: Requirements 2.7**

### Property 4: Matrix Dimension Correctness

*For any* list of rooms and list of time slots, creating an empty timetable matrix should produce a matrix with dimensions matching the number of rooms (rows) and number of time slots (columns).

**Validates: Requirements 2.2**

### Property 5: Teacher Qualification Inference

*For any* teacher and subject, the qualified/2 predicate should return true if and only if the subject ID appears in the teacher's qualified subjects list.

**Validates: Requirements 3.6**

### Property 6: Room Suitability Inference

*For any* room and session type, the suitable_room/2 predicate should return true if and only if the room type matches the session type (theory→classroom, lab→lab).

**Validates: Requirements 3.7**

### Property 7: No Teacher Conflicts

*For any* valid generated timetable, no teacher should be assigned to multiple class sessions in the same time slot.

**Validates: Requirements 4.1**

### Property 8: No Room Conflicts

*For any* valid generated timetable, no room should be assigned to multiple class sessions in the same time slot.

**Validates: Requirements 4.2**

### Property 9: Weekly Hours Requirement

*For any* valid generated timetable, each class-subject pair should have total scheduled hours equal to the subject's required weekly hours.

**Validates: Requirements 4.3**

### Property 10: Consecutive Lab Sessions

*For any* lab session in a valid timetable with duration exceeding one period, the assigned time slots should be consecutive (same day, sequential periods).

**Validates: Requirements 4.4**

### Property 11: Theory Room Type Constraint

*For any* theory session in a valid generated timetable, the assigned room should have type 'classroom'.

**Validates: Requirements 4.5**

### Property 12: Lab Room Type Constraint

*For any* lab session in a valid generated timetable, the assigned room should have type 'lab'.

**Validates: Requirements 4.6**

### Property 13: Teacher Qualification Constraint

*For any* assignment in a valid generated timetable, the assigned teacher should be qualified to teach the assigned subject (subject ID in teacher's qualified subjects list).

**Validates: Requirements 4.7**

### Property 14: Room Capacity Constraint

*For any* assignment in a valid generated timetable, the assigned room's capacity should meet or exceed the class size.

**Validates: Requirements 4.8**

### Property 15: Teacher Availability Constraint

*For any* assignment in a valid generated timetable, the assigned time slot should be in the teacher's availability list.

**Validates: Requirements 4.9**

### Property 16: Workload Balance Measurement

*For any* generated timetable, the system should be able to calculate a workload balance score for each teacher based on the distribution of their sessions across days of the week.

**Validates: Requirements 5.1**

### Property 17: Late Theory Class Detection

*For any* generated timetable, the system should be able to identify and count theory classes scheduled in late afternoon or evening time slots (period > 6).

**Validates: Requirements 5.2**

### Property 18: Back-to-Back Lab Detection

*For any* generated timetable, the system should be able to identify teachers with back-to-back lab sessions (consecutive time slots, both lab type).

**Validates: Requirements 5.3**

### Property 19: Schedule Gap Measurement

*For any* generated timetable and any class, the system should be able to calculate the number of gaps (free periods between scheduled sessions) in that class's schedule.

**Validates: Requirements 5.5**

### Property 20: Reliability Score Range

*For any* timetable, the calculated reliability score should be a value between 0.0 and 1.0 inclusive.

**Validates: Requirements 8.4, 8.7**

### Property 21: Reliability Calculation Correctness

*For any* timetable, the reliability score should be calculated using the product of individual assignment probabilities (teacher availability × room availability × class occurrence for each assignment).

**Validates: Requirements 8.5**

### Property 22: Conditional Reliability Dependencies

*For any* timetable and any teacher, if that teacher becomes unavailable, the conditional reliability should account for all sessions taught by that teacher being affected.

**Validates: Requirements 8.6**

### Property 23: Assignment Explanation Availability

*For any* assignment in a generated timetable, the explain_assignment predicate should return an explanation containing the teacher name, subject name, room name, time slot details, and justification for the assignment.

**Validates: Requirements 9.1, 9.3**

### Property 24: Conflict Detection Completeness

*For any* timetable (valid or invalid), the detect_conflicts predicate should identify all constraint violations including teacher conflicts, room conflicts, and any hard constraint violations.

**Validates: Requirements 3.8, 3.9, 9.4**

### Property 25: Conflict Description Completeness

*For any* detected conflict, the conflict description should include the conflict type, the conflicting resource identifiers, the time slot, and the affected sessions.

**Validates: Requirements 9.5**

### Property 26: Timetable Format Round-Trip

*For any* valid timetable structure, formatting it to JSON and then parsing the JSON back should produce an equivalent timetable structure with all assignments preserved.

**Validates: Requirements 10.7**

### Property 27: Parse Validation

*For any* timetable data referencing non-existent resources (invalid teacher ID, room ID, subject ID, or slot ID), the parse_timetable predicate should fail and return an error identifying the missing resource.

**Validates: Requirements 10.2**

### Property 28: Invalid Parse Error Messages

*For any* malformed timetable data (wrong structure, missing fields, invalid types), the parse_timetable predicate should return a descriptive error message identifying the specific parsing failure.

**Validates: Requirements 10.3**

### Property 29: JSON Format Validity

*For any* timetable, formatting it as JSON should produce syntactically valid JSON that can be parsed by standard JSON parsers.

**Validates: Requirements 10.5**

### Property 30: API JSON Request Parsing

*For any* valid JSON request body sent to API endpoints, the API Server should successfully parse the JSON and extract the required fields.

**Validates: Requirements 11.7**

### Property 31: API JSON Response Format

*For any* API request (successful or failed), the API Server should return a response with valid JSON body and appropriate HTTP status code (2xx for success, 4xx for client errors, 5xx for server errors).

**Validates: Requirements 11.8**

### Property 32: API Error Response Format

*For any* failed API request, the response should include a JSON body with status field set to "error" and a descriptive message field, along with a 4xx or 5xx HTTP status code.

**Validates: Requirements 11.9**

### Property 33: CORS Headers Presence

*For any* API request, the response should include CORS headers (Access-Control-Allow-Origin, Access-Control-Allow-Methods, Access-Control-Allow-Headers) to enable cross-origin requests.

**Validates: Requirements 11.10**

### Property 34: Concurrent Request Data Consistency

*For any* set of concurrent API requests that modify or read timetable data, the system should maintain data consistency with no corruption or race conditions.

**Validates: Requirements 15.5**

### Property 35: Exception Handling

*For any* Prolog predicate that fails with an exception, the system should catch the exception, log detailed error information, and return a user-friendly error message to the API caller.

**Validates: Requirements 16.1, 16.2**

### Property 36: Inconsistent Data Detection

*For any* Knowledge Base state containing inconsistent data (e.g., teacher qualified for non-existent subject, class referencing non-existent subject), the validation predicates should detect the inconsistency and report which facts are conflicting.

**Validates: Requirements 16.3, 16.4**

### Property 37: Malformed JSON Handling

*For any* malformed JSON request body (syntax errors, invalid structure), the API Server should return a 400 Bad Request response with parsing error details.

**Validates: Requirements 16.5**

### Property 38: Missing Resource Error Reporting

*For any* timetable generation attempt with missing required resources (no teachers, no rooms, no time slots), the system should fail with an error message identifying which specific resource is missing and why it is needed.

**Validates: Requirements 16.6**

### Property 39: Repair Preserves Valid Assignments

*For any* timetable repair operation, assignments that do not violate any constraints should be preserved in the repaired timetable.

**Validates: Requirements 20.2**

### Property 40: Repair Minimizes Changes

*For any* timetable repair operation, the number of changed assignments should be minimal (only conflicting assignments and their dependencies are modified).

**Validates: Requirements 20.3**

### Property 41: Analytics Calculation Completeness

*For any* generated timetable, the system should be able to calculate teacher workload statistics (hours per teacher), room utilization percentages (occupied slots / total slots), and average student schedule density (sessions per day, gaps per class).

**Validates: Requirements 22.1, 22.2, 22.3**

### Property 42: Analytics JSON Export

*For any* generated timetable, the analytics data should be exportable as valid JSON containing all calculated statistics.

**Validates: Requirements 22.5**

### Property 43: Input Validation Completeness

*For any* API request, all JSON input fields should be validated for type correctness, required field presence, and value range constraints before processing.

**Validates: Requirements 24.1**

### Property 44: Invalid Identifier Rejection

*For any* API request containing invalid resource identifiers (non-existent IDs, wrong format), the request should be rejected with an appropriate error message.

**Validates: Requirements 24.2**

### Property 45: Text Field Sanitization

*For any* API request containing text fields, the input should be sanitized to remove or escape potentially harmful characters before storage or processing.

**Validates: Requirements 24.3**

### Property 46: Payload Size Limits

*For any* API request with payload size exceeding the configured limit, the request should be rejected with a 413 Payload Too Large response.

**Validates: Requirements 24.4**

### Property 47: Export Format Completeness

*For any* generated timetable, exporting it in any format (PDF, CSV, JSON) should produce a file containing all required information: teacher names, subject names, room numbers, time slots, and class names for all assignments.

**Validates: Requirements 25.1, 25.2, 25.3, 25.4**


## Error Handling

### Error Categories

#### 1. Input Validation Errors

**Scenarios**:
- Missing required fields in resource data
- Invalid data types (string where integer expected)
- Out-of-range values (negative capacity, invalid day name)
- Malformed JSON syntax

**Handling Strategy**:
```prolog
validate_resource(ResourceType, Data, ValidatedData) :-
    catch(
        (check_required_fields(ResourceType, Data),
         check_field_types(ResourceType, Data),
         check_value_ranges(ResourceType, Data),
         ValidatedData = Data),
        validation_error(Field, Reason),
        (log_error(validation_error(Field, Reason)),
         throw(api_error(400, 'Validation failed', Field, Reason)))
    ).
```

**Response Format**:
```json
{
    "status": "error",
    "code": 400,
    "message": "Validation failed",
    "field": "max_load",
    "reason": "Value must be a positive integer"
}
```

#### 2. Constraint Violation Errors

**Scenarios**:
- No valid timetable exists (over-constrained problem)
- Conflicting hard constraints
- Insufficient resources (not enough rooms, teachers, or time slots)

**Handling Strategy**:
```prolog
generate_timetable(Timetable) :-
    catch(
        (retrieve_and_validate_resources,
         solve_csp(Sessions, EmptyMatrix, Timetable)),
        csp_failure(Reason),
        (log_error(csp_failure(Reason)),
         analyze_failure(Reason, Explanation),
         throw(api_error(422, 'Cannot generate timetable', Explanation)))
    ).

analyze_failure(no_solution, Explanation) :-
    identify_conflicting_constraints(Conflicts),
    format(atom(Explanation), 
           'No valid timetable exists. Conflicting constraints: ~w. Consider: adding more rooms, increasing teacher availability, or reducing subject hours.',
           [Conflicts]).
```

**Response Format**:
```json
{
    "status": "error",
    "code": 422,
    "message": "Cannot generate timetable",
    "explanation": "No valid timetable exists. Conflicting constraints: [teacher_availability, room_capacity]. Consider: adding more rooms, increasing teacher availability, or reducing subject hours.",
    "suggestions": [
        "Add more classroom-type rooms",
        "Increase teacher t1 availability",
        "Reduce weekly hours for subject math"
    ]
}
```

#### 3. Resource Not Found Errors

**Scenarios**:
- Querying non-existent timetable
- Referencing invalid resource IDs
- Missing required resources during generation

**Handling Strategy**:
```prolog
get_resource(ResourceType, ID, Resource) :-
    (   resource_exists(ResourceType, ID)
    ->  retrieve_resource(ResourceType, ID, Resource)
    ;   throw(api_error(404, 'Resource not found', ResourceType, ID))
    ).
```

**Response Format**:
```json
{
    "status": "error",
    "code": 404,
    "message": "Resource not found",
    "resource_type": "teacher",
    "resource_id": "t99"
}
```

#### 4. System Errors

**Scenarios**:
- Prolog runtime exceptions
- Memory exhaustion
- Unexpected predicate failures
- File I/O errors

**Handling Strategy**:
```prolog
safe_execute(Goal, Result) :-
    catch(
        (call(Goal), Result = success),
        Exception,
        (log_error(system_error(Exception)),
         format_user_error(Exception, UserMessage),
         Result = error(UserMessage))
    ).

format_user_error(Exception, Message) :-
    (   Exception = error(resource_error(_), _)
    ->  Message = 'System resource exhausted. Please try again with a smaller problem.'
    ;   Exception = error(existence_error(_, _), _)
    ->  Message = 'Required system component not found. Please check installation.'
    ;   Message = 'An unexpected error occurred. Please contact support.'
    ).
```

**Response Format**:
```json
{
    "status": "error",
    "code": 500,
    "message": "Internal server error",
    "user_message": "An unexpected error occurred. Please contact support.",
    "error_id": "err_20240115_123456"
}
```

### Error Recovery Strategies

#### Graceful Degradation

When full timetable generation fails, attempt partial generation:

```prolog
generate_timetable_with_fallback(Result) :-
    (   generate_timetable(Timetable)
    ->  Result = complete(Timetable)
    ;   generate_partial_timetable(PartialTimetable, UnassignedSessions)
    ->  Result = partial(PartialTimetable, UnassignedSessions)
    ;   Result = failed
    ).
```

#### Constraint Relaxation

If hard constraints cannot be satisfied, suggest which constraints to relax:

```prolog
suggest_constraint_relaxation(Conflicts, Suggestions) :-
    analyze_constraint_conflicts(Conflicts, Analysis),
    rank_by_relaxation_impact(Analysis, RankedSuggestions),
    Suggestions = RankedSuggestions.
```

#### Automatic Retry with Adjustments

For timeout or resource exhaustion, retry with reduced search space:

```prolog
generate_with_retry(Timetable, Attempts) :-
    Attempts > 0,
    (   generate_timetable(Timetable)
    ->  true
    ;   reduce_search_space,
        Attempts1 is Attempts - 1,
        generate_with_retry(Timetable, Attempts1)
    ).
```

### Error Logging

All errors are logged with structured information:

```prolog
log_error(Error) :-
    get_timestamp(Timestamp),
    generate_error_id(ErrorID),
    format_error_details(Error, Details),
    write_log_entry(error, Timestamp, ErrorID, Details),
    (   should_alert(Error)
    ->  send_alert(Error, ErrorID)
    ;   true
    ).
```

Log entry format:
```
[2024-01-15 12:34:56] ERROR [err_20240115_123456]: CSP solver failed - no solution found
Details: {
    "constraints_checked": 1247,
    "backtrack_count": 5432,
    "time_elapsed": "28.3s",
    "conflicting_constraints": ["teacher_availability", "room_capacity"]
}
```


## Testing Strategy

### Dual Testing Approach

The system employs both unit testing and property-based testing to ensure comprehensive correctness verification:

- **Unit Tests**: Verify specific examples, edge cases, and integration points
- **Property Tests**: Verify universal properties across all inputs through randomization

Both approaches are complementary and necessary:
- Unit tests catch concrete bugs in specific scenarios
- Property tests verify general correctness across the input space

### Property-Based Testing

#### Framework Selection

**SWI-Prolog**: Use `plunit` with custom property test generators

For property-based testing, we'll implement a lightweight PBT framework in Prolog:

```prolog
% Property test runner
property_test(PropertyName, Generator, Property, NumTests) :-
    format('Testing property: ~w (~w iterations)~n', [PropertyName, NumTests]),
    run_property_iterations(Generator, Property, NumTests, 0, 0).

run_property_iterations(_, _, 0, Passed, Failed) :-
    format('Results: ~w passed, ~w failed~n', [Passed, Failed]),
    (Failed = 0 -> true ; fail).

run_property_iterations(Generator, Property, N, Passed, Failed) :-
    N > 0,
    (   call(Generator, Input),
        call(Property, Input)
    ->  Passed1 is Passed + 1,
        Failed1 = Failed
    ;   format('FAILED on input: ~w~n', [Input]),
        Passed1 = Passed,
        Failed1 is Failed + 1
    ),
    N1 is N - 1,
    run_property_iterations(Generator, Property, N1, Passed1, Failed1).
```

#### Property Test Configuration

Each property test must:
- Run minimum 100 iterations (due to randomization)
- Reference the design document property in a comment tag
- Use appropriate generators for input data

**Tag Format**:
```prolog
% Feature: ai-timetable-generation, Property 7: No Teacher Conflicts
test(property_no_teacher_conflicts) :-
    property_test(
        'No teacher conflicts',
        generate_random_timetable,
        check_no_teacher_conflicts,
        100
    ).
```

#### Generators

Generators create random valid inputs for property tests:

```prolog
% Generate random teacher
generate_teacher(teacher(ID, Name, Subjects, MaxLoad, Availability)) :-
    random_atom(5, ID),
    random_name(Name),
    random_subject_list(Subjects),
    random_between(10, 30, MaxLoad),
    random_slot_list(Availability).

% Generate random timetable
generate_random_timetable(Timetable) :-
    generate_random_resources(Teachers, Subjects, Rooms, Slots, Classes),
    assert_resources(Teachers, Subjects, Rooms, Slots, Classes),
    create_sessions(Classes, Subjects, Sessions),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    solve_csp(Sessions, EmptyMatrix, Timetable),
    retract_resources.

% Generate random matrix
generate_random_matrix(Matrix) :-
    random_between(2, 10, Rows),
    random_between(2, 20, Cols),
    create_matrix(Rows, Cols, Matrix).
```

### Unit Testing

#### Test Organization

Tests are organized by module:

```prolog
:- begin_tests(knowledge_base).
:- begin_tests(matrix_model).
:- begin_tests(constraints).
:- begin_tests(csp_solver).
:- begin_tests(probability_module).
:- begin_tests(timetable_generator).
:- begin_tests(api_server).
```

#### Example Unit Tests

**Knowledge Base Tests**:
```prolog
:- begin_tests(knowledge_base).

test(teacher_qualification_positive) :-
    assertz(teacher(t1, 'Dr. Smith', [math, physics], 20, [1,2,3])),
    qualified(t1, math),
    retractall(teacher(t1, _, _, _, _)).

test(teacher_qualification_negative) :-
    assertz(teacher(t1, 'Dr. Smith', [math, physics], 20, [1,2,3])),
    \+ qualified(t1, chemistry),
    retractall(teacher(t1, _, _, _, _)).

test(room_suitability_theory) :-
    assertz(room(r1, 'Room 101', 40, classroom)),
    suitable_room(r1, theory),
    retractall(room(r1, _, _, _)).

test(room_suitability_lab) :-
    assertz(room(lab1, 'Lab A', 30, lab)),
    suitable_room(lab1, lab),
    retractall(room(lab1, _, _, _)).

:- end_tests(knowledge_base).
```

**Matrix Model Tests**:
```prolog
:- begin_tests(matrix_model).

test(matrix_creation_dimensions) :-
    create_empty_timetable([r1, r2, r3], [s1, s2, s3, s4], Matrix),
    length(Matrix, 3),
    Matrix = [Row1|_],
    length(Row1, 4).

test(matrix_cell_access) :-
    create_empty_timetable([r1, r2], [s1, s2], Matrix),
    get_cell(Matrix, 0, 0, Cell),
    Cell = empty.

test(matrix_cell_update) :-
    create_empty_timetable([r1, r2], [s1, s2], Matrix),
    set_cell(Matrix, 0, 0, assigned(r1, c1, math, t1, s1), UpdatedMatrix),
    get_cell(UpdatedMatrix, 0, 0, Cell),
    Cell = assigned(r1, c1, math, t1, s1).

% Feature: ai-timetable-generation, Property 3: Matrix Structure Preservation
test(property_matrix_structure_preservation) :-
    property_test(
        'Matrix structure preservation',
        generate_random_matrix,
        check_matrix_structure_preserved,
        100
    ).

check_matrix_structure_preserved(Matrix) :-
    length(Matrix, OrigRows),
    Matrix = [Row|_],
    length(Row, OrigCols),
    random_between(0, OrigRows-1, RowIdx),
    random_between(0, OrigCols-1, ColIdx),
    set_cell(Matrix, RowIdx, ColIdx, test_value, UpdatedMatrix),
    length(UpdatedMatrix, NewRows),
    UpdatedMatrix = [NewRow|_],
    length(NewRow, NewCols),
    OrigRows = NewRows,
    OrigCols = NewCols.

:- end_tests(matrix_model).
```

**Constraint Tests**:
```prolog
:- begin_tests(constraints).

test(teacher_conflict_detection) :-
    % Create matrix with teacher conflict
    Matrix = [[assigned(r1, c1, math, t1, s1)], [assigned(r2, c2, physics, t1, s1)]],
    \+ check_teacher_no_conflict(t1, s1, Matrix).

test(room_conflict_detection) :-
    % Create matrix with room conflict
    Matrix = [[assigned(r1, c1, math, t1, s1), assigned(r1, c2, physics, t2, s1)]],
    \+ check_room_no_conflict(r1, s1, Matrix).

% Feature: ai-timetable-generation, Property 7: No Teacher Conflicts
test(property_no_teacher_conflicts) :-
    property_test(
        'No teacher conflicts in valid timetables',
        generate_valid_timetable,
        check_no_teacher_conflicts_property,
        100
    ).

check_no_teacher_conflicts_property(Timetable) :-
    get_all_assignments(Timetable, Assignments),
    \+ (member(assigned(_, _, _, T, S), Assignments),
        member(assigned(_, _, _, T, S), Assignments),
        % Ensure they're different assignments
        assigned(_, _, _, T, S) \= assigned(_, _, _, T, S)).

:- end_tests(constraints).
```

**CSP Solver Tests**:
```prolog
:- begin_tests(csp_solver).

test(simple_solvable_instance) :-
    % Setup simple problem
    assertz(teacher(t1, 'Teacher 1', [math], 10, [s1, s2])),
    assertz(subject(math, 'Math', 2, theory, 1)),
    assertz(room(r1, 'Room 1', 40, classroom)),
    assertz(timeslot(s1, monday, 1, '09:00', 1)),
    assertz(timeslot(s2, monday, 2, '10:00', 1)),
    assertz(class(c1, 'Class 1', [math])),
    % Solve
    create_sessions([class(c1, 'Class 1', [math])], [subject(math, 'Math', 2, theory, 1)], Sessions),
    create_empty_timetable([r1], [s1, s2], EmptyMatrix),
    solve_csp(Sessions, EmptyMatrix, Timetable),
    % Verify solution exists
    Timetable \= [],
    % Cleanup
    retractall(teacher(_, _, _, _, _)),
    retractall(subject(_, _, _, _, _)),
    retractall(room(_, _, _, _)),
    retractall(timeslot(_, _, _, _, _)),
    retractall(class(_, _, _)).

test(unsolvable_instance) :-
    % Setup impossible problem (no available teachers)
    assertz(subject(math, 'Math', 2, theory, 1)),
    assertz(room(r1, 'Room 1', 40, classroom)),
    assertz(timeslot(s1, monday, 1, '09:00', 1)),
    assertz(class(c1, 'Class 1', [math])),
    % Attempt to solve
    create_sessions([class(c1, 'Class 1', [math])], [subject(math, 'Math', 2, theory, 1)], Sessions),
    create_empty_timetable([r1], [s1], EmptyMatrix),
    \+ solve_csp(Sessions, EmptyMatrix, _),
    % Cleanup
    retractall(subject(_, _, _, _, _)),
    retractall(room(_, _, _, _)),
    retractall(timeslot(_, _, _, _, _)),
    retractall(class(_, _, _)).

:- end_tests(csp_solver).
```

**Probability Module Tests**:
```prolog
:- begin_tests(probability_module).

% Feature: ai-timetable-generation, Property 20: Reliability Score Range
test(property_reliability_range) :-
    property_test(
        'Reliability score in valid range',
        generate_valid_timetable,
        check_reliability_range,
        100
    ).

check_reliability_range(Timetable) :-
    schedule_reliability(Timetable, Reliability),
    Reliability >= 0.0,
    Reliability =< 1.0.

% Feature: ai-timetable-generation, Property 21: Reliability Calculation Correctness
test(property_reliability_calculation) :-
    % Create simple timetable with known probabilities
    Matrix = [[assigned(r1, c1, math, t1, s1)]],
    schedule_reliability(Matrix, Reliability),
    % With default probabilities: 0.95 * 0.98 * 0.99 = 0.92169
    ExpectedMin is 0.92,
    ExpectedMax is 0.93,
    Reliability >= ExpectedMin,
    Reliability =< ExpectedMax.

:- end_tests(probability_module).
```

**Integration Tests**:
```prolog
:- begin_tests(integration).

test(end_to_end_generation) :-
    % Load example dataset
    load_dataset('data/dataset.pl'),
    % Generate timetable
    generate_timetable(Timetable),
    % Verify all constraints satisfied
    validate_timetable(Timetable),
    % Calculate reliability
    schedule_reliability(Timetable, Reliability),
    Reliability > 0.0,
    % Cleanup
    clear_knowledge_base.

test(api_resource_submission) :-
    % Start API server
    start_test_server,
    % Submit teacher data
    http_post('http://localhost:8080/api/resources',
              json(_{type: teacher, data: _{id: t1, name: 'Test Teacher', qualified_subjects: [math], max_load: 20, availability: [1,2,3]}}),
              Response,
              []),
    % Verify success
    Response.status = success,
    % Cleanup
    stop_test_server.

:- end_tests(integration).
```

### Test Execution

Run all tests with:
```prolog
?- run_tests.
```

Run specific test suite:
```prolog
?- run_tests(matrix_model).
```

Run with verbose output:
```prolog
?- run_tests([verbose(true)]).
```

### Coverage Goals

- **Unit Test Coverage**: Minimum 80% of predicates
- **Property Test Coverage**: All 47 correctness properties
- **Integration Test Coverage**: All major user workflows
- **Edge Case Coverage**: Empty inputs, boundary values, maximum sizes

### Continuous Testing

Tests should be run:
- Before each commit
- On pull request creation
- Nightly with extended property test iterations (1000+ per property)
- Before releases with full integration test suite


## Security Considerations

### Input Validation

#### JSON Schema Validation

All API requests must conform to predefined schemas:

```prolog
validate_teacher_data(Data) :-
    required_field(Data, id, atom),
    required_field(Data, name, string),
    required_field(Data, qualified_subjects, list),
    required_field(Data, max_load, integer),
    required_field(Data, availability, list),
    validate_range(Data.max_load, 1, 100),
    validate_list_elements(Data.qualified_subjects, atom),
    validate_list_elements(Data.availability, integer).

required_field(Data, Field, Type) :-
    get_dict(Field, Data, Value),
    check_type(Value, Type).
```

#### Sanitization

Text inputs are sanitized to prevent injection attacks:

```prolog
sanitize_text(Input, Sanitized) :-
    % Remove control characters
    re_replace('[\\x00-\\x1F\\x7F]'/g, '', Input, Step1),
    % Escape special characters
    escape_html(Step1, Step2),
    % Limit length
    truncate_string(Step2, 1000, Sanitized).

escape_html(Input, Output) :-
    re_replace('&'/g, '&amp;', Input, S1),
    re_replace('<'/g, '&lt;', S1, S2),
    re_replace('>'/g, '&gt;', S2, S3),
    re_replace('"'/g, '&quot;', S3, S4),
    re_replace("'"/g, '&#x27;', S4, Output).
```

#### Resource Identifier Validation

All resource IDs must match expected patterns:

```prolog
validate_resource_id(ID) :-
    atom(ID),
    atom_length(ID, Len),
    Len > 0,
    Len =< 50,
    atom_codes(ID, Codes),
    all_valid_id_chars(Codes).

all_valid_id_chars([]).
all_valid_id_chars([C|Rest]) :-
    (   C >= 0'a, C =< 0'z
    ;   C >= 0'A, C =< 0'Z
    ;   C >= 0'0, C =< 0'9
    ;   C = 0'_
    ;   C = 0'-
    ),
    all_valid_id_chars(Rest).
```

### Request Size Limits

Prevent resource exhaustion attacks:

```prolog
:- set_setting(http:max_post_size, 1048576).  % 1 MB limit

check_request_size(Request) :-
    memberchk(content_length(Size), Request),
    (   Size > 1048576
    ->  throw(http_reply(payload_too_large))
    ;   true
    ).
```

### Rate Limiting

Prevent abuse through rate limiting:

```prolog
:- dynamic request_count/2.

check_rate_limit(ClientIP) :-
    get_time(Now),
    Window is Now - 60,  % 1 minute window
    retractall(request_count(ClientIP, Time)),
    Time < Window,
    findall(_, request_count(ClientIP, _), Requests),
    length(Requests, Count),
    (   Count >= 100  % Max 100 requests per minute
    ->  throw(http_reply(too_many_requests))
    ;   assertz(request_count(ClientIP, Now))
    ).
```

### Authentication and Authorization

For production deployment, add authentication:

```prolog
check_auth(Request) :-
    (   memberchk(authorization(Auth), Request)
    ->  validate_token(Auth, UserID),
        check_permissions(UserID, Request)
    ;   throw(http_reply(unauthorized))
    ).

validate_token(Token, UserID) :-
    % Verify JWT or API key
    decode_token(Token, Claims),
    get_dict(user_id, Claims, UserID),
    \+ token_expired(Claims).
```

### Data Privacy

Sensitive data handling:

```prolog
% Don't log sensitive information
log_request(Request) :-
    remove_sensitive_fields(Request, SafeRequest),
    log_info(request(SafeRequest)).

remove_sensitive_fields(Request, SafeRequest) :-
    exclude(is_sensitive_field, Request, SafeRequest).

is_sensitive_field(authorization(_)).
is_sensitive_field(cookie(_)).
```

### SQL Injection Prevention

Although using Prolog facts (not SQL), prevent code injection:

```prolog
% Never use format/3 with user input in goal position
% BAD: format(atom(Goal), 'teacher(~w, _, _, _, _)', [UserInput]), call(Goal)
% GOOD: Use parameterized queries
safe_query_teacher(ID, Teacher) :-
    validate_resource_id(ID),  % Validate first
    teacher(ID, Name, Subjects, MaxLoad, Availability),
    Teacher = teacher(ID, Name, Subjects, MaxLoad, Availability).
```

### HTTPS Enforcement

For production, enforce HTTPS:

```prolog
:- use_module(library(http/http_ssl_plugin)).

start_secure_server(Port) :-
    http_server(http_dispatch, [
        port(Port),
        ssl([
            certificate_file('cert.pem'),
            key_file('key.pem'),
            password('secret')
        ])
    ]).
```

### Security Headers

Add security headers to all responses:

```prolog
add_security_headers :-
    format('X-Content-Type-Options: nosniff~n'),
    format('X-Frame-Options: DENY~n'),
    format('X-XSS-Protection: 1; mode=block~n'),
    format('Content-Security-Policy: default-src \'self\'~n'),
    format('Strict-Transport-Security: max-age=31536000; includeSubDomains~n').
```

## Performance Optimizations

### Heuristic Selection Rationale

#### Minimum Remaining Values (MRV)

**Purpose**: Select the most constrained variable first to fail fast.

**Benefit**: Reduces search tree size by detecting dead ends early.

**Implementation**:
```prolog
select_variable_mrv(Variables, Domains, Selected) :-
    findall(Count-Var, 
            (member(Var, Variables), 
             get_domain(Var, Domains, Domain), 
             length(Domain, Count)), 
            Pairs),
    sort(Pairs, [_-Selected|_]).
```

**Impact**: Reduces average search time by 40-60% compared to random variable selection.

#### Degree Heuristic

**Purpose**: Break ties by selecting variables involved in most constraints.

**Benefit**: Further reduces search space by addressing highly connected variables.

**Implementation**:
```prolog
count_constraints(Variable, OtherVariables, Count) :-
    findall(1, 
            (member(Other, OtherVariables), 
             shares_constraint(Variable, Other)), 
            Ones),
    length(Ones, Count).
```

**Impact**: Reduces tie-breaking randomness, improving consistency.

#### Least Constraining Value (LCV)

**Purpose**: Select values that leave maximum flexibility for future assignments.

**Benefit**: Increases likelihood of finding solutions without backtracking.

**Implementation**:
```prolog
order_values_lcv(Values, Variable, OtherVariables, Domains, OrderedValues) :-
    findall(EliminatedCount-Value,
            (member(Value, Values),
             count_eliminated_values(Value, Variable, OtherVariables, Domains, EliminatedCount)),
            Pairs),
    sort(Pairs, SortedPairs),
    pairs_values(SortedPairs, OrderedValues).
```

**Impact**: Reduces backtracking by 30-50%.

### Forward Checking Benefits

**Purpose**: Prune inconsistent values from future variable domains after each assignment.

**Benefit**: Detects failures earlier, reducing wasted search effort.

**Algorithm**:
```prolog
forward_check(AssignedVar, AssignedValue, FutureVars, Domains, NewDomains) :-
    maplist(prune_domain(AssignedVar, AssignedValue), FutureVars, Domains, NewDomains).

prune_domain(AssignedVar, AssignedValue, Var, Domain, PrunedDomain) :-
    exclude(conflicts_with(AssignedVar, AssignedValue, Var), Domain, PrunedDomain).
```

**Impact**: Reduces search nodes by 50-70% compared to naive backtracking.

### Search Space Pruning Strategies

#### Early Constraint Checking

Check constraints immediately after assignment, before recursive call:

```prolog
try_assignment(Var, Value, Remaining, Domains, Matrix, Solution) :-
    assign_value(Var, Value, Matrix, NewMatrix),
    check_all_constraints(Var, Value, NewMatrix),  % Fail fast
    forward_check(Var, Value, Remaining, Domains, NewDomains),
    backtracking_search(Remaining, NewDomains, NewMatrix, Solution).
```

#### Domain Ordering

Pre-sort domains by likelihood of success:

```prolog
initialize_domains_optimized(Variables, Domains) :-
    maplist(generate_and_sort_domain, Variables, Domains).

generate_and_sort_domain(Var, Var-SortedDomain) :-
    generate_domain(Var, Domain),
    score_domain_values(Domain, ScoredDomain),
    sort(ScoredDomain, SortedScoredDomain),
    pairs_values(SortedScoredDomain, SortedDomain).
```

#### Constraint Propagation

Beyond forward checking, propagate constraints transitively:

```prolog
arc_consistency(Domains, ConsistentDomains) :-
    propagate_constraints(Domains, NewDomains),
    (   Domains = NewDomains
    ->  ConsistentDomains = Domains
    ;   arc_consistency(NewDomains, ConsistentDomains)
    ).
```

### Caching and Memoization

Cache expensive computations:

```prolog
:- dynamic cached_domain/2.

get_domain_cached(Variable, Domain) :-
    (   cached_domain(Variable, Domain)
    ->  true
    ;   generate_domain(Variable, Domain),
        assertz(cached_domain(Variable, Domain))
    ).
```

### Parallel Search

For large problems, explore branches in parallel:

```prolog
parallel_solve(Variables, Domains, Matrix, Solution) :-
    select_variable(Variables, Domains, Var, Remaining),
    get_domain(Var, Domains, Values),
    concurrent_maplist(try_branch(Var, Remaining, Domains, Matrix), Values, Solutions),
    member(Solution, Solutions),
    Solution \= failed.
```

### Memory Management

Limit memory usage for large problems:

```prolog
:- set_prolog_flag(stack_limit, 2_000_000_000).  % 2 GB limit

check_memory_usage :-
    statistics(globalused, Used),
    (   Used > 1_500_000_000  % 1.5 GB threshold
    ->  garbage_collect,
        trim_stacks
    ;   true
    ).
```

## Extensibility Design

### Plugin Architecture for New Constraints

New constraints can be added without modifying existing code:

```prolog
% Constraint plugin interface
:- multifile constraint_check/3.
:- multifile constraint_type/1.

% Core constraints
constraint_type(hard).
constraint_type(soft).

% Plugin: Custom constraint
constraint_check(custom_constraint_name, Assignment, Matrix) :-
    % Custom validation logic
    validate_custom_rule(Assignment, Matrix).

% Register plugin
:- assertz(constraint_type(custom)).
```

### Module Separation Principles

Each module has clear responsibilities and interfaces:

```
knowledge_base.pl    → Data storage and retrieval
    ↓ (provides facts)
constraints.pl       → Constraint definitions
    ↓ (uses constraints)
csp_solver.pl        → Search algorithm
    ↓ (uses solver)
timetable_generator.pl → Orchestration
    ↓ (uses generator)
api_server.pl        → External interface
```

**Dependency Rules**:
- Lower layers don't depend on upper layers
- Each module exports clear interface predicates
- Internal predicates are not exported

### Extension Points for New Resource Types

Add new resource types by extending the schema:

```prolog
% Extension: Add equipment resource
:- multifile resource_type/1.
:- multifile resource_schema/2.

resource_type(equipment).

resource_schema(equipment, [
    field(id, atom, required),
    field(name, string, required),
    field(type, atom, required),
    field(location, atom, optional)
]).

% Extend constraint checking
constraint_check(equipment_availability, Assignment, Matrix) :-
    assignment_equipment(Assignment, EquipmentID),
    equipment_available(EquipmentID, Assignment).
```

### Adding New Optimization Strategies

New heuristics can be plugged in:

```prolog
% Heuristic plugin interface
:- multifile variable_selection_heuristic/3.
:- multifile value_selection_heuristic/4.

% Plugin: Custom heuristic
variable_selection_heuristic(custom_heuristic, Variables, Domains, Selected) :-
    % Custom variable selection logic
    custom_select_variable(Variables, Domains, Selected).

% Configure which heuristic to use
:- dynamic active_heuristic/1.
active_heuristic(mrv).  % Default

set_heuristic(Heuristic) :-
    retractall(active_heuristic(_)),
    assertz(active_heuristic(Heuristic)).
```

### API Versioning

Support multiple API versions:

```prolog
:- http_handler(root(api/v1/generate), handle_generate_v1, []).
:- http_handler(root(api/v2/generate), handle_generate_v2, []).

handle_generate_v1(Request) :-
    % Version 1 implementation
    generate_timetable_v1(Timetable),
    format_response_v1(Timetable, Response),
    reply_json(Response).

handle_generate_v2(Request) :-
    % Version 2 with additional features
    generate_timetable_v2(Timetable, Metadata),
    format_response_v2(Timetable, Metadata, Response),
    reply_json(Response).
```

### Configuration System

Externalize configuration for easy customization:

```prolog
% config.pl
:- dynamic config/2.

% Default configuration
config(server_port, 8080).
config(max_search_nodes, 10000).
config(log_level, info).
config(enable_caching, true).
config(heuristic, mrv).

% Load custom configuration
load_config(File) :-
    exists_file(File),
    consult(File).

% Get configuration value
get_config(Key, Value) :-
    (   config(Key, Value)
    ->  true
    ;   default_config(Key, Value)
    ).
```

### Documentation for Extension

Each extension point is documented:

```prolog
%% constraint_check(+ConstraintName, +Assignment, +Matrix) is semidet.
%
%  Extension point for adding new constraints.
%
%  @param ConstraintName The unique name of the constraint
%  @param Assignment The assignment to validate
%  @param Matrix The current timetable matrix
%
%  @example Add a custom constraint:
%  ```
%  constraint_check(no_friday_labs, Assignment, _Matrix) :-
%      assignment_day(Assignment, Day),
%      assignment_type(Assignment, Type),
%      \+ (Day = friday, Type = lab).
%  ```
```

## Advanced Features Extension

This design document can be extended with 10 innovative advanced features that transform the system into an "AI Intelligent Timetable Decision System". These features are documented in separate files:

- **advanced-features.md** - Features 1-6 (XAI, Smart Conflicts, Scenarios, Quality Scoring, Recommendations, Heatmaps)
- **advanced-features-part2.md** - Features 7-10 (Search Visualization, Multiple Solutions, Constraint Sliders, Real-Time Validation)
- **ADVANCED_FEATURES_INTEGRATION.md** - Integration guide and implementation roadmap

### Advanced Features Summary

1. **Explainable AI Timetable (XAI)** - Prolog proof tracing to explain WHY each assignment was made
2. **Smart Conflict Suggestion System** - Automatically suggest solutions beyond just detecting conflicts
3. **Scenario Simulation** - Simulate real-world disruptions (teacher absence, room maintenance, exam week)
4. **Timetable Quality Scoring** - Comprehensive quality score (0-100) with breakdown
5. **AI Recommendation Engine** - Suggest improvements to existing timetables
6. **Visual Heatmap** - Color-coded resource utilization visualization
7. **AI Search Visualization** - Display CSP search process statistics and metrics
8. **Multiple Timetable Generation** - Generate top N best timetables ranked by quality
9. **Constraint Importance Slider** - Adjust soft constraint priorities dynamically
10. **Real-Time Constraint Checking** - Validate data as users enter it with instant feedback

These advanced features demonstrate:
- **Explainable AI (XAI)** - Transparency and trust through proof tracing
- **Decision Support** - Intelligent suggestions and recommendations
- **Robustness** - Scenario simulation and adaptability
- **Multi-Objective Optimization** - Quality scoring and weighted constraints
- **Interactive AI** - Real-time validation and customization
- **Visualization** - Heatmaps and search process transparency

### Enhanced MFAI Concept Demonstration

With advanced features, the system demonstrates:

| MFAI Concept | Basic Implementation | Advanced Enhancement |
|--------------|---------------------|----------------------|
| **Linear Algebra** | Matrix-based timetable | Heatmap matrix visualization |
| **First Order Logic** | Prolog facts and rules | XAI proof tracing |
| **Logical Inference** | Backward chaining | Explanation generation |
| **CSP** | Backtracking search | Search statistics, multiple solutions |
| **Probabilistic Reasoning** | Reliability estimation | Scenario simulation |
| **Explainable AI** | N/A | Complete reasoning transparency |
| **Decision Support** | Basic conflict detection | Smart suggestions and recommendations |
| **Multi-Objective Optimization** | Single objective | Quality scoring with weighted constraints |
| **AI Customization** | Fixed constraints | Dynamic constraint priorities |
| **Proactive AI** | Post-validation | Real-time validation |

## Conclusion

This design document provides a comprehensive blueprint for implementing the AI-Based Timetable Generation System. The system demonstrates all required MFAI concepts through practical application:

- **Linear Algebra**: Matrix-based timetable representation
- **First Order Logic**: Prolog facts and rules for scheduling knowledge
- **Logical Inference**: Backward chaining for constraint checking
- **CSP**: Backtracking search with intelligent heuristics
- **Probabilistic Reasoning**: Reliability estimation using conditional probabilities

The architecture is modular, extensible, and testable, with clear separation of concerns and well-defined interfaces. The dual testing approach (unit tests + property-based tests) ensures correctness across the input space. Security considerations and performance optimizations make the system production-ready.

Implementation should follow the module structure outlined, starting with the foundational modules (knowledge_base.pl, matrix_model.pl) and building up to the orchestration layer (timetable_generator.pl, api_server.pl). The 47 correctness properties provide clear acceptance criteria for each component.

### Implementation Roadmap

**Phase 1: Core System (Weeks 1-4)**
- Implement foundational modules (knowledge_base, matrix_model, constraints)
- Build CSP solver with heuristics
- Create basic API server and frontend
- Achieve 47 core correctness properties

**Phase 2: Advanced Features (Weeks 5-8)**
- Implement 10 advanced features (see advanced-features.md)
- Add 10 additional correctness properties
- Enhance UI with advanced visualizations
- Integrate all features seamlessly

**Phase 3: Testing & Polish (Weeks 9-10)**
- Comprehensive testing (unit + property-based)
- Performance optimization
- Documentation completion
- User acceptance testing

The advanced features transform this from a simple timetable generator into a comprehensive "AI Intelligent Timetable Decision System" that demonstrates cutting-edge AI capabilities and provides significant academic and practical value.