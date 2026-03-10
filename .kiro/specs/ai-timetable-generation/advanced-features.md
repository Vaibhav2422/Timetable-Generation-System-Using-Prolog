# Advanced Features: AI Intelligent Timetable Decision System

This document describes 10 innovative advanced features that transform the basic timetable generator into an "AI Intelligent Timetable Decision System" demonstrating cutting-edge AI capabilities.

## Feature 1: Explainable AI Timetable (XAI)

### Overview
Implement Prolog proof tracing to explain WHY each assignment was made, demonstrating Explainable AI (XAI) principles. This provides transparency and builds trust in the AI system's decisions.

### Backend Implementation

#### New Module: xai_explainer.pl

**Key Predicates**:

```prolog
%% explain_assignment(+ClassID, +SubjectID, +TeacherID, +RoomID, +SlotID, -Explanation) is det.
%
% Generate detailed explanation for why a specific assignment was made.
% Uses Prolog's proof tracing to collect all justification rules.
%
explain_assignment(ClassID, SubjectID, TeacherID, RoomID, SlotID, Explanation) :-
    % Collect all reasoning steps
    findall(Step, trace_assignment_reason(ClassID, SubjectID, TeacherID, RoomID, SlotID, Step), Steps),
    format_explanation_steps(Steps, Explanation).

% Trace individual reasoning steps
trace_assignment_reason(ClassID, SubjectID, TeacherID, RoomID, SlotID, 
                       step(1, qualification, Message)) :-
    qualified(TeacherID, SubjectID),
    teacher(TeacherID, TName, _, _, _),
    subject(SubjectID, SName, _, _, _),
    format(atom(Message), '~w is qualified to teach ~w', [TName, SName]).

trace_assignment_reason(ClassID, SubjectID, TeacherID, RoomID, SlotID,
                       step(2, room_suitability, Message)) :-
    subject(SubjectID, _, _, Type, _),
    suitable_room(RoomID, Type),
    room(RoomID, RName, _, RType),
    format(atom(Message), '~w (type: ~w) supports ~w sessions', [RName, RType, Type]).

trace_assignment_reason(ClassID, SubjectID, TeacherID, RoomID, SlotID,
                       step(3, availability, Message)) :-
    teacher_available(TeacherID, SlotID),
    timeslot(SlotID, Day, Period, StartTime, _),
    teacher(TeacherID, TName, _, _, _),
    format(atom(Message), '~w is available at ~w ~w (~w)', [TName, Day, Period, StartTime]).

trace_assignment_reason(ClassID, SubjectID, TeacherID, RoomID, SlotID,
                       step(4, no_conflicts, Message)) :-
    % Check no conflicts exist
    \+ has_teacher_conflict(TeacherID, SlotID),
    \+ has_room_conflict(RoomID, SlotID),
    Message = 'No teacher or room conflicts detected'.

trace_assignment_reason(ClassID, SubjectID, TeacherID, RoomID, SlotID,
                       step(5, optimization, Message)) :-
    calculate_assignment_quality(TeacherID, RoomID, SlotID, Quality),
    format(atom(Message), 'This assignment optimizes workload balance (quality score: ~2f)', [Quality]).

% Format explanation steps into readable text
format_explanation_steps(Steps, Explanation) :-
    sort(Steps, SortedSteps),
    maplist(format_step, SortedSteps, Lines),
    atomic_list_concat(Lines, '\n', Explanation).

format_step(step(Num, Category, Message), FormattedLine) :-
    format(atom(FormattedLine), '~w. ~w', [Num, Message]).

% Calculate quality score for an assignment
calculate_assignment_quality(TeacherID, RoomID, SlotID, Quality) :-
    teacher_workload_score(TeacherID, WorkloadScore),
    room_utilization_score(RoomID, UtilScore),
    time_preference_score(SlotID, TimeScore),
    Quality is (WorkloadScore + UtilScore + TimeScore) / 3.

teacher_workload_score(TeacherID, Score) :-
    get_current_timetable(Timetable),
    count_teacher_assignments(TeacherID, Timetable, Count),
    teacher(TeacherID, _, _, MaxLoad, _),
    Score is 1.0 - (Count / MaxLoad).

room_utilization_score(RoomID, Score) :-
    get_current_timetable(Timetable),
    count_room_assignments(RoomID, Timetable, Count),
    get_all_timeslots(Slots),
    length(Slots, TotalSlots),
    Score is Count / TotalSlots.

time_preference_score(SlotID, Score) :-
    timeslot(SlotID, _, Period, _, _),
    (Period =< 4 -> Score = 1.0 ;  % Morning preferred
     Period =< 6 -> Score = 0.8 ;  % Afternoon acceptable
     Score = 0.5).                  % Evening less preferred
```

### API Endpoint

```prolog
% New endpoint in api_server.pl
:- http_handler(root(api/explain_detailed), handle_explain_detailed, []).

handle_explain_detailed(Request) :-
    cors_headers,
    member(method(post), Request),
    http_read_json(Request, JSONData),
    get_dict(class_id, JSONData, ClassID),
    get_dict(subject_id, JSONData, SubjectID),
    get_dict(teacher_id, JSONData, TeacherID),
    get_dict(room_id, JSONData, RoomID),
    get_dict(slot_id, JSONData, SlotID),
    explain_assignment(ClassID, SubjectID, TeacherID, RoomID, SlotID, Explanation),
    reply_json_dict(_{status: success, explanation: Explanation}).
```

### Frontend Implementation

**HTML Addition** (in index.html):
```html
<!-- Explanation Modal Enhancement -->
<div id="explanation-modal" class="modal hidden">
    <div class="modal-content">
        <span class="close">&times;</span>
        <h3>Assignment Explanation (XAI)</h3>
        <div id="explanation-steps" class="explanation-container"></div>
        <div id="explanation-quality-score"></div>
    </div>
</div>
```

**CSS Addition** (in style.css):
```css
.explanation-container {
    background-color: #f8f9fa;
    padding: 1.5rem;
    border-radius: 8px;
    margin: 1rem 0;
}

.explanation-step {
    padding: 0.75rem;
    margin: 0.5rem 0;
    background-color: white;
    border-left: 4px solid var(--secondary-color);
    border-radius: 4px;
}

.explanation-step.qualification { border-left-color: #27ae60; }
.explanation-step.room_suitability { border-left-color: #3498db; }
.explanation-step.availability { border-left-color: #f39c12; }
.explanation-step.no_conflicts { border-left-color: #9b59b6; }
.explanation-step.optimization { border-left-color: #e74c3c; }
```

