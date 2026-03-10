# Advanced Features Part 2: AI Intelligent Timetable Decision System

## Feature 7: AI Search Visualization

### Overview
Display CSP search process statistics including nodes explored, backtracking events, heuristics applied, and time taken. This demonstrates AI transparency and debugging capabilities.

### Backend Implementation

#### New Module: search_statistics.pl

```prolog
:- dynamic search_stat/2.

%% initialize_search_stats is det.
%
% Initialize search statistics tracking.
%
initialize_search_stats :-
    retractall(search_stat(_, _)),
    assertz(search_stat(nodes_explored, 0)),
    assertz(search_stat(backtrack_count, 0)),
    assertz(search_stat(mrv_applications, 0)),
    assertz(search_stat(degree_applications, 0)),
    assertz(search_stat(lcv_applications, 0)),
    assertz(search_stat(forward_check_prunings, 0)),
    assertz(search_stat(constraint_checks, 0)),
    assertz(search_stat(start_time, 0)),
    get_time(Time),
    retract(search_stat(start_time, _)),
    assertz(search_stat(start_time, Time)).

%% increment_stat(+StatName) is det.
%
% Increment a search statistic counter.
%
increment_stat(StatName) :-
    retract(search_stat(StatName, Count)),
    NewCount is Count + 1,
    assertz(search_stat(StatName, NewCount)).

%% get_search_statistics(-Stats) is det.
%
% Retrieve all search statistics.
%
get_search_statistics(Stats) :-
    search_stat(nodes_explored, Nodes),
    search_stat(backtrack_count, Backtracks),
    search_stat(mrv_applications, MRV),
    search_stat(degree_applications, Degree),
    search_stat(lcv_applications, LCV),
    search_stat(forward_check_prunings, FCPrunings),
    search_stat(constraint_checks, Constraints),
    search_stat(start_time, StartTime),
    get_time(EndTime),
    ElapsedTime is EndTime - StartTime,
    Stats = _{
        nodes_explored: Nodes,
        backtrack_count: Backtracks,
        heuristics: _{
            mrv_applications: MRV,
            degree_applications: Degree,
            lcv_applications: LCV
        },
        forward_checking: _{
            prunings: FCPrunings
        },
        constraint_checks: Constraints,
        time_elapsed: ElapsedTime,
        search_efficiency: (Nodes > 0 -> Backtracks / Nodes ; 0)
    }.

% Enhanced CSP solver with statistics tracking
solve_csp_with_stats(Sessions, Matrix, Solution) :-
    initialize_search_stats,
    initialize_domains(Sessions, Domains),
    backtracking_search_with_stats(Sessions, Domains, Matrix, Solution),
    get_search_statistics(Stats),
    log_search_statistics(Stats).

backtracking_search_with_stats([], _, Matrix, Matrix) :- !.
backtracking_search_with_stats(Sessions, Domains, Matrix, Solution) :-
    increment_stat(nodes_explored),
    select_variable_with_stats(Sessions, Domains, SelectedSession, RemainingSessions),
    get_domain(SelectedSession, Domains, Domain),
    order_domain_values_with_stats(Domain, SelectedSession, Matrix, OrderedDomain),
    try_values_with_stats(OrderedDomain, SelectedSession, RemainingSessions, Domains, Matrix, Solution).

select_variable_with_stats(Sessions, Domains, Selected, Remaining) :-
    increment_stat(mrv_applications),
    select_variable_mrv(Sessions, Domains, Selected, Remaining).

order_domain_values_with_stats(Domain, Session, Matrix, OrderedDomain) :-
    increment_stat(lcv_applications),
    order_domain_values(Domain, Session, Matrix, OrderedDomain).

try_values_with_stats([Value|Rest], Session, Remaining, Domains, Matrix, Solution) :-
    assign_value(Session, Value, Matrix, NewMatrix),
    increment_stat(constraint_checks),
    (   check_constraints(Session, Value, NewMatrix)
    ->  forward_check_with_stats(Session, Value, Remaining, Domains, NewDomains),
        (   \+ has_empty_domain(NewDomains)
        ->  backtracking_search_with_stats(Remaining, NewDomains, NewMatrix, Solution)
        ;   increment_stat(backtrack_count),
            fail
        )
    ;   increment_stat(backtrack_count),
        fail
    ),
    !.
try_values_with_stats([_|Rest], Session, Remaining, Domains, Matrix, Solution) :-
    increment_stat(backtrack_count),
    try_values_with_stats(Rest, Session, Remaining, Domains, Matrix, Solution).

forward_check_with_stats(AssignedSession, AssignedValue, RemainingSessions, Domains, NewDomains) :-
    forward_check(AssignedSession, AssignedValue, RemainingSessions, Domains, NewDomains),
    count_pruned_values(Domains, NewDomains, PrunedCount),
    add_to_stat(forward_check_prunings, PrunedCount).

add_to_stat(StatName, Amount) :-
    retract(search_stat(StatName, Count)),
    NewCount is Count + Amount,
    assertz(search_stat(StatName, NewCount)).

count_pruned_values(OldDomains, NewDomains, Count) :-
    findall(Diff,
            (member(Var-OldDomain, OldDomains),
             member(Var-NewDomain, NewDomains),
             length(OldDomain, OldLen),
             length(NewDomain, NewLen),
             Diff is OldLen - NewLen),
            Diffs),
    sum_list(Diffs, Count).

% Log search statistics
log_search_statistics(Stats) :-
    log_info('=== Search Statistics ==='),
    format('Nodes explored: ~w~n', [Stats.nodes_explored]),
    format('Backtracking events: ~w~n', [Stats.backtrack_count]),
    format('MRV applications: ~w~n', [Stats.heuristics.mrv_applications]),
    format('LCV applications: ~w~n', [Stats.heuristics.lcv_applications]),
    format('Forward checking prunings: ~w~n', [Stats.forward_checking.prunings]),
    format('Constraint checks: ~w~n', [Stats.constraint_checks]),
    format('Time elapsed: ~2f seconds~n', [Stats.time_elapsed]),
    format('Search efficiency: ~2f~n', [Stats.search_efficiency]).
```

