# System Architecture

## AI-Based Timetable Generation System

---

## 1. High-Level Architecture

### Three-Tier Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  PRESENTATION TIER                           │
│                   (Web Browser)                              │
│  ┌────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │   Forms    │  │  Timetable   │  │    Analytics     │   │
│  │  (Input)   │  │     Grid     │  │    Dashboard     │   │
│  └────────────┘  └──────────────┘  └──────────────────┘   │
│         HTML/CSS/JavaScript (Frontend)                       │
└─────────────────────────────────────────────────────────────┘
                            │
                    HTTP/JSON (REST API)
                            │
┌─────────────────────────────────────────────────────────────┐
│                   APPLICATION TIER                           │
│              SWI-Prolog Backend (API Server)                 │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                   api_server.pl                       │   │
│  │  (HTTP Server, Request Routing, JSON Handling)       │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                     LOGIC TIER                               │
│              Core AI Modules (Prolog)                        │
│  ┌──────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │knowledge_base│  │timetable_generator│  │probability_  │  │
│  │    .pl       │  │       .pl         │  │  module.pl   │  │
│  └──────────────┘  └──────────────────┘  └──────────────┘  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │constraints.pl│  │ csp_solver.pl│  │ matrix_model.pl  │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Advanced Feature Modules                 │   │
│  │  conflict_resolver | recommendation_engine |         │   │
│  │  multi_solution_generator | scenario_simulator |     │   │
│  │  nl_query | heatmap_generator | constraint_graph |   │   │
│  │  complexity_analyzer | conflict_predictor |          │   │
│  │  pattern_analyzer | quality_scorer | genetic_optimizer│  │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Module Dependency Graph

```
                    api_server.pl
                         │
          ┌──────────────┼──────────────────────┐
          │              │                       │
          ▼              ▼                       ▼
timetable_generator  [advanced modules]    logging.pl
     │    │    │
  ┌──┘    │    └──────────────┐
  ▼       ▼                   ▼
csp_solver  constraints  probability_module
  │           │
  └─────┬─────┘
        │
  ┌─────┴──────────┐
  ▼                ▼
knowledge_base  matrix_model
```

---

## 3. Module Descriptions

### Foundation Layer

**knowledge_base.pl**
- MFAI Concept: First Order Logic
- Stores facts: `teacher/5`, `subject/5`, `room/4`, `timeslot/5`, `class/3`
- Rules: `qualified/2` (teacher-subject), `suitable_room/2` (room-subject type)
- Supports dynamic assertion/retraction for runtime data entry

**matrix_model.pl**
- MFAI Concept: Linear Algebra
- Represents timetable as a 2D matrix indexed by (class, slot)
- Operations: `create_matrix/3`, `matrix_get/4`, `matrix_set/5`, `scan_matrix/3`
- Enables efficient conflict detection via row/column scanning

### Logic Layer

**constraints.pl**
- MFAI Concept: Propositional Logic
- Hard constraints: no teacher double-booking, no room double-booking,
  teacher qualification, room suitability, class availability
- Soft constraints: workload balance, time preferences, schedule compactness
- Exports: `check_all_hard_constraints/6`, `calculate_soft_score/2`

**csp_solver.pl**
- MFAI Concept: Constraint Satisfaction Problems
- Backtracking search with forward checking (arc consistency)
- Heuristics: MRV (Minimum Remaining Values), Degree Heuristic, LCV (Least Constraining Value)
- Node limit: configurable (default 10,000) with timeout (default 300s)
- Exports: `solve_csp/3`

**probability_module.pl**
- MFAI Concept: Probabilistic Reasoning
- Calculates schedule reliability using conditional probabilities
- Models teacher availability, room availability, class occurrence
- Formula: `P(schedule) = ∏ P(teacher_i) × P(room_i) × P(class_i)`
- Exports: `calculate_reliability/2`

### Application Layer

**timetable_generator.pl**
- MFAI Concept: Logical Inference (backward chaining)
- Orchestrates: resource loading → session creation → CSP solving → validation
- Provides: assignment explanations, conflict detection, conflict repair
- Exports: `generate_timetable/1`, `explain_assignment/5`, `detect_conflicts/1`

**api_server.pl**
- HTTP server using SWI-Prolog `library(http/http_server)`
- Routes all REST endpoints to appropriate backend predicates
- Handles JSON serialization/deserialization
- CORS headers for browser access

### Advanced Feature Modules