**JavaScript Addition** (in script.js):
```javascript
// Enhanced explanation with XAI
async function showDetailedExplanation(assignment) {
    try {
        const response = await fetch(`${API_BASE}/explain_detailed`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                class_id: assignment.class_id,
                subject_id: assignment.subject_id,
                teacher_id: assignment.teacher_id,
                room_id: assignment.room_id,
                slot_id: assignment.slot_id
            })
        });
        const result = await response.json();
        
        if (result.status === 'success') {
            displayXAIExplanation(result.explanation);
        }
    } catch (error) {
        showNotification('Error fetching explanation: ' + error.message, 'error');
    }
}

function displayXAIExplanation(explanation) {
    const modal = document.getElementById('explanation-modal');
    const container = document.getElementById('explanation-steps');
    
    const steps = explanation.split('\n');
    container.innerHTML = '';
    
    steps.forEach(step => {
        const stepDiv = document.createElement('div');
        stepDiv.className = 'explanation-step';
        stepDiv.textContent = step;
        container.appendChild(stepDiv);
    });
    
    modal.classList.add('active');
}
```

### MFAI Concept Demonstration

This feature demonstrates:
- **Logical Inference**: Traces Prolog's backward chaining to show reasoning steps
- **First Order Logic**: Uses FOL rules to justify each decision
- **Explainable AI**: Provides transparency in AI decision-making

---

## Feature 2: Smart Conflict Suggestion System

### Overview
Beyond detecting conflicts, automatically suggest solutions using AI reasoning. This demonstrates AI decision-support capabilities.

### Backend Implementation

#### New Module: conflict_resolver.pl

```prolog
%% suggest_fix(+Conflict, -Suggestions) is det.
%
% Generate intelligent suggestions to resolve a conflict.
%
suggest_fix(teacher_conflict(TeacherID, SlotID, Sessions), Suggestions) :-
    findall(Suggestion, 
            suggest_teacher_conflict_fix(TeacherID, SlotID, Sessions, Suggestion),
            Suggestions).

% Suggestion 1: Move one session to alternative time slot
suggest_teacher_conflict_fix(TeacherID, SlotID, [Session1, Session2|_], Suggestion) :-
    find_alternative_slots(TeacherID, Session1, AlternativeSlots),
    AlternativeSlots \= [],
    AlternativeSlots = [BestSlot|_],
    timeslot(BestSlot, Day, Period, StartTime, _),
    session_details(Session1, ClassID, SubjectID),
    class(ClassID, ClassName, _),
    subject(SubjectID, SubjectName, _, _, _),
    format(atom(Suggestion), 
           'Move "~w - ~w" to ~w Period ~w (~w)',
           [ClassName, SubjectName, Day, Period, StartTime]).

% Suggestion 2: Assign alternative teacher
suggest_teacher_conflict_fix(TeacherID, SlotID, [Session1|_], Suggestion) :-
    session_details(Session1, ClassID, SubjectID),
    find_alternative_teachers(SubjectID, SlotID, TeacherID, AlternativeTeachers),
    AlternativeTeachers \= [],
    AlternativeTeachers = [AltTeacherID|_],
    teacher(AltTeacherID, AltTeacherName, _, _, _),
    class(ClassID, ClassName, _),
    subject(SubjectID, SubjectName, _, _, _),
    format(atom(Suggestion),
           'Assign ~w as alternative teacher for "~w - ~w"',
           [AltTeacherName, ClassName, SubjectName]).

% Suggestion 3: Swap with another session
suggest_teacher_conflict_fix(TeacherID, SlotID, [Session1|_], Suggestion) :-
    find_swappable_sessions(TeacherID, Session1, SwappableSessions),
    SwappableSessions \= [],
    SwappableSessions = [SwapSession|_],
    session_details(SwapSession, SwapClassID, SwapSubjectID),
    class(SwapClassID, SwapClassName, _),
    subject(SwapSubjectID, SwapSubjectName, _, _, _),
    format(atom(Suggestion),
           'Swap with "~w - ~w" session',
           [SwapClassName, SwapSubjectName]).

% Find alternative time slots for a session
find_alternative_slots(TeacherID, Session, AlternativeSlots) :-
    session_details(Session, ClassID, SubjectID),
    findall(SlotID,
            (timeslot(SlotID, _, _, _, _),
             teacher_available(TeacherID, SlotID),
             \+ has_teacher_conflict(TeacherID, SlotID),
             suitable_for_class(ClassID, SlotID)),
            AlternativeSlots).

% Find alternative teachers for a subject
find_alternative_teachers(SubjectID, SlotID, CurrentTeacherID, AlternativeTeachers) :-
    findall(TeacherID,
            (qualified(TeacherID, SubjectID),
             TeacherID \= CurrentTeacherID,
             teacher_available(TeacherID, SlotID),
             \+ has_teacher_conflict(TeacherID, SlotID)),
            AlternativeTeachers).

% Find sessions that can be swapped
find_swappable_sessions(TeacherID, Session, SwappableSessions) :-
    session_details(Session, ClassID, SubjectID),
    get_current_timetable(Timetable),
    findall(OtherSession,
            (assignment_in_timetable(Timetable, OtherSession),
             can_swap_sessions(Session, OtherSession)),
            SwappableSessions).

can_swap_sessions(Session1, Session2) :-
    session_details(Session1, Class1, Subject1),
    session_details(Session2, Class2, Subject2),
    Class1 \= Class2,  % Different classes
    % Check if swap would resolve conflicts
    would_resolve_conflict_if_swapped(Session1, Session2).

% Apply a suggested fix
apply_fix(Suggestion, UpdatedTimetable) :-
    parse_suggestion(Suggestion, FixType, Parameters),
    execute_fix(FixType, Parameters, UpdatedTimetable).

execute_fix(move_session, [SessionID, NewSlotID], UpdatedTimetable) :-
    get_current_timetable(CurrentTimetable),
    remove_session(SessionID, CurrentTimetable, PartialTimetable),
    assign_session(SessionID, NewSlotID, PartialTimetable, UpdatedTimetable).

execute_fix(change_teacher, [SessionID, NewTeacherID], UpdatedTimetable) :-
    get_current_timetable(CurrentTimetable),
    update_session_teacher(SessionID, NewTeacherID, CurrentTimetable, UpdatedTimetable).

execute_fix(swap_sessions, [Session1ID, Session2ID], UpdatedTimetable) :-
    get_current_timetable(CurrentTimetable),
    swap_session_slots(Session1ID, Session2ID, CurrentTimetable, UpdatedTimetable).
```

### API Endpoint

```prolog
:- http_handler(root(api/suggest_fixes), handle_suggest_fixes, []).
:- http_handler(root(api/apply_fix), handle_apply_fix, []).

handle_suggest_fixes(Request) :-
    cors_headers,
    member(method(get), Request),
    get_current_timetable(Timetable),
    detect_conflicts(Timetable, Conflicts),
    findall(ConflictWithSuggestions,
            (member(Conflict, Conflicts),
             suggest_fix(Conflict, Suggestions),
             ConflictWithSuggestions = _{conflict: Conflict, suggestions: Suggestions}),
            AllSuggestions),
    reply_json_dict(_{status: success, conflict_suggestions: AllSuggestions}).

handle_apply_fix(Request) :-
    cors_headers,
    member(method(post), Request),
    http_read_json(Request, JSONData),
    get_dict(suggestion, JSONData, Suggestion),
    apply_fix(Suggestion, UpdatedTimetable),
    format_timetable(UpdatedTimetable, json, JSONOutput),
    reply_json_dict(_{status: success, timetable: JSONOutput, message: 'Fix applied successfully'}).
```