### API Endpoint

```prolog
:- http_handler(root(api/search_stats), handle_search_stats, []).

handle_search_stats(Request) :-
    cors_headers,
    member(method(get), Request),
    (   search_stat(_, _)
    ->  get_search_statistics(Stats),
        reply_json_dict(_{status: success, statistics: Stats})
    ;   reply_json_dict(_{status: error, message: 'No search statistics available. Generate a timetable first.'})
    ).
```

### Frontend Implementation

**HTML Addition**:
```html
<div id="search-stats-panel" class="panel">
    <h3>AI Search Process Statistics</h3>
    <div id="search-stats-display">
        <div class="stat-item">
            <span class="stat-label">Nodes Explored</span>
            <span id="nodes-explored" class="stat-value">--</span>
        </div>
        <div class="stat-item">
            <span class="stat-label">Backtracking Events</span>
            <span id="backtrack-count" class="stat-value">--</span>
        </div>
        <div class="stat-item">
            <span class="stat-label">MRV Heuristic Applied</span>
            <span id="mrv-count" class="stat-value">--</span>
        </div>
        <div class="stat-item">
            <span class="stat-label">LCV Heuristic Applied</span>
            <span id="lcv-count" class="stat-value">--</span>
        </div>
        <div class="stat-item">
            <span class="stat-label">Forward Checking Prunings</span>
            <span id="fc-prunings" class="stat-value">--</span>
        </div>
        <div class="stat-item">
            <span class="stat-label">Time Elapsed</span>
            <span id="time-elapsed" class="stat-value">--</span>
        </div>
        <div class="stat-item">
            <span class="stat-label">Search Efficiency</span>
            <span id="search-efficiency" class="stat-value">--</span>
        </div>
    </div>
    <canvas id="search-tree-visualization"></canvas>
</div>
```

**JavaScript Addition**:
```javascript
async function loadSearchStatistics() {
    try {
        const response = await fetch(`${API_BASE}/search_stats`);
        const result = await response.json();
        
        if (result.status === 'success') {
            displaySearchStatistics(result.statistics);
        }
    } catch (error) {
        console.error('Error loading search statistics:', error);
    }
}

function displaySearchStatistics(stats) {
    document.getElementById('nodes-explored').textContent = stats.nodes_explored.toLocaleString();
    document.getElementById('backtrack-count').textContent = stats.backtrack_count.toLocaleString();
    document.getElementById('mrv-count').textContent = stats.heuristics.mrv_applications.toLocaleString();
    document.getElementById('lcv-count').textContent = stats.heuristics.lcv_applications.toLocaleString();
    document.getElementById('fc-prunings').textContent = stats.forward_checking.prunings.toLocaleString();
    document.getElementById('time-elapsed').textContent = stats.time_elapsed.toFixed(2) + 's';
    document.getElementById('search-efficiency').textContent = (stats.search_efficiency * 100).toFixed(1) + '%';
    
    // Optional: Visualize search tree
    visualizeSearchTree(stats);
}

function visualizeSearchTree(stats) {
    const canvas = document.getElementById('search-tree-visualization');
    const ctx = canvas.getContext('2d');
    
    // Simple bar chart visualization
    const data = [
        { label: 'Nodes', value: stats.nodes_explored, color: '#3498db' },
        { label: 'Backtracks', value: stats.backtrack_count, color: '#e74c3c' },
        { label: 'Prunings', value: stats.forward_checking.prunings, color: '#27ae60' }
    ];
    
    const maxValue = Math.max(...data.map(d => d.value));
    const barHeight = 40;
    const barSpacing = 20;
    
    canvas.height = data.length * (barHeight + barSpacing);
    canvas.width = 500;
    
    data.forEach((item, index) => {
        const y = index * (barHeight + barSpacing);
        const barWidth = (item.value / maxValue) * 400;
        
        ctx.fillStyle = item.color;
        ctx.fillRect(80, y, barWidth, barHeight);
        
        ctx.fillStyle = '#2c3e50';
        ctx.font = '14px Arial';
        ctx.fillText(item.label, 10, y + 25);
        ctx.fillText(item.value.toLocaleString(), barWidth + 90, y + 25);
    });
}

// Auto-load after generation
document.getElementById('generate-btn').addEventListener('click', async () => {
    // ... existing generation code ...
    await loadSearchStatistics();
});
```

### MFAI Concept Demonstration

This feature demonstrates:
- **Algorithm Transparency**: Shows how CSP solver works internally
- **Performance Analysis**: Tracks efficiency metrics
- **AI Debugging**: Helps understand search behavior

---

## Feature 8: Multiple Timetable Generation

### Overview
Generate top N best timetables instead of just one, ranked by quality score. This demonstrates AI optimization comparison and choice.

### Backend Implementation

#### New Module: multi_solution_generator.pl