| Module | Feature | Description |
|--------|---------|-------------|
| `conflict_resolver.pl` | Conflict Repair | Suggests minimal changes to fix conflicts |
| `recommendation_engine.pl` | Recommendations | Proactive scheduling improvement suggestions |
| `multi_solution_generator.pl` | Multi-Solution | Generates N alternative timetables with quality scores |
| `scenario_simulator.pl` | What-If Analysis | Simulates impact of resource changes |
| `nl_query.pl` | Natural Language | Answers queries like "who teaches CS-A on Monday?" |
| `heatmap_generator.pl` | Heatmap | Room/teacher utilization heatmap data |
| `constraint_graph.pl` | Constraint Graph | Visualizes constraint relationships between resources |
| `complexity_analyzer.pl` | Complexity | Measures problem size, branching factor, constraint density |
| `conflict_predictor.pl` | Prediction | Predicts likely conflicts before generation |
| `pattern_analyzer.pl` | Patterns | Identifies recurring schedule patterns |
| `quality_scorer.pl` | Quality | Multi-dimensional timetable quality scoring |
| `genetic_optimizer.pl` | Optimization | Genetic algorithm for post-generation improvement |
| `learning_module.pl` | Learning | Adapts preferences from user feedback |

---

## 4. Data Flow

### Timetable Generation Flow

```
User Input (browser forms)
        │
        ▼ POST /api/resources
api_server.pl → parse JSON → assert facts into knowledge_base
        │
        ▼ POST /api/generate
timetable_generator.pl
  1. get_all_teachers/subjects/rooms/slots/classes from knowledge_base
  2. create_sessions/1 → list of (class, subject, sessions_needed)
  3. solve_csp/3 → assigns each session to (teacher, room, slot)
     ├── select_unassigned_variable/2  [MRV heuristic]
     ├── order_domain_values/3         [LCV heuristic]
     ├── check_all_hard_constraints/6  [constraint checking]
     └── forward_check/4               [arc consistency]
  4. calculate_reliability/2 → probability score
  5. store result as assigned/5 facts
        │
        ▼ GET /api/timetable
api_server.pl → collect assigned/5 facts → serialize to JSON → browser
        │
        ▼ (browser renders timetable grid)
```

### Conflict Detection Flow

```
GET /api/conflicts
        │
        ▼
timetable_generator.pl → detect_conflicts/1
  ├── scan for teacher double-bookings (same teacher, same slot, different rooms)
  ├── scan for room double-bookings (same room, same slot, different classes)
  └── scan for constraint violations (unqualified teacher, wrong room type)
        │
        ▼
Format conflict list with descriptions → JSON → browser highlights cells
```

---

## 5. API Reference

### POST /api/resources

Submit all scheduling resources. Call before generating.

Request body:
```json
{
  "teachers": [
    {"id": "t1", "name": "Dr. Alice", "subjects": ["s1","s2"], "max_hours": 20, "preferences": []}
  ],
  "subjects": [
    {"id": "s1", "name": "Data Structures", "type": "theory", "hours_per_week": 3, "requires_lab": false}
  ],
  "rooms": [
    {"id": "r1", "name": "Room 101", "type": "classroom", "capacity": 40}
  ],
  "timeslots": [
    {"id": "slot1", "day": "monday", "period": 1, "start": "09:00", "end": "10:00"}
  ],
  "classes": [
    {"id": "c1", "name": "CS-A", "size": 35, "subjects": ["s1","s2"]}
  ]
}
```

Response: `{"status": "ok", "message": "Resources loaded"}`

---

### POST /api/generate

Trigger timetable generation.

Request body: `{}` (uses previously submitted resources)

Response:
```json
{
  "status": "ok",
  "assignments": [
    {"class_id": "c1", "subject_id": "s1", "teacher_id": "t1",
     "room_id": "r1", "slot_id": "slot1"}
  ],
  "reliability": 0.923
}
```

---

### GET /api/timetable

Retrieve the current timetable.

Response:
```json
{
  "status": "ok",
  "timetable": {
    "slots": ["slot1", "slot2", ...],
    "assignments": [...]
  }
}
```

---

### POST /api/explain

Get AI explanation for a specific assignment.

Request: `{"class_id": "c1", "subject_id": "s1", "teacher_id": "t1", "room_id": "r1", "slot_id": "slot1"}`

Response:
```json
{
  "status": "ok",
  "explanation": "Dr. Alice assigned to Data Structures for CS-A because: teacher is qualified (FOL rule), Room 101 is suitable (theory class), slot1 is available for all parties, workload within limits."
}
```

---

### GET /api/conflicts

Response:
```json
{
  "status": "ok",
  "conflicts": [
    {"type": "teacher_double_booking", "teacher_id": "t1", "slot_id": "slot3",
     "description": "Dr. Alice is assigned to two classes at the same time"}
  ]
}
```