### Frontend Implementation

**HTML Addition**:
```html
<div id="conflict-suggestions-panel" class="panel">
    <h3>Smart Conflict Resolution</h3>
    <div id="conflict-list"></div>
</div>
```

**JavaScript Addition**:
```javascript
async function loadConflictSuggestions() {
    try {
        const response = await fetch(`${API_BASE}/suggest_fixes`);
        const result = await response.json();
        
        if (result.status === 'success') {
            displayConflictSuggestions(result.conflict_suggestions);
        }
    } catch (error) {
        console.error('Error loading suggestions:', error);
    }
}

function displayConflictSuggestions(conflictSuggestions) {
    const container = document.getElementById('conflict-list');
    container.innerHTML = '';
    
    conflictSuggestions.forEach((item, index) => {
        const conflictDiv = document.createElement('div');
        conflictDiv.className = 'conflict-item';
        
        const conflictDesc = document.createElement('p');
        conflictDesc.className = 'conflict-description';
        conflictDesc.textContent = item.conflict.description;
        conflictDiv.appendChild(conflictDesc);
        
        const suggestionsDiv = document.createElement('div');
        suggestionsDiv.className = 'suggestions-list';
        
        item.suggestions.forEach((suggestion, idx) => {
            const suggestionBtn = document.createElement('button');
            suggestionBtn.className = 'suggestion-btn';
            suggestionBtn.textContent = `Fix ${idx + 1}: ${suggestion}`;
            suggestionBtn.onclick = () => applyFix(suggestion);
            suggestionsDiv.appendChild(suggestionBtn);
        });
        
        conflictDiv.appendChild(suggestionsDiv);
        container.appendChild(conflictDiv);
    });
}

async function applyFix(suggestion) {
    try {
        const response = await fetch(`${API_BASE}/apply_fix`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ suggestion: suggestion })
        });
        const result = await response.json();
        
        if (result.status === 'success') {
            showNotification('Fix applied successfully!', 'success');
            currentTimetable = result.timetable;
            renderTimetable(result.timetable);
            loadConflictSuggestions();  // Refresh suggestions
        }
    } catch (error) {
        showNotification('Error applying fix: ' + error.message, 'error');
    }
}
```

### MFAI Concept Demonstration

This feature demonstrates:
- **Constraint Satisfaction**: Finds alternative assignments that satisfy constraints
- **Logical Inference**: Reasons about which fixes would resolve conflicts
- **AI Decision Support**: Provides actionable recommendations to users

---

## Feature 3: Scenario Simulation

### Overview
Allow users to simulate real-world disruptions (teacher absence, room maintenance, extra class added, exam week) and see how the AI adapts. This demonstrates AI robustness and adaptability.

### Backend Implementation

#### New Module: scenario_simulator.pl

```prolog
%% simulate_scenario(+ScenarioType, +Parameters, -NewTimetable) is det.
%
% Simulate a real-world scenario and generate adapted timetable.
%
simulate_scenario(teacher_absence, Parameters, NewTimetable) :-
    get_dict(teacher_id, Parameters, TeacherID),
    get_dict(days, Parameters, Days),
    get_current_timetable(CurrentTimetable),
    mark_teacher_unavailable(TeacherID, Days, CurrentTimetable, AffectedSessions),
    reassign_sessions(AffectedSessions, CurrentTimetable, NewTimetable).

simulate_scenario(room_maintenance, Parameters, NewTimetable) :-
    get_dict(room_id, Parameters, RoomID),
    get_dict(slots, Parameters, Slots),
    get_current_timetable(CurrentTimetable),
    mark_room_unavailable(RoomID, Slots, CurrentTimetable, AffectedSessions),
    reassign_sessions(AffectedSessions, CurrentTimetable, NewTimetable).

simulate_scenario(extra_class, Parameters, NewTimetable) :-
    get_dict(class_id, Parameters, ClassID),
    get_dict(subject_id, Parameters, SubjectID),
    get_dict(sessions_needed, Parameters, SessionsNeeded),
    get_current_timetable(CurrentTimetable),
    create_extra_sessions(ClassID, SubjectID, SessionsNeeded, ExtraSessions),
    assign_extra_sessions(ExtraSessions, CurrentTimetable, NewTimetable).

simulate_scenario(exam_week, Parameters, NewTimetable) :-
    get_dict(week_start, Parameters, WeekStart),
    get_current_timetable(CurrentTimetable),
    adjust_for_exam_week(WeekStart, CurrentTimetable, NewTimetable).

% Mark teacher unavailable for specific days
mark_teacher_unavailable(TeacherID, Days, Timetable, AffectedSessions) :-
    get_all_assignments(Timetable, Assignments),
    findall(Assignment,
            (member(Assignment, Assignments),
             assignment_teacher(Assignment, TeacherID),
             assignment_day(Assignment, Day),
             member(Day, Days)),
            AffectedSessions).

% Reassign affected sessions
reassign_sessions([], Timetable, Timetable).
reassign_sessions([Session|Rest], CurrentTimetable, FinalTimetable) :-
    find_alternative_assignment(Session, Alternative),
    update_assignment(Session, Alternative, CurrentTimetable, UpdatedTimetable),
    reassign_sessions(Rest, UpdatedTimetable, FinalTimetable).

% Find alternative assignment for a session
find_alternative_assignment(Session, Alternative) :-
    session_details(Session, ClassID, SubjectID),
    assignment_slot(Session, OriginalSlot),
    % Find alternative teacher
    find_alternative_teachers(SubjectID, OriginalSlot, _, [AltTeacher|_]),
    % Keep same slot if possible, or find new slot
    (   teacher_available(AltTeacher, OriginalSlot)
    ->  Alternative = alternative(AltTeacher, OriginalSlot)
    ;   find_alternative_slots(AltTeacher, Session, [AltSlot|_]),
        Alternative = alternative(AltTeacher, AltSlot)
    ).

% Adjust timetable for exam week
adjust_for_exam_week(WeekStart, CurrentTimetable, NewTimetable) :-
    % Reduce session durations
    % Avoid back-to-back sessions
    % Prioritize theory over labs
    get_all_assignments(CurrentTimetable, Assignments),
    filter_exam_week_assignments(Assignments, WeekStart, FilteredAssignments),
    redistribute_assignments(FilteredAssignments, NewTimetable).

% Compare scenarios
compare_scenarios(Scenario1, Scenario2, Comparison) :-
    simulate_scenario(Scenario1, _, Timetable1),
    simulate_scenario(Scenario2, _, Timetable2),
    calculate_quality_score(Timetable1, Score1),
    calculate_quality_score(Timetable2, Score2),
    schedule_reliability(Timetable1, Reliability1),
    schedule_reliability(Timetable2, Reliability2),
    Comparison = _{
        scenario1: _{quality: Score1, reliability: Reliability1},
        scenario2: _{quality: Score2, reliability: Reliability2},
        recommendation: (Score1 > Score2 -> scenario1 ; scenario2)
    }.
```