```prolog
%% generate_top_timetables(+N, -TimetableList) is det.
%
% Generate N best timetables ranked by quality score.
%
generate_top_timetables(N, RankedTimetables) :-
    log_info('Generating multiple timetable solutions'),
    retrieve_resources(Teachers, Subjects, Rooms, Slots, Classes),
    create_sessions(Classes, Subjects, Sessions),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    generate_multiple_solutions(Sessions, EmptyMatrix, N, Solutions),
    rank_solutions_by_quality(Solutions, RankedTimetables).

% Generate multiple solutions using different search strategies
generate_multiple_solutions(Sessions, EmptyMatrix, N, Solutions) :-
    findall(Timetable,
            (between(1, N, _),
             generate_solution_variant(Sessions, EmptyMatrix, Timetable)),
            AllSolutions),
    remove_duplicates(AllSolutions, Solutions).

% Generate solution variant with randomization
generate_solution_variant(Sessions, EmptyMatrix, Timetable) :-
    randomize_session_order(Sessions, RandomizedSessions),
    solve_csp(RandomizedSessions, EmptyMatrix, Timetable).

% Alternative: Use different heuristic combinations
generate_solution_with_heuristic(Sessions, EmptyMatrix, HeuristicSet, Timetable) :-
    set_active_heuristics(HeuristicSet),
    solve_csp(Sessions, EmptyMatrix, Timetable),
    reset_heuristics.

% Rank solutions by quality score
rank_solutions_by_quality(Solutions, RankedSolutions) :-
    maplist(score_solution, Solutions, ScoredSolutions),
    sort(2, @>=, ScoredSolutions, SortedSolutions),  % Sort by score descending
    pairs_keys(SortedSolutions, RankedSolutions).

score_solution(Timetable, Timetable-Score) :-
    calculate_quality_score(Timetable, QualityScore),
    schedule_reliability(Timetable, Reliability),
    Score is QualityScore * 0.7 + Reliability * 30.  % Combined score

% Remove duplicate timetables
remove_duplicates(Timetables, UniqueTimetables) :-
    remove_duplicates_helper(Timetables, [], UniqueTimetables).

remove_duplicates_helper([], Acc, Acc).
remove_duplicates_helper([T|Rest], Acc, Result) :-
    (   member_equivalent(T, Acc)
    ->  remove_duplicates_helper(Rest, Acc, Result)
    ;   remove_duplicates_helper(Rest, [T|Acc], Result)
    ).

member_equivalent(Timetable, List) :-
    member(OtherTimetable, List),
    timetables_equivalent(Timetable, OtherTimetable).

timetables_equivalent(T1, T2) :-
    get_all_assignments(T1, A1),
    get_all_assignments(T2, A2),
    sort(A1, Sorted1),
    sort(A2, Sorted2),
    Sorted1 = Sorted2.

% Compare two timetables
compare_timetables(Timetable1, Timetable2, Comparison) :-
    calculate_quality_score(Timetable1, Score1),
    calculate_quality_score(Timetable2, Score2),
    schedule_reliability(Timetable1, Rel1),
    schedule_reliability(Timetable2, Rel2),
    quality_breakdown(Timetable1, Breakdown1),
    quality_breakdown(Timetable2, Breakdown2),
    Comparison = _{
        timetable1: _{
            quality_score: Score1,
            reliability: Rel1,
            breakdown: Breakdown1
        },
        timetable2: _{
            quality_score: Score2,
            reliability: Rel2,
            breakdown: Breakdown2
        },
        winner: (Score1 > Score2 -> timetable1 ; timetable2),
        score_difference: abs(Score1 - Score2)
    }.
```

### API Endpoints

```prolog
:- http_handler(root(api/generate_multiple), handle_generate_multiple, []).
:- http_handler(root(api/compare_timetables), handle_compare_timetables, []).

handle_generate_multiple(Request) :-
    cors_headers,
    member(method(post), Request),
    http_read_json(Request, JSONData),
    get_dict(count, JSONData, N),
    (N > 10 -> Count = 10 ; Count = N),  % Limit to 10 solutions
    generate_top_timetables(Count, RankedTimetables),
    maplist(format_timetable_with_score, RankedTimetables, FormattedTimetables),
    reply_json_dict(_{
        status: success,
        count: Count,
        timetables: FormattedTimetables
    }).

format_timetable_with_score(Timetable, Formatted) :-
    format_timetable(Timetable, json, JSONOutput),
    calculate_quality_score(Timetable, Score),
    schedule_reliability(Timetable, Reliability),
    Formatted = _{
        timetable: JSONOutput,
        quality_score: Score,
        reliability: Reliability
    }.

handle_compare_timetables(Request) :-
    cors_headers,
    member(method(post), Request),
    http_read_json(Request, JSONData),
    get_dict(timetable1_id, JSONData, ID1),
    get_dict(timetable2_id, JSONData, ID2),
    retrieve_timetable(ID1, Timetable1),
    retrieve_timetable(ID2, Timetable2),
    compare_timetables(Timetable1, Timetable2, Comparison),
    reply_json_dict(_{status: success, comparison: Comparison}).
```

### Frontend Implementation

**HTML Addition**:
```html
<div id="multiple-solutions-panel" class="panel">
    <h3>Multiple Timetable Options</h3>
    <div class="generation-controls">
        <label>Number of options: <input type="number" id="solution-count" min="2" max="10" value="3"></label>
        <button id="generate-multiple-btn" class="primary-btn">Generate Options</button>
    </div>
    <div id="solutions-list"></div>
</div>
```