---

### POST /api/repair

Request: `{"conflict": {...}}` (conflict object from /api/conflicts)

Response:
```json
{
  "status": "ok",
  "suggestions": [
    {"action": "reassign", "assignment": {...}, "alternative_slot": "slot5",
     "reason": "slot5 is free for all parties"}
  ]
}
```

---

### GET /api/analytics

Response:
```json
{
  "status": "ok",
  "analytics": {
    "teacher_utilization": {"t1": 0.75, "t2": 0.60},
    "room_utilization": {"r1": 0.80, "r2": 0.45},
    "total_assignments": 24,
    "conflicts_count": 0
  }
}
```

---

### GET /api/export?format=json|csv|text

Returns timetable in the requested format.

---

### POST /api/multi_generate

Request: `{"count": 3}` — generate N alternative timetables.

Response:
```json
{
  "status": "ok",
  "solutions": [
    {"id": 1, "quality_score": 0.87, "reliability": 0.92, "assignments": [...]},
    {"id": 2, "quality_score": 0.83, "reliability": 0.89, "assignments": [...]}
  ]
}
```

---

### POST /api/simulate

What-if scenario simulation.

Request: `{"change": {"type": "remove_teacher", "teacher_id": "t1"}}`

Response:
```json
{
  "status": "ok",
  "impact": {
    "affected_assignments": 5,
    "unresolvable_conflicts": 2,
    "suggested_reassignments": [...]
  }
}
```

---

### POST /api/nl_query

Request: `{"query": "who teaches CS-A on Monday?"}`

Response:
```json
{
  "status": "ok",
  "answer": "CS-A has Data Structures (Dr. Alice, Room 101, 09:00) and Algorithms (Prof. Bob, Room 102, 10:00) on Monday."
}
```

---

## 6. CSP Formulation

### Variables
Each session `(class C, subject S, session_number N)` is a variable.

### Domain
Each variable's domain = all valid `(teacher T, room R, slot SL)` triples where:
- `qualified(T, S)` holds
- `suitable_room(R, S)` holds
- `T`, `R`, `C` are all available at `SL`

### Constraints

Hard (must satisfy):
1. No teacher assigned to two sessions at the same slot
2. No room assigned to two sessions at the same slot
3. Teacher must be qualified for the subject
4. Room type must match subject type
5. Class cannot have two sessions at the same slot

Soft (optimize):
1. Minimize teacher workload imbalance
2. Avoid late-day theory classes
3. Avoid back-to-back lab sessions
4. Minimize schedule gaps

### Search Strategy
1. Select variable with fewest remaining domain values (MRV)
2. Break ties using degree heuristic (most constraints)
3. Order values by least constraining value (LCV)
4. After each assignment, run forward checking to prune domains
5. Backtrack on empty domain

---

## 7. MFAI Concept Mapping

| MFAI Concept | Module | Demonstration |
|-------------|--------|---------------|
| Linear Algebra | `matrix_model.pl` | Timetable as 2D matrix; row/column operations for conflict detection |
| Propositional Logic | `constraints.pl` | Boolean constraint expressions: `no_teacher_conflict ∧ qualified ∧ suitable_room` |
| First Order Logic | `knowledge_base.pl` | `∀T,S: qualified(T,S) ← teaches(T,S) ∧ certified(T,S)` |
| Logical Inference | `timetable_generator.pl` | Backward chaining to derive explanations and check rules |
| CSP | `csp_solver.pl` | Backtracking + forward checking + MRV/Degree/LCV heuristics |
| Probabilistic Reasoning | `probability_module.pl` | `P(valid) = ∏ P(teacher_avail) × P(room_avail) × P(class_occurs)` |

---

## 8. Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Backend | SWI-Prolog 8.x | Logic programming, inference, HTTP server |
| HTTP | `library(http/http_server)` | REST API server |
| JSON | `library(http/http_json)` | JSON parsing and serialization |
| Frontend | HTML5 + CSS3 + JS (ES6+) | Web interface |
| API | Fetch API | Async HTTP requests from browser |
| Testing | Custom PBT framework | 80 tests (33 unit + 47 property-based) |

---

## 9. Known Limitations and Future Work

| Limitation | Impact | Potential Fix |
|-----------|--------|---------------|
| In-memory storage | Data lost on restart | Add persistent database |
| Single-threaded CSP | Slow for 10+ classes | Parallel search |
| No PDF export | Limited export options | Add PDF library |
| Limited NL query patterns | Narrow query support | Extend NL parser |
| No authentication | Single-user only | Add session management |

---

*Architecture Document Version: 2.0*
*Last Updated: 2026*