### API Endpoints

```prolog
:- http_handler(root(api/simulate), handle_simulate, []).
:- http_handler(root(api/compare_scenarios), handle_compare_scenarios, []).

handle_simulate(Request) :-
    cors_headers,
    member(method(post), Request),
    http_read_json(Request, JSONData),
    get_dict(scenario_type, JSONData, ScenarioType),
    get_dict(parameters, JSONData, Parameters),
    simulate_scenario(ScenarioType, Parameters, NewTimetable),
    format_timetable(NewTimetable, json, JSONOutput),
    schedule_reliability(NewTimetable, Reliability),
    reply_json_dict(_{
        status: success,
        scenario_type: ScenarioType,
        original_timetable: current,
        simulated_timetable: JSONOutput,
        reliability: Reliability
    }).

handle_compare_scenarios(Request) :-
    cors_headers,
    member(method(post), Request),
    http_read_json(Request, JSONData),
    get_dict(scenarios, JSONData, Scenarios),
    maplist(simulate_and_score, Scenarios, Results),
    reply_json_dict(_{status: success, comparison: Results}).
```

### Frontend Implementation

**HTML Addition**:
```html
<section id="scenario-section" class="section">
    <h2>Scenario Simulation</h2>
    <div class="scenario-controls">
        <select id="scenario-type">
            <option value="teacher_absence">Teacher Absence</option>
            <option value="room_maintenance">Room Maintenance</option>
            <option value="extra_class">Extra Class Added</option>
            <option value="exam_week">Exam Week</option>
        </select>
        <div id="scenario-parameters"></div>
        <button id="simulate-btn" class="primary-btn">Simulate Scenario</button>
    </div>
    <div id="scenario-comparison">
        <div id="original-timetable-preview"></div>
        <div id="simulated-timetable-preview"></div>
    </div>
</section>
```

**JavaScript Addition**:
```javascript
async function simulateScenario(scenarioType, parameters) {
    try {
        const response = await fetch(`${API_BASE}/simulate`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                scenario_type: scenarioType,
                parameters: parameters
            })
        });
        const result = await response.json();
        
        if (result.status === 'success') {
            displayScenarioComparison(currentTimetable, result.simulated_timetable);
            showNotification(`Scenario simulated. New reliability: ${(result.reliability * 100).toFixed(1)}%`, 'info');
        }
    } catch (error) {
        showNotification('Simulation failed: ' + error.message, 'error');
    }
}

function displayScenarioComparison(original, simulated) {
    const originalDiv = document.getElementById('original-timetable-preview');
    const simulatedDiv = document.getElementById('simulated-timetable-preview');
    
    originalDiv.innerHTML = '<h3>Original Timetable</h3>';
    renderMiniTimetable(original, originalDiv);
    
    simulatedDiv.innerHTML = '<h3>Simulated Timetable</h3>';
    renderMiniTimetable(simulated, simulatedDiv);
    
    highlightDifferences(original, simulated);
}

document.getElementById('simulate-btn').addEventListener('click', () => {
    const scenarioType = document.getElementById('scenario-type').value;
    const parameters = collectScenarioParameters(scenarioType);
    simulateScenario(scenarioType, parameters);
});
```

### MFAI Concept Demonstration

This feature demonstrates:
- **Constraint Satisfaction**: Re-solves CSP under new constraints
- **Probabilistic Reasoning**: Calculates reliability under different scenarios
- **AI Adaptability**: Shows how AI handles dynamic changes

---

## Feature 4: Timetable Quality Scoring

### Overview
Calculate comprehensive quality score (0-100) based on multiple criteria: hard constraint satisfaction, teacher workload balance, room utilization efficiency, and schedule compactness.

### Backend Implementation

#### New Module: quality_scorer.pl

```prolog
%% calculate_quality_score(+Timetable, -Score) is det.
%
% Calculate comprehensive quality score (0-100) for a timetable.
% Formula: 40% hard constraints + 20% workload + 20% utilization + 20% compactness
%
calculate_quality_score(Timetable, Score) :-
    hard_constraint_score(Timetable, HardScore),
    workload_balance_score(Timetable, WorkloadScore),
    room_utilization_score(Timetable, UtilScore),
    schedule_compactness_score(Timetable, CompactScore),
    Score is (HardScore * 0.4 + WorkloadScore * 0.2 + UtilScore * 0.2 + CompactScore * 0.2) * 100.

% Hard constraint satisfaction score (0.0 - 1.0)
hard_constraint_score(Timetable, Score) :-
    get_all_assignments(Timetable, Assignments),
    length(Assignments, Total),
    count_constraint_violations(Assignments, Timetable, Violations),
    Score is (Total - Violations) / Total.

count_constraint_violations([], _, 0).
count_constraint_violations([Assignment|Rest], Timetable, Count) :-
    (   violates_any_constraint(Assignment, Timetable)
    ->  count_constraint_violations(Rest, Timetable, RestCount),
        Count is RestCount + 1
    ;   count_constraint_violations(Rest, Timetable, Count)
    ).

% Teacher workload balance score (0.0 - 1.0)
workload_balance_score(Timetable, Score) :-
    get_all_teachers(Teachers),
    maplist(teacher_workload_ratio(Timetable), Teachers, Ratios),
    calculate_balance_metric(Ratios, Score).

teacher_workload_ratio(Timetable, TeacherID, Ratio) :-
    count_teacher_assignments(TeacherID, Timetable, Assigned),
    teacher(TeacherID, _, _, MaxLoad, _),
    Ratio is Assigned / MaxLoad.

calculate_balance_metric(Ratios, Score) :-
    mean(Ratios, Mean),
    maplist(deviation_from_mean(Mean), Ratios, Deviations),
    sum_list(Deviations, TotalDeviation),
    length(Ratios, N),
    AvgDeviation is TotalDeviation / N,
    Score is max(0, 1.0 - AvgDeviation).

deviation_from_mean(Mean, Value, Deviation) :-
    Deviation is abs(Value - Mean).

% Room utilization efficiency score (0.0 - 1.0)
room_utilization_score(Timetable, Score) :-
    get_all_rooms(Rooms),
    get_all_timeslots(Slots),
    length(Slots, TotalSlots),
    maplist(room_utilization_ratio(Timetable, TotalSlots), Rooms, Ratios),
    mean(Ratios, Score).

room_utilization_ratio(Timetable, TotalSlots, RoomID, Ratio) :-
    count_room_assignments(RoomID, Timetable, Occupied),
    Ratio is Occupied / TotalSlots.

% Schedule compactness score (0.0 - 1.0)
% Measures how few gaps exist in class schedules
schedule_compactness_score(Timetable, Score) :-
    get_all_classes(Classes),
    maplist(class_gap_ratio(Timetable), Classes, GapRatios),
    mean(GapRatios, AvgGapRatio),
    Score is 1.0 - AvgGapRatio.

class_gap_ratio(Timetable, ClassID, Ratio) :-
    get_class_schedule(ClassID, Timetable, Schedule),
    count_gaps(Schedule, Gaps),
    length(Schedule, Sessions),
    (Sessions > 0 -> Ratio is Gaps / Sessions ; Ratio = 0).

% Count gaps in a schedule
count_gaps(Schedule, Gaps) :-
    sort_schedule_by_time(Schedule, SortedSchedule),
    count_gaps_in_sorted(SortedSchedule, Gaps).

count_gaps_in_sorted([], 0).
count_gaps_in_sorted([_], 0).
count_gaps_in_sorted([Slot1, Slot2|Rest], Gaps) :-
    (   are_consecutive_slots(Slot1, Slot2)
    ->  count_gaps_in_sorted([Slot2|Rest], Gaps)
    ;   count_gaps_in_sorted([Slot2|Rest], RestGaps),
        Gaps is RestGaps + 1
    ).

% Get quality breakdown
quality_breakdown(Timetable, Breakdown) :-
    hard_constraint_score(Timetable, HardScore),
    workload_balance_score(Timetable, WorkloadScore),
    room_utilization_score(Timetable, UtilScore),
    schedule_compactness_score(Timetable, CompactScore),
    Breakdown = _{
        hard_constraints: HardScore,
        workload_balance: WorkloadScore,
        room_utilization: UtilScore,
        schedule_compactness: CompactScore,
        overall: (HardScore * 0.4 + WorkloadScore * 0.2 + UtilScore * 0.2 + CompactScore * 0.2)
    }.
```