**JavaScript Addition**:
```javascript
async function generateMultipleTimetables(count) {
    try {
        const response = await fetch(`${API_BASE}/generate_multiple`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ count: count })
        });
        const result = await response.json();
        
        if (result.status === 'success') {
            displayMultipleSolutions(result.timetables);
        }
    } catch (error) {
        showNotification('Error generating multiple solutions: ' + error.message, 'error');
    }
}

function displayMultipleSolutions(timetables) {
    const container = document.getElementById('solutions-list');
    container.innerHTML = '';
    
    timetables.forEach((tt, index) => {
        const solutionDiv = document.createElement('div');
        solutionDiv.className = 'solution-option';
        
        const header = document.createElement('div');
        header.className = 'solution-header';
        header.innerHTML = `
            <h4>Option ${index + 1}</h4>
            <div class="solution-scores">
                <span class="score-badge quality">Quality: ${tt.quality_score.toFixed(1)}</span>
                <span class="score-badge reliability">Reliability: ${(tt.reliability * 100).toFixed(1)}%</span>
            </div>
        `;
        
        const previewBtn = document.createElement('button');
        previewBtn.className = 'preview-btn';
        previewBtn.textContent = 'Preview';
        previewBtn.onclick = () => previewTimetable(tt.timetable);
        
        const selectBtn = document.createElement('button');
        selectBtn.className = 'select-btn';
        selectBtn.textContent = 'Select This Option';
        selectBtn.onclick = () => selectTimetable(tt.timetable);
        
        solutionDiv.appendChild(header);
        solutionDiv.appendChild(previewBtn);
        solutionDiv.appendChild(selectBtn);
        container.appendChild(solutionDiv);
    });
}

function previewTimetable(timetable) {
    // Show preview in modal
    const modal = document.createElement('div');
    modal.className = 'modal active';
    modal.innerHTML = `
        <div class="modal-content">
            <span class="close">&times;</span>
            <h3>Timetable Preview</h3>
            <div id="preview-grid"></div>
        </div>
    `;
    document.body.appendChild(modal);
    
    renderMiniTimetable(timetable, document.getElementById('preview-grid'));
    
    modal.querySelector('.close').onclick = () => modal.remove();
}

function selectTimetable(timetable) {
    currentTimetable = timetable;
    renderTimetable(timetable);
    showNotification('Timetable selected!', 'success');
    document.getElementById('nav-visualize').click();
}

document.getElementById('generate-multiple-btn').addEventListener('click', () => {
    const count = parseInt(document.getElementById('solution-count').value);
    generateMultipleTimetables(count);
});
```

### MFAI Concept Demonstration

This feature demonstrates:
- **Solution Space Exploration**: Finds multiple valid solutions
- **Optimization Comparison**: Ranks solutions by quality
- **User Choice**: Empowers users to select preferred solution

---

## Feature 9: Constraint Importance Slider

### Overview
Allow users to adjust soft constraint priorities dynamically using sliders. This demonstrates customizable AI optimization.

### Backend Implementation

#### New Module: dynamic_constraints.pl

```prolog
:- dynamic constraint_weight/2.

%% initialize_constraint_weights is det.
%
% Initialize default constraint weights.
%
initialize_constraint_weights :-
    retractall(constraint_weight(_, _)),
    assertz(constraint_weight(teacher_preference, 0.5)),
    assertz(constraint_weight(room_optimization, 0.5)),
    assertz(constraint_weight(student_compact_schedule, 0.5)),
    assertz(constraint_weight(workload_balance, 0.5)).

%% set_constraint_weight(+ConstraintType, +Weight) is det.
%
% Set weight for a soft constraint (0.0 to 1.0).
%
set_constraint_weight(ConstraintType, Weight) :-
    Weight >= 0.0,
    Weight =< 1.0,
    retract(constraint_weight(ConstraintType, _)),
    assertz(constraint_weight(ConstraintType, Weight)),
    log_info(format('Constraint weight updated: ~w = ~2f', [ConstraintType, Weight])).

%% get_constraint_weight(+ConstraintType, -Weight) is det.
%
% Get current weight for a constraint.
%
get_constraint_weight(ConstraintType, Weight) :-
    (   constraint_weight(ConstraintType, Weight)
    ->  true
    ;   Weight = 0.5  % Default weight
    ).

% Calculate weighted soft constraint score
calculate_weighted_soft_score(Timetable, TotalScore) :-
    teacher_preference_score(Timetable, TPScore),
    room_optimization_score(Timetable, ROScore),
    student_compact_score(Timetable, SCScore),
    workload_balance_score(Timetable, WBScore),
    
    get_constraint_weight(teacher_preference, TPWeight),
    get_constraint_weight(room_optimization, ROWeight),
    get_constraint_weight(student_compact_schedule, SCWeight),
    get_constraint_weight(workload_balance, WBWeight),
    
    WeightedTP is TPScore * TPWeight,
    WeightedRO is ROScore * ROWeight,
    WeightedSC is SCScore * SCWeight,
    WeightedWB is WBScore * WBWeight,
    
    TotalWeight is TPWeight + ROWeight + SCWeight + WBWeight,
    (TotalWeight > 0 
    -> TotalScore is (WeightedTP + WeightedRO + WeightedSC + WeightedWB) / TotalWeight
    ; TotalScore = 0).

% Teacher preference score
teacher_preference_score(Timetable, Score) :-
    get_all_teachers(Teachers),
    maplist(teacher_satisfaction(Timetable), Teachers, Satisfactions),
    mean(Satisfactions, Score).

teacher_satisfaction(Timetable, TeacherID, Satisfaction) :-
    teacher(TeacherID, _, _, _, PreferredSlots),
    get_teacher_assignments(TeacherID, Timetable, Assignments),
    count_preferred_assignments(Assignments, PreferredSlots, PreferredCount),
    length(Assignments, Total),
    (Total > 0 -> Satisfaction is PreferredCount / Total ; Satisfaction = 1.0).

count_preferred_assignments([], _, 0).
count_preferred_assignments([Assignment|Rest], PreferredSlots, Count) :-
    assignment_slot(Assignment, SlotID),
    (   member(SlotID, PreferredSlots)
    ->  count_preferred_assignments(Rest, PreferredSlots, RestCount),
        Count is RestCount + 1
    ;   count_preferred_assignments(Rest, PreferredSlots, Count)
    ).

% Room optimization score
room_optimization_score(Timetable, Score) :-
    get_all_rooms(Rooms),
    maplist(room_efficiency(Timetable), Rooms, Efficiencies),
    mean(Efficiencies, Score).

room_efficiency(Timetable, RoomID, Efficiency) :-
    room(RoomID, _, Capacity, _),
    get_room_assignments(RoomID, Timetable, Assignments),
    maplist(assignment_class_size, Assignments, ClassSizes),
    mean(ClassSizes, AvgSize),
    Efficiency is min(1.0, AvgSize / Capacity).

% Student compact schedule score
student_compact_score(Timetable, Score) :-
    get_all_classes(Classes),
    maplist(class_compactness(Timetable), Classes, Compactnesses),
    mean(Compactnesses, Score).

class_compactness(Timetable, ClassID, Compactness) :-
    get_class_schedule(ClassID, Timetable, Schedule),
    count_gaps(Schedule, Gaps),
    length(Schedule, Sessions),
    (Sessions > 0 -> Compactness is 1.0 - (Gaps / Sessions) ; Compactness = 1.0).

% Generate timetable with custom weights
generate_with_custom_weights(Weights, Timetable) :-
    % Set weights
    maplist(apply_weight, Weights),
    % Generate timetable
    generate_timetable(Timetable),
    % Reset to defaults
    initialize_constraint_weights.

apply_weight(ConstraintType-Weight) :-
    set_constraint_weight(ConstraintType, Weight).

% Get all constraint weights
get_all_constraint_weights(Weights) :-
    findall(Type-Weight,
            constraint_weight(Type, Weight),
            Weights).
```