### API Endpoint

```prolog
:- http_handler(root(api/quality_score), handle_quality_score, []).

handle_quality_score(Request) :-
    cors_headers,
    member(method(get), Request),
    get_current_timetable(Timetable),
    calculate_quality_score(Timetable, Score),
    quality_breakdown(Timetable, Breakdown),
    reply_json_dict(_{
        status: success,
        overall_score: Score,
        breakdown: Breakdown
    }).
```

### Frontend Implementation

**HTML Addition**:
```html
<div id="quality-display" class="quality-panel">
    <h3>Timetable Quality Score</h3>
    <div class="quality-score-circle">
        <span id="quality-score-value">--</span>
    </div>
    <div class="quality-breakdown">
        <div class="quality-metric">
            <span class="metric-label">Hard Constraints</span>
            <div class="metric-bar">
                <div id="hard-constraints-bar" class="metric-fill"></div>
            </div>
            <span id="hard-constraints-value" class="metric-value">--</span>
        </div>
        <div class="quality-metric">
            <span class="metric-label">Workload Balance</span>
            <div class="metric-bar">
                <div id="workload-bar" class="metric-fill"></div>
            </div>
            <span id="workload-value" class="metric-value">--</span>
        </div>
        <div class="quality-metric">
            <span class="metric-label">Room Utilization</span>
            <div class="metric-bar">
                <div id="utilization-bar" class="metric-fill"></div>
            </div>
            <span id="utilization-value" class="metric-value">--</span>
        </div>
        <div class="quality-metric">
            <span class="metric-label">Schedule Compactness</span>
            <div class="metric-bar">
                <div id="compactness-bar" class="metric-fill"></div>
            </div>
            <span id="compactness-value" class="metric-value">--</span>
        </div>
    </div>
</div>
```

**CSS Addition**:
```css
.quality-score-circle {
    width: 150px;
    height: 150px;
    border-radius: 50%;
    border: 10px solid #ecf0f1;
    display: flex;
    align-items: center;
    justify-content: center;
    margin: 1rem auto;
    font-size: 3rem;
    font-weight: bold;
}

.quality-score-circle.high { border-color: var(--success-color); color: var(--success-color); }
.quality-score-circle.medium { border-color: var(--warning-color); color: var(--warning-color); }
.quality-score-circle.low { border-color: var(--danger-color); color: var(--danger-color); }

.quality-metric {
    margin: 1rem 0;
}

.metric-bar {
    width: 100%;
    height: 20px;
    background-color: #ecf0f1;
    border-radius: 10px;
    overflow: hidden;
    margin: 0.5rem 0;
}

.metric-fill {
    height: 100%;
    background-color: var(--secondary-color);
    transition: width 0.5s ease;
}
```

**JavaScript Addition**:
```javascript
async function loadQualityScore() {
    try {
        const response = await fetch(`${API_BASE}/quality_score`);
        const result = await response.json();
        
        if (result.status === 'success') {
            displayQualityScore(result.overall_score, result.breakdown);
        }
    } catch (error) {
        console.error('Error loading quality score:', error);
    }
}

function displayQualityScore(overallScore, breakdown) {
    const scoreCircle = document.querySelector('.quality-score-circle');
    const scoreValue = document.getElementById('quality-score-value');
    
    scoreValue.textContent = overallScore.toFixed(0);
    
    scoreCircle.classList.remove('high', 'medium', 'low');
    if (overallScore >= 80) {
        scoreCircle.classList.add('high');
    } else if (overallScore >= 60) {
        scoreCircle.classList.add('medium');
    } else {
        scoreCircle.classList.add('low');
    }
    
    // Update breakdown bars
    updateMetricBar('hard-constraints', breakdown.hard_constraints);
    updateMetricBar('workload', breakdown.workload_balance);
    updateMetricBar('utilization', breakdown.room_utilization);
    updateMetricBar('compactness', breakdown.schedule_compactness);
}

function updateMetricBar(metricId, value) {
    const bar = document.getElementById(`${metricId}-bar`);
    const valueSpan = document.getElementById(`${metricId}-value`);
    
    bar.style.width = (value * 100) + '%';
    valueSpan.textContent = (value * 100).toFixed(1) + '%';
}
```

### MFAI Concept Demonstration

This feature demonstrates:
- **Multi-Objective Optimization**: Balances multiple competing objectives
- **Quantitative Analysis**: Provides measurable quality metrics
- **AI Evaluation**: Assesses solution quality systematically

---

## Feature 5: AI Recommendation Engine

### Overview
Suggest improvements to existing timetables by analyzing optimization opportunities. This demonstrates AI advisory capabilities.

### Backend Implementation

#### New Module: recommendation_engine.pl