### API Endpoints

```prolog
:- http_handler(root(api/constraint_weights), handle_constraint_weights, []).
:- http_handler(root(api/set_weights), handle_set_weights, []).
:- http_handler(root(api/generate_with_weights), handle_generate_with_weights, []).

handle_constraint_weights(Request) :-
    cors_headers,
    member(method(get), Request),
    get_all_constraint_weights(Weights),
    reply_json_dict(_{status: success, weights: Weights}).

handle_set_weights(Request) :-
    cors_headers,
    member(method(post), Request),
    http_read_json(Request, JSONData),
    get_dict(weights, JSONData, WeightsDict),
    dict_pairs(WeightsDict, _, WeightPairs),
    maplist(apply_weight_from_pair, WeightPairs),
    reply_json_dict(_{status: success, message: 'Weights updated successfully'}).

apply_weight_from_pair(Type-Weight) :-
    atom_string(TypeAtom, Type),
    set_constraint_weight(TypeAtom, Weight).

handle_generate_with_weights(Request) :-
    cors_headers,
    member(method(post), Request),
    http_read_json(Request, JSONData),
    get_dict(weights, JSONData, WeightsDict),
    dict_pairs(WeightsDict, _, WeightPairs),
    generate_with_custom_weights(WeightPairs, Timetable),
    format_timetable(Timetable, json, JSONOutput),
    calculate_quality_score(Timetable, Score),
    reply_json_dict(_{
        status: success,
        timetable: JSONOutput,
        quality_score: Score
    }).
```

### Frontend Implementation

**HTML Addition**:
```html
<div id="constraint-weights-panel" class="panel">
    <h3>Customize Constraint Priorities</h3>
    <p class="panel-description">Adjust the importance of each soft constraint (0-100%)</p>
    
    <div class="constraint-slider">
        <label for="teacher-preference-slider">Teacher Preference Importance</label>
        <input type="range" id="teacher-preference-slider" min="0" max="100" value="50">
        <span id="teacher-preference-value" class="slider-value">50%</span>
    </div>
    
    <div class="constraint-slider">
        <label for="room-optimization-slider">Room Optimization Importance</label>
        <input type="range" id="room-optimization-slider" min="0" max="100" value="50">
        <span id="room-optimization-value" class="slider-value">50%</span>
    </div>
    
    <div class="constraint-slider">
        <label for="student-compact-slider">Student Compact Schedule Importance</label>
        <input type="range" id="student-compact-slider" min="0" max="100" value="50">
        <span id="student-compact-value" class="slider-value">50%</span>
    </div>
    
    <div class="constraint-slider">
        <label for="workload-balance-slider">Workload Balance Importance</label>
        <input type="range" id="workload-balance-slider" min="0" max="100" value="50">
        <span id="workload-balance-value" class="slider-value">50%</span>
    </div>
    
    <div class="slider-actions">
        <button id="apply-weights-btn" class="primary-btn">Apply Weights</button>
        <button id="regenerate-with-weights-btn" class="secondary-btn">Regenerate with New Priorities</button>
        <button id="reset-weights-btn" class="tertiary-btn">Reset to Defaults</button>
    </div>
</div>
```

**CSS Addition**:
```css
.constraint-slider {
    margin: 1.5rem 0;
}

.constraint-slider label {
    display: block;
    margin-bottom: 0.5rem;
    font-weight: 500;
}

.constraint-slider input[type="range"] {
    width: 80%;
    height: 8px;
    border-radius: 5px;
    background: #ecf0f1;
    outline: none;
    -webkit-appearance: none;
}

.constraint-slider input[type="range"]::-webkit-slider-thumb {
    -webkit-appearance: none;
    appearance: none;
    width: 20px;
    height: 20px;
    border-radius: 50%;
    background: var(--secondary-color);
    cursor: pointer;
}

.constraint-slider input[type="range"]::-moz-range-thumb {
    width: 20px;
    height: 20px;
    border-radius: 50%;
    background: var(--secondary-color);
    cursor: pointer;
}

.slider-value {
    display: inline-block;
    width: 50px;
    text-align: right;
    font-weight: bold;
    color: var(--secondary-color);
}

.slider-actions {
    display: flex;
    gap: 1rem;
    margin-top: 2rem;
}
```