```prolog
%% recommend_improvements(+Timetable, -Recommendations) is det.
%
% Analyze timetable and suggest improvements.
%
recommend_improvements(Timetable, Recommendations) :-
    findall(Recommendation,
            find_improvement_opportunity(Timetable, Recommendation),
            Recommendations).

% Find room utilization improvements
find_improvement_opportunity(Timetable, Recommendation) :-
    identify_underutilized_rooms(Timetable, UnderutilizedRooms),
    member(RoomID, UnderutilizedRooms),
    find_room_swap_opportunity(RoomID, Timetable, SwapDetails),
    calculate_improvement_impact(SwapDetails, Impact),
    format_room_recommendation(SwapDetails, Impact, Recommendation).

% Find workload balance improvements
find_improvement_opportunity(Timetable, Recommendation) :-
    identify_workload_imbalance(Timetable, ImbalancedTeachers),
    member(TeacherID, ImbalancedTeachers),
    find_workload_redistribution(TeacherID, Timetable, RedistDetails),
    calculate_improvement_impact(RedistDetails, Impact),
    format_workload_recommendation(RedistDetails, Impact, Recommendation).

% Find schedule compactness improvements
find_improvement_opportunity(Timetable, Recommendation) :-
    identify_fragmented_schedules(Timetable, FragmentedClasses),
    member(ClassID, FragmentedClasses),
    find_compaction_opportunity(ClassID, Timetable, CompactDetails),
    calculate_improvement_impact(CompactDetails, Impact),
    format_compactness_recommendation(CompactDetails, Impact, Recommendation).

% Find back-to-back session reductions
find_improvement_opportunity(Timetable, Recommendation) :-
    identify_excessive_backtoback(Timetable, AffectedTeachers),
    member(TeacherID, AffectedTeachers),
    find_spacing_opportunity(TeacherID, Timetable, SpacingDetails),
    calculate_improvement_impact(SpacingDetails, Impact),
    format_spacing_recommendation(SpacingDetails, Impact, Recommendation).

% Identify underutilized rooms
identify_underutilized_rooms(Timetable, UnderutilizedRooms) :-
    get_all_rooms(Rooms),
    get_all_timeslots(Slots),
    length(Slots, TotalSlots),
    findall(RoomID,
            (member(RoomID, Rooms),
             count_room_assignments(RoomID, Timetable, Count),
             Utilization is Count / TotalSlots,
             Utilization < 0.5),  % Less than 50% utilized
            UnderutilizedRooms).

% Find room swap opportunity
find_room_swap_opportunity(UnderutilizedRoom, Timetable, SwapDetails) :-
    get_all_rooms(Rooms),
    member(OverutilizedRoom, Rooms),
    OverutilizedRoom \= UnderutilizedRoom,
    count_room_assignments(OverutilizedRoom, Timetable, OverCount),
    get_all_timeslots(Slots),
    length(Slots, TotalSlots),
    OverUtilization is OverCount / TotalSlots,
    OverUtilization > 0.8,  % More than 80% utilized
    find_movable_sessions(OverutilizedRoom, UnderutilizedRoom, Timetable, MovableSessions),
    MovableSessions \= [],
    SwapDetails = swap(MovableSessions, OverutilizedRoom, UnderutilizedRoom).

% Identify workload imbalance
identify_workload_imbalance(Timetable, ImbalancedTeachers) :-
    get_all_teachers(Teachers),
    maplist(teacher_workload_ratio(Timetable), Teachers, TeacherRatios),
    pairs_keys_values(TeacherRatios, Teachers, Ratios),
    mean(Ratios, MeanRatio),
    findall(TeacherID,
            (member(TeacherID-Ratio, TeacherRatios),
             abs(Ratio - MeanRatio) > 0.2),  % More than 20% deviation
            ImbalancedTeachers).

% Calculate improvement impact
calculate_improvement_impact(swap(Sessions, FromRoom, ToRoom), Impact) :-
    length(Sessions, NumSessions),
    Impact is NumSessions * 0.15.  % 15% improvement per session moved

calculate_improvement_impact(redistribute(Sessions, FromTeacher, ToTeacher), Impact) :-
    length(Sessions, NumSessions),
    Impact is NumSessions * 0.10.  % 10% improvement per session redistributed

calculate_improvement_impact(compact(Sessions, Gaps), Impact) :-
    Impact is Gaps * 0.05.  % 5% improvement per gap removed

% Format recommendations
format_room_recommendation(swap(Sessions, FromRoom, ToRoom), Impact, Recommendation) :-
    room(FromRoom, FromName, _, _),
    room(ToRoom, ToName, _, _),
    length(Sessions, NumSessions),
    format(atom(Description),
           'Move ~w sessions from ~w to ~w → improves room utilization by ~1f%',
           [NumSessions, FromName, ToName, Impact]),
    Recommendation = _{
        type: room_optimization,
        description: Description,
        impact: Impact,
        action: swap(Sessions, FromRoom, ToRoom),
        priority: (Impact > 0.2 -> high ; medium)
    }.

format_workload_recommendation(redistribute(Sessions, FromTeacher, ToTeacher), Impact, Recommendation) :-
    teacher(FromTeacher, FromName, _, _, _),
    teacher(ToTeacher, ToName, _, _, _),
    length(Sessions, NumSessions),
    format(atom(Description),
           'Reassign ~w sessions from ~w to ~w → improves workload balance by ~1f%',
           [NumSessions, FromName, ToName, Impact]),
    Recommendation = _{
        type: workload_balance,
        description: Description,
        impact: Impact,
        action: redistribute(Sessions, FromTeacher, ToTeacher),
        priority: (Impact > 0.15 -> high ; medium)
    }.

format_compactness_recommendation(compact(Sessions, Gaps), Impact, Recommendation) :-
    length(Sessions, NumSessions),
    format(atom(Description),
           'Rearrange ~w sessions to reduce ~w gaps → improves schedule compactness by ~1f%',
           [NumSessions, Gaps, Impact]),
    Recommendation = _{
        type: schedule_compactness,
        description: Description,
        impact: Impact,
        action: compact(Sessions, Gaps),
        priority: (Gaps > 3 -> high ; low)
    }.

% Apply recommendation
apply_recommendation(Recommendation, UpdatedTimetable) :-
    get_dict(action, Recommendation, Action),
    execute_recommendation_action(Action, UpdatedTimetable).

execute_recommendation_action(swap(Sessions, FromRoom, ToRoom), UpdatedTimetable) :-
    get_current_timetable(CurrentTimetable),
    move_sessions_to_room(Sessions, ToRoom, CurrentTimetable, UpdatedTimetable).

execute_recommendation_action(redistribute(Sessions, FromTeacher, ToTeacher), UpdatedTimetable) :-
    get_current_timetable(CurrentTimetable),
    reassign_sessions_to_teacher(Sessions, ToTeacher, CurrentTimetable, UpdatedTimetable).

execute_recommendation_action(compact(Sessions, _), UpdatedTimetable) :-
    get_current_timetable(CurrentTimetable),
    compact_sessions(Sessions, CurrentTimetable, UpdatedTimetable).
```

### API Endpoints

```prolog
:- http_handler(root(api/recommendations), handle_recommendations, []).
:- http_handler(root(api/apply_recommendation), handle_apply_recommendation, []).

handle_recommendations(Request) :-
    cors_headers,
    member(method(get), Request),
    get_current_timetable(Timetable),
    recommend_improvements(Timetable, Recommendations),
    sort_by_priority(Recommendations, SortedRecommendations),
    reply_json_dict(_{status: success, recommendations: SortedRecommendations}).

handle_apply_recommendation(Request) :-
    cors_headers,
    member(method(post), Request),
    http_read_json(Request, JSONData),
    get_dict(recommendation, JSONData, Recommendation),
    apply_recommendation(Recommendation, UpdatedTimetable),
    format_timetable(UpdatedTimetable, json, JSONOutput),
    calculate_quality_score(UpdatedTimetable, NewScore),
    reply_json_dict(_{
        status: success,
        timetable: JSONOutput,
        new_quality_score: NewScore,
        message: 'Recommendation applied successfully'
    }).
```