**JavaScript Addition**:
```javascript
// Initialize sliders
const sliders = [
    { id: 'teacher-preference', name: 'teacher_preference' },
    { id: 'room-optimization', name: 'room_optimization' },
    { id: 'student-compact', name: 'student_compact_schedule' },
    { id: 'workload-balance', name: 'workload_balance' }
];

sliders.forEach(slider => {
    const sliderElement = document.getElementById(`${slider.id}-slider`);
    const valueElement = document.getElementById(`${slider.id}-value`);
    
    sliderElement.addEventListener('input', (e) => {
        valueElement.textContent = e.target.value + '%';
    });
});

// Apply weights
document.getElementById('apply-weights-btn').addEventListener('click', async () => {
    const weights = {};
    sliders.forEach(slider => {
        const value = document.getElementById(`${slider.id}-slider`).value;
        weights[slider.name] = parseFloat(value) / 100;
    });
    
    try {
        const response = await fetch(`${API_BASE}/set_weights`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ weights: weights })
        });
        const result = await response.json();
        
        if (result.status === 'success') {
            showNotification('Constraint weights updated!', 'success');
        }
    } catch (error) {
        showNotification('Error updating weights: ' + error.message, 'error');
    }
});

// Regenerate with new weights
document.getElementById('regenerate-with-weights-btn').addEventListener('click', async () => {
    const weights = {};
    sliders.forEach(slider => {
        const value = document.getElementById(`${slider.id}-slider`).value;
        weights[slider.name] = parseFloat(value) / 100;
    });
    
    try {
        const response = await fetch(`${API_BASE}/generate_with_weights`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ weights: weights })
        });
        const result = await response.json();
        
        if (result.status === 'success') {
            currentTimetable = result.timetable;
            renderTimetable(result.timetable);
            showNotification(`Regenerated! Quality score: ${result.quality_score.toFixed(1)}`, 'success');
        }
    } catch (error) {
        showNotification('Error regenerating: ' + error.message, 'error');
    }
});

// Reset to defaults
document.getElementById('reset-weights-btn').addEventListener('click', () => {
    sliders.forEach(slider => {
        const sliderElement = document.getElementById(`${slider.id}-slider`);
        const valueElement = document.getElementById(`${slider.id}-value`);
        sliderElement.value = 50;
        valueElement.textContent = '50%';
    });
    showNotification('Weights reset to defaults', 'info');
});
```

### MFAI Concept Demonstration

This feature demonstrates:
- **Customizable Optimization**: User-controlled objective functions
- **Multi-Objective Balancing**: Weighted combination of objectives
- **Interactive AI**: Real-time parameter adjustment

---

## Feature 10: Real-Time Constraint Checking

### Overview
Validate data as users enter it in forms with instant feedback. This demonstrates proactive AI reasoning.

### Backend Implementation

#### New Module: realtime_validator.pl

```prolog
%% validate_teacher_input(+TeacherData, -ValidationResult) is det.
%
% Validate teacher data in real-time.
%
validate_teacher_input(TeacherData, ValidationResult) :-
    findall(Error, validate_teacher_field(TeacherData, Error), Errors),
    findall(Warning, validate_teacher_warning(TeacherData, Warning), Warnings),
    (   Errors = []
    ->  ValidationResult = _{status: valid, warnings: Warnings}
    ;   ValidationResult = _{status: invalid, errors: Errors, warnings: Warnings}
    ).

validate_teacher_field(Data, Error) :-
    get_dict(qualified_subjects, Data, Subjects),
    member(SubjectID, Subjects),
    \+ subject(SubjectID, _, _, _, _),
    format(atom(Error), 'Subject "~w" does not exist', [SubjectID]).

validate_teacher_field(Data, Error) :-
    get_dict(max_load, Data, MaxLoad),
    MaxLoad < 1,
    Error = 'Maximum load must be at least 1 hour'.

validate_teacher_field(Data, Error) :-
    get_dict(max_load, Data, MaxLoad),
    MaxLoad > 40,
    Error = 'Maximum load exceeds reasonable limit (40 hours)'.

validate_teacher_field(Data, Error) :-
    get_dict(availability, Data, Availability),
    member(SlotID, Availability),
    \+ timeslot(SlotID, _, _, _, _),
    format(atom(Error), 'Time slot "~w" does not exist', [SlotID]).

validate_teacher_warning(Data, Warning) :-
    get_dict(qualified_subjects, Data, Subjects),
    length(Subjects, Count),
    Count < 2,
    Warning = 'Teacher qualified for only one subject - consider adding more qualifications'.

validate_teacher_warning(Data, Warning) :-
    get_dict(availability, Data, Availability),
    length(Availability, Count),
    get_all_timeslots(AllSlots),
    length(AllSlots, Total),
    Percentage is (Count / Total) * 100,
    Percentage < 50,
    format(atom(Warning), 'Teacher available for only ~1f% of time slots', [Percentage]).

%% validate_subject_input(+SubjectData, -ValidationResult) is det.
%
% Validate subject data in real-time.
%
validate_subject_input(SubjectData, ValidationResult) :-
    findall(Error, validate_subject_field(SubjectData, Error), Errors),
    findall(Warning, validate_subject_warning(SubjectData, Warning), Warnings),
    (   Errors = []
    ->  ValidationResult = _{status: valid, warnings: Warnings}
    ;   ValidationResult = _{status: invalid, errors: Errors, warnings: Warnings}
    ).

validate_subject_field(Data, Error) :-
    get_dict(weekly_hours, Data, Hours),
    Hours < 1,
    Error = 'Weekly hours must be at least 1'.

validate_subject_field(Data, Error) :-
    get_dict(weekly_hours, Data, Hours),
    Hours > 20,
    Error = 'Weekly hours exceeds reasonable limit (20 hours)'.

validate_subject_field(Data, Error) :-
    get_dict(type, Data, Type),
    \+ member(Type, [theory, lab]),
    Error = 'Subject type must be either "theory" or "lab"'.

validate_subject_field(Data, Error) :-
    get_dict(duration, Data, Duration),
    get_dict(weekly_hours, Data, WeeklyHours),
    0 =\= WeeklyHours mod Duration,
    Error = 'Weekly hours must be divisible by session duration'.

validate_subject_warning(Data, Warning) :-
    get_dict(type, Data, lab),
    get_dict(duration, Data, Duration),
    Duration < 2,
    Warning = 'Lab sessions typically require at least 2 hours duration'.

%% validate_room_input(+RoomData, -ValidationResult) is det.
%
% Validate room data in real-time.
%
validate_room_input(RoomData, ValidationResult) :-
    findall(Error, validate_room_field(RoomData, Error), Errors),
    findall(Warning, validate_room_warning(RoomData, Warning), Warnings),
    (   Errors = []
    ->  ValidationResult = _{status: valid, warnings: Warnings}
    ;   ValidationResult = _{status: invalid, errors: Errors, warnings: Warnings}
    ).

validate_room_field(Data, Error) :-
    get_dict(capacity, Data, Capacity),
    Capacity < 1,
    Error = 'Room capacity must be at least 1'.

validate_room_field(Data, Error) :-
    get_dict(capacity, Data, Capacity),
    Capacity > 500,
    Error = 'Room capacity exceeds reasonable limit (500)'.

validate_room_field(Data, Error) :-
    get_dict(type, Data, Type),
    \+ member(Type, [classroom, lab]),
    Error = 'Room type must be either "classroom" or "lab"'.

validate_room_warning(Data, Warning) :-
    get_dict(type, Data, lab),
    get_dict(capacity, Data, Capacity),
    Capacity > 40,
    Warning = 'Lab capacity is unusually high - verify this is correct'.

%% check_assignment_feasibility(+Assignment, -FeasibilityResult) is det.
%
% Check if a potential assignment is feasible.
%
check_assignment_feasibility(Assignment, FeasibilityResult) :-
    get_dict(teacher_id, Assignment, TeacherID),
    get_dict(subject_id, Assignment, SubjectID),
    get_dict(room_id, Assignment, RoomID),
    get_dict(slot_id, Assignment, SlotID),
    get_dict(class_id, Assignment, ClassID),
    
    findall(Issue, check_assignment_issue(TeacherID, SubjectID, RoomID, SlotID, ClassID, Issue), Issues),
    
    (   Issues = []
    ->  FeasibilityResult = _{feasible: true, message: 'Assignment is feasible'}
    ;   FeasibilityResult = _{feasible: false, issues: Issues}
    ).

check_assignment_issue(TeacherID, SubjectID, _, _, _, Issue) :-
    \+ qualified(TeacherID, SubjectID),
    teacher(TeacherID, TName, _, _, _),
    subject(SubjectID, SName, _, _, _),
    format(atom(Issue), '⚠ ~w is not qualified to teach ~w', [TName, SName]).

check_assignment_issue(TeacherID, _, _, SlotID, _, Issue) :-
    \+ teacher_available(TeacherID, SlotID),
    teacher(TeacherID, TName, _, _, _),
    timeslot(SlotID, Day, Period, _, _),
    format(atom(Issue), '⚠ ~w is not available at ~w Period ~w', [TName, Day, Period]).

check_assignment_issue(_, SubjectID, RoomID, _, _, Issue) :-
    subject(SubjectID, _, _, Type, _),
    \+ suitable_room(RoomID, Type),
    room(RoomID, RName, _, RType),
    format(atom(Issue), '⚠ ~w (type: ~w) is not suitable for ~w sessions', [RName, RType, Type]).

check_assignment_issue(_, _, RoomID, _, ClassID, Issue) :-
    room(RoomID, _, Capacity, _),
    class_size(ClassID, Size),
    Size > Capacity,
    room(RoomID, RName, _, _),
    format(atom(Issue), '⚠ ~w capacity (~w) is insufficient for class size (~w)', [RName, Capacity, Size]).

check_assignment_issue(TeacherID, _, _, SlotID, _, Issue) :-
    get_current_timetable(Timetable),
    has_teacher_conflict(TeacherID, SlotID, Timetable),
    teacher(TeacherID, TName, _, _, _),
    format(atom(Issue), '⚠ ~w already has an assignment at this time', [TName]).

check_assignment_issue(_, _, RoomID, SlotID, _, Issue) :-
    get_current_timetable(Timetable),
    has_room_conflict(RoomID, SlotID, Timetable),
    room(RoomID, RName, _, _),
    format(atom(Issue), '⚠ ~w is already occupied at this time', [RName]).
```

### API Endpoints

```prolog
:- http_handler(root(api/validate/teacher), handle_validate_teacher, []).
:- http_handler(root(api/validate/subject), handle_validate_subject, []).
:- http_handler(root(api/validate/room), handle_validate_room, []).
:- http_handler(root(api/validate/assignment), handle_validate_assignment, []).

handle_validate_teacher(Request) :-
    cors_headers,
    member(method(post), Request),
    http_read_json(Request, TeacherData),
    validate_teacher_input(TeacherData, ValidationResult),
    reply_json_dict(ValidationResult).

handle_validate_subject(Request) :-
    cors_headers,
    member(method(post), Request),
    http_read_json(Request, SubjectData),
    validate_subject_input(SubjectData, ValidationResult),
    reply_json_dict(ValidationResult).

handle_validate_room(Request) :-
    cors_headers,
    member(method(post), Request),
    http_read_json(Request, RoomData),
    validate_room_input(RoomData, ValidationResult),
    reply_json_dict(ValidationResult).

handle_validate_assignment(Request) :-
    cors_headers,
    member(method(post), Request),
    http_read_json(Request, AssignmentData),
    check_assignment_feasibility(AssignmentData, FeasibilityResult),
    reply_json_dict(FeasibilityResult).
```