### Frontend Implementation

**HTML Addition**:
```html
<div id="recommendations-panel" class="panel">
    <h3>AI Recommendations</h3>
    <button id="get-recommendations-btn" class="secondary-btn">Optimize My Timetable</button>
    <div id="recommendations-list"></div>
</div>
```

**JavaScript Addition**:
```javascript
async function loadRecommendations() {
    try {
        const response = await fetch(`${API_BASE}/recommendations`);
        const result = await response.json();
        
        if (result.status === 'success') {
            displayRecommendations(result.recommendations);
        }
    } catch (error) {
        showNotification('Error loading recommendations: ' + error.message, 'error');
    }
}

function displayRecommendations(recommendations) {
    const container = document.getElementById('recommendations-list');
    container.innerHTML = '';
    
    if (recommendations.length === 0) {
        container.innerHTML = '<p class="no-recommendations">Your timetable is already optimized!</p>';
        return;
    }
    
    recommendations.forEach((rec, index) => {
        const recDiv = document.createElement('div');
        recDiv.className = `recommendation-item priority-${rec.priority}`;
        
        const header = document.createElement('div');
        header.className = 'recommendation-header';
        header.innerHTML = `
            <span class="priority-badge">${rec.priority.toUpperCase()}</span>
            <span class="impact-badge">+${(rec.impact * 100).toFixed(1)}%</span>
        `;
        
        const description = document.createElement('p');
        description.className = 'recommendation-description';
        description.textContent = rec.description;
        
        const applyBtn = document.createElement('button');
        applyBtn.className = 'apply-recommendation-btn';
        applyBtn.textContent = 'Apply This Recommendation';
        applyBtn.onclick = () => applyRecommendation(rec);
        
        recDiv.appendChild(header);
        recDiv.appendChild(description);
        recDiv.appendChild(applyBtn);
        container.appendChild(recDiv);
    });
}

async function applyRecommendation(recommendation) {
    try {
        const response = await fetch(`${API_BASE}/apply_recommendation`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ recommendation: recommendation })
        });
        const result = await response.json();
        
        if (result.status === 'success') {
            currentTimetable = result.timetable;
            renderTimetable(result.timetable);
            showNotification(`Applied! New quality score: ${result.new_quality_score.toFixed(1)}`, 'success');
            loadRecommendations();  // Refresh recommendations
            loadQualityScore();     // Update quality display
        }
    } catch (error) {
        showNotification('Error applying recommendation: ' + error.message, 'error');
    }
}

document.getElementById('get-recommendations-btn').addEventListener('click', loadRecommendations);
```

### MFAI Concept Demonstration

This feature demonstrates:
- **AI Advisory Systems**: Provides intelligent suggestions
- **Optimization Analysis**: Identifies improvement opportunities
- **Decision Support**: Helps users make informed choices

---

## Feature 6: Visual Heatmap

### Overview
Display resource utilization as color-coded heatmaps for rooms, teachers, and time slots. This enhances decision support visualization.

### Backend Implementation

#### New Module: heatmap_generator.pl

```prolog
%% calculate_utilization(+ResourceType, +ResourceID, -Percentage) is det.
%
% Calculate utilization percentage for a resource.
%
calculate_utilization(room, RoomID, Percentage) :-
    get_current_timetable(Timetable),
    count_room_assignments(RoomID, Timetable, Occupied),
    get_all_timeslots(Slots),
    length(Slots, Total),
    Percentage is (Occupied / Total) * 100.

calculate_utilization(teacher, TeacherID, Percentage) :-
    get_current_timetable(Timetable),
    count_teacher_assignments(TeacherID, Timetable, Assigned),
    teacher(TeacherID, _, _, MaxLoad, _),
    Percentage is (Assigned / MaxLoad) * 100.

calculate_utilization(timeslot, SlotID, Percentage) :-
    get_current_timetable(Timetable),
    get_all_rooms(Rooms),
    length(Rooms, TotalRooms),
    count_slot_assignments(SlotID, Timetable, Occupied),
    Percentage is (Occupied / TotalRooms) * 100.

% Generate room usage heatmap
generate_room_heatmap(HeatmapData) :-
    get_all_rooms(Rooms),
    get_all_timeslots(Slots),
    findall(DataPoint,
            (member(RoomID, Rooms),
             member(SlotID, Slots),
             calculate_cell_utilization(RoomID, SlotID, Utilization),
             room(RoomID, RoomName, _, _),
             timeslot(SlotID, Day, Period, _, _),
             DataPoint = _{
                 room_id: RoomID,
                 room_name: RoomName,
                 slot_id: SlotID,
                 day: Day,
                 period: Period,
                 utilization: Utilization,
                 color: utilization_color(Utilization)
             }),
            HeatmapData).

% Generate teacher workload heatmap
generate_teacher_heatmap(HeatmapData) :-
    get_all_teachers(Teachers),
    findall(DataPoint,
            (member(TeacherID, Teachers),
             teacher(TeacherID, Name, _, _, _),
             maplist(teacher_day_workload(TeacherID), [monday, tuesday, wednesday, thursday, friday], DayWorkloads),
             DataPoint = _{
                 teacher_id: TeacherID,
                 teacher_name: Name,
                 workload_by_day: DayWorkloads
             }),
            HeatmapData).

teacher_day_workload(TeacherID, Day, DayWorkload) :-
    get_current_timetable(Timetable),
    count_teacher_day_assignments(TeacherID, Day, Timetable, Count),
    DayWorkload = _{day: Day, sessions: Count, color: workload_color(Count)}.

% Generate time slot popularity heatmap
generate_timeslot_heatmap(HeatmapData) :-
    get_all_timeslots(Slots),
    findall(DataPoint,
            (member(SlotID, Slots),
             timeslot(SlotID, Day, Period, StartTime, _),
             calculate_utilization(timeslot, SlotID, Utilization),
             DataPoint = _{
                 slot_id: SlotID,
                 day: Day,
                 period: Period,
                 start_time: StartTime,
                 utilization: Utilization,
                 color: utilization_color(Utilization)
             }),
            HeatmapData).

% Calculate cell utilization (room + slot)
calculate_cell_utilization(RoomID, SlotID, Utilization) :-
    get_current_timetable(Timetable),
    (   is_cell_occupied(RoomID, SlotID, Timetable)
    ->  Utilization = 100
    ;   Utilization = 0
    ).

is_cell_occupied(RoomID, SlotID, Timetable) :-
    get_all_assignments(Timetable, Assignments),
    member(assigned(RoomID, _, _, _, SlotID), Assignments).

% Color mapping functions
utilization_color(Percentage) :-
    (   Percentage >= 80 -> Color = red
    ;   Percentage >= 50 -> Color = yellow
    ;   Color = green
    ).

workload_color(Sessions) :-
    (   Sessions >= 4 -> Color = red
    ;   Sessions >= 2 -> Color = yellow
    ;   Color = green
    ).
```

### API Endpoints