### Frontend Implementation

**HTML Addition**:
```html
<!-- Add validation feedback to forms -->
<form id="teacher-form">
    <h3>Add Teacher</h3>
    <div class="form-group">
        <label>Name:</label>
        <input type="text" id="teacher-name" required>
        <div class="validation-feedback"></div>
    </div>
    <div class="form-group">
        <label>Qualified Subjects:</label>
        <select id="teacher-subjects" multiple>
            <!-- Options populated dynamically -->
        </select>
        <div class="validation-feedback"></div>
    </div>
    <div class="form-group">
        <label>Max Load (hours/week):</label>
        <input type="number" id="teacher-maxload" min="1" max="40">
        <div class="validation-feedback"></div>
    </div>
    <button type="submit">Add Teacher</button>
</form>
```

**CSS Addition**:
```css
.validation-feedback {
    margin-top: 0.5rem;
    font-size: 0.9rem;
}

.validation-feedback.valid {
    color: var(--success-color);
}

.validation-feedback.invalid {
    color: var(--danger-color);
}

.validation-feedback.warning {
    color: var(--warning-color);
}

.validation-feedback::before {
    margin-right: 0.5rem;
}

.validation-feedback.valid::before {
    content: '✓';
}

.validation-feedback.invalid::before {
    content: '✗';
}

.validation-feedback.warning::before {
    content: '⚠';
}
```

**JavaScript Addition**:
```javascript
// Real-time validation for teacher form
const teacherForm = document.getElementById('teacher-form');
const teacherInputs = teacherForm.querySelectorAll('input, select');

teacherInputs.forEach(input => {
    input.addEventListener('blur', async () => {
        await validateTeacherForm();
    });
    
    input.addEventListener('input', debounce(async () => {
        await validateTeacherForm();
    }, 500));
});

async function validateTeacherForm() {
    const data = {
        name: document.getElementById('teacher-name').value,
        qualified_subjects: Array.from(document.getElementById('teacher-subjects').selectedOptions).map(o => o.value),
        max_load: parseInt(document.getElementById('teacher-maxload').value)
    };
    
    try {
        const response = await fetch(`${API_BASE}/validate/teacher`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
        const result = await response.json();
        
        displayValidationFeedback(teacherForm, result);
    } catch (error) {
        console.error('Validation error:', error);
    }
}

function displayValidationFeedback(form, result) {
    const feedbackElements = form.querySelectorAll('.validation-feedback');
    feedbackElements.forEach(el => el.innerHTML = '');
    
    if (result.status === 'valid') {
        const feedback = form.querySelector('.validation-feedback');
        feedback.className = 'validation-feedback valid';
        feedback.textContent = 'All fields are valid';
        
        if (result.warnings && result.warnings.length > 0) {
            result.warnings.forEach(warning => {
                const warningEl = document.createElement('div');
                warningEl.className = 'validation-feedback warning';
                warningEl.textContent = warning;
                form.appendChild(warningEl);
            });
        }
    } else {
        result.errors.forEach(error => {
            const errorEl = document.createElement('div');
            errorEl.className = 'validation-feedback invalid';
            errorEl.textContent = error;
            form.appendChild(errorEl);
        });
    }
}

// Debounce helper
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}
```

### MFAI Concept Demonstration

This feature demonstrates:
- **Proactive AI Reasoning**: Validates before submission
- **Constraint Checking**: Real-time constraint verification
- **User Guidance**: Immediate feedback improves data quality

---

## Integration with Main Design Document

These 10 advanced features should be integrated into the main design document as follows:

1. **Add new modules** to the Components section
2. **Add new API endpoints** to the API Server section
3. **Update frontend components** with new UI elements
4. **Add correctness properties** for each feature
5. **Update MFAI concept mapping** to show how features demonstrate AI concepts

### Updated MFAI Concept Mapping

| MFAI Concept | Original Demo | Advanced Feature Enhancement |
|--------------|---------------|------------------------------|
| **Explainable AI** | N/A | Feature 1: XAI with proof tracing |
| **Decision Support** | Basic conflict detection | Feature 2: Smart conflict suggestions |
| **Robustness** | N/A | Feature 3: Scenario simulation |
| **Multi-Objective Optimization** | Basic CSP | Feature 4: Quality scoring system |
| **AI Advisory** | N/A | Feature 5: Recommendation engine |
| **Data Visualization** | Basic grid | Feature 6: Interactive heatmaps |
| **Algorithm Transparency** | N/A | Feature 7: Search visualization |
| **Solution Space Exploration** | Single solution | Feature 8: Multiple solutions |
| **Customizable AI** | Fixed constraints | Feature 9: Dynamic constraint weights |
| **Proactive Reasoning** | Post-validation | Feature 10: Real-time validation |

### Summary

These 10 advanced features transform the basic timetable generator into a comprehensive "AI Intelligent Timetable Decision System" that demonstrates:

- **Transparency**: XAI explanations and search visualization
- **Intelligence**: Smart suggestions and recommendations
- **Adaptability**: Scenario simulation and multiple solutions
- **Customization**: Adjustable constraint priorities
- **Proactivity**: Real-time validation and feedback
- **Visualization**: Heatmaps and quality metrics
- **Decision Support**: Comprehensive analytics and comparisons

This will significantly enhance the academic value of the project and demonstrate advanced AI capabilities beyond basic constraint satisfaction.