```prolog
:- http_handler(root(api/heatmap/rooms), handle_room_heatmap, []).
:- http_handler(root(api/heatmap/teachers), handle_teacher_heatmap, []).
:- http_handler(root(api/heatmap/timeslots), handle_timeslot_heatmap, []).

handle_room_heatmap(Request) :-
    cors_headers,
    member(method(get), Request),
    generate_room_heatmap(HeatmapData),
    reply_json_dict(_{status: success, heatmap_type: room_usage, data: HeatmapData}).

handle_teacher_heatmap(Request) :-
    cors_headers,
    member(method(get), Request),
    generate_teacher_heatmap(HeatmapData),
    reply_json_dict(_{status: success, heatmap_type: teacher_workload, data: HeatmapData}).

handle_timeslot_heatmap(Request) :-
    cors_headers,
    member(method(get), Request),
    generate_timeslot_heatmap(HeatmapData),
    reply_json_dict(_{status: success, heatmap_type: timeslot_popularity, data: HeatmapData}).
```

### Frontend Implementation

**HTML Addition**:
```html
<section id="heatmap-section" class="section">
    <h2>Resource Utilization Heatmaps</h2>
    <div class="heatmap-controls">
        <button class="heatmap-btn active" data-type="rooms">Room Usage</button>
        <button class="heatmap-btn" data-type="teachers">Teacher Workload</button>
        <button class="heatmap-btn" data-type="timeslots">Time Slot Popularity</button>
    </div>
    <div id="heatmap-legend">
        <span class="legend-item"><span class="legend-color green"></span> Low (&lt;50%)</span>
        <span class="legend-item"><span class="legend-color yellow"></span> Medium (50-80%)</span>
        <span class="legend-item"><span class="legend-color red"></span> High (&gt;80%)</span>
    </div>
    <div id="heatmap-display"></div>
</section>
```

**CSS Addition**:
```css
.heatmap-display {
    display: grid;
    gap: 2px;
    background-color: #bdc3c7;
    margin: 2rem 0;
}

.heatmap-cell {
    padding: 1rem;
    text-align: center;
    cursor: pointer;
    transition: transform 0.2s;
}

.heatmap-cell:hover {
    transform: scale(1.05);
    z-index: 10;
}

.heatmap-cell.green { background-color: #27ae60; color: white; }
.heatmap-cell.yellow { background-color: #f39c12; color: white; }
.heatmap-cell.red { background-color: #e74c3c; color: white; }

.heatmap-legend {
    display: flex;
    justify-content: center;
    gap: 2rem;
    margin: 1rem 0;
}

.legend-color {
    display: inline-block;
    width: 20px;
    height: 20px;
    border-radius: 4px;
    margin-right: 0.5rem;
}

.legend-color.green { background-color: #27ae60; }
.legend-color.yellow { background-color: #f39c12; }
.legend-color.red { background-color: #e74c3c; }
```

**JavaScript Addition**:
```javascript
async function loadHeatmap(type) {
    try {
        const response = await fetch(`${API_BASE}/heatmap/${type}`);
        const result = await response.json();
        
        if (result.status === 'success') {
            displayHeatmap(result.heatmap_type, result.data);
        }
    } catch (error) {
        showNotification('Error loading heatmap: ' + error.message, 'error');
    }
}

function displayHeatmap(type, data) {
    const container = document.getElementById('heatmap-display');
    container.innerHTML = '';
    
    if (type === 'room_usage') {
        displayRoomHeatmap(data, container);
    } else if (type === 'teacher_workload') {
        displayTeacherHeatmap(data, container);
    } else if (type === 'timeslot_popularity') {
        displayTimeslotHeatmap(data, container);
    }
}

function displayRoomHeatmap(data, container) {
    // Group by room and slot
    const rooms = [...new Set(data.map(d => d.room_name))];
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
    
    container.style.gridTemplateColumns = `100px repeat(${days.length}, 1fr)`;
    
    // Header row
    const headerCell = document.createElement('div');
    headerCell.className = 'heatmap-cell header';
    headerCell.textContent = 'Room / Day';
    container.appendChild(headerCell);
    
    days.forEach(day => {
        const dayHeader = document.createElement('div');
        dayHeader.className = 'heatmap-cell header';
        dayHeader.textContent = day.charAt(0).toUpperCase() + day.slice(1);
        container.appendChild(dayHeader);
    });
    
    // Data rows
    rooms.forEach(room => {
        const roomLabel = document.createElement('div');
        roomLabel.className = 'heatmap-cell header';
        roomLabel.textContent = room;
        container.appendChild(roomLabel);
        
        days.forEach(day => {
            const dayData = data.filter(d => d.room_name === room && d.day === day);
            const avgUtilization = dayData.reduce((sum, d) => sum + d.utilization, 0) / dayData.length;
            
            const cell = document.createElement('div');
            cell.className = `heatmap-cell ${getUtilizationColor(avgUtilization)}`;
            cell.textContent = avgUtilization.toFixed(0) + '%';
            cell.title = `${room} on ${day}: ${avgUtilization.toFixed(1)}% utilized`;
            container.appendChild(cell);
        });
    });
}

function displayTeacherHeatmap(data, container) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
    
    container.style.gridTemplateColumns = `150px repeat(${days.length}, 1fr)`;
    
    // Header row
    const headerCell = document.createElement('div');
    headerCell.className = 'heatmap-cell header';
    headerCell.textContent = 'Teacher / Day';
    container.appendChild(headerCell);
    
    days.forEach(day => {
        const dayHeader = document.createElement('div');
        dayHeader.className = 'heatmap-cell header';
        dayHeader.textContent = day.charAt(0).toUpperCase() + day.slice(1);
        container.appendChild(dayHeader);
    });
    
    // Data rows
    data.forEach(teacher => {
        const teacherLabel = document.createElement('div');
        teacherLabel.className = 'heatmap-cell header';
        teacherLabel.textContent = teacher.teacher_name;
        container.appendChild(teacherLabel);
        
        teacher.workload_by_day.forEach(dayWork => {
            const cell = document.createElement('div');
            cell.className = `heatmap-cell ${dayWork.color}`;
            cell.textContent = dayWork.sessions + ' sessions';
            cell.title = `${teacher.teacher_name} on ${dayWork.day}: ${dayWork.sessions} sessions`;
            container.appendChild(cell);
        });
    });
}

function getUtilizationColor(percentage) {
    if (percentage >= 80) return 'red';
    if (percentage >= 50) return 'yellow';
    return 'green';
}

// Heatmap type switching
document.querySelectorAll('.heatmap-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
        document.querySelectorAll('.heatmap-btn').forEach(b => b.classList.remove('active'));
        e.target.classList.add('active');
        const type = e.target.dataset.type;
        loadHeatmap(type);
    });
});

// Load default heatmap
loadHeatmap('rooms');
```

### MFAI Concept Demonstration

This feature demonstrates:
- **Data Visualization**: Presents complex data intuitively
- **Pattern Recognition**: Helps identify utilization patterns
- **Decision Support**: Visual aids for resource allocation

---

