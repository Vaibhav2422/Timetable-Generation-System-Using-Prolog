# Developer Guide

## AI-Based Timetable Generation System

---

## Development Setup

### Prerequisites

- SWI-Prolog 8.x (`swipl`)
- A text editor or IDE with Prolog support (VS Code + Prolog extension recommended)
- Git

### Running the Server

```bash
# Windows
"C:\Program Files\swipl\bin\swipl.exe" main.pl

# macOS/Linux
swipl main.pl
```

### Running Tests

```bash
# Windows
"C:\Program Files\swipl\bin\swipl.exe" -g run_all_tests -t halt backend/testing.pl

# macOS/Linux
swipl -g run_all_tests -t halt backend/testing.pl
```

Expected: 80 tests pass (33 unit + 47 property-based).

---

## Adding a New Constraint

### 1. Add the constraint predicate to `backend/constraints.pl`

```prolog
%% check_no_back_to_back_labs(+TeacherID, +SlotID, +Assignments) is semidet
%  Fails if the teacher already has a lab session in the adjacent slot.
%  @param TeacherID  Teacher being assigned
%  @param SlotID     Proposed slot
%  @param Assignments Current assignment list
check_no_back_to_back_labs(TeacherID, SlotID, Assignments) :-
    \+ (
        member(assigned(_, _, SubjID, TeacherID, OtherSlot), Assignments),
        subject(SubjID, _, lab, _, _),
        adjacent_slot(SlotID, OtherSlot)
    ).
```

### 2. Export it from the module declaration

In `constraints.pl`, add to the export list:
```prolog
:- module(constraints, [
    ...
    check_no_back_to_back_labs/3,
    ...
]).
```

### 3. Integrate into `check_all_hard_constraints/6`

```prolog
check_all_hard_constraints(TeacherID, RoomID, SlotID, ClassID, SubjectID, Assignments) :-
    check_teacher_no_conflict(TeacherID, SlotID, Assignments),
    check_room_no_conflict(RoomID, SlotID, Assignments),
    check_teacher_qualified(TeacherID, SubjectID),
    check_room_suitable(RoomID, SubjectID),
    check_no_back_to_back_labs(TeacherID, SlotID, Assignments).  % <-- add here
```

### 4. Add a property test in `backend/testing.pl`

```prolog
test_no_back_to_back_labs :-
    assert_true(
        \+ (
            member(assigned(_, _, S1, T, Slot1), TestAssignments),
            member(assigned(_, _, S2, T, Slot2), TestAssignments),
            subject(S1, _, lab, _, _),
            subject(S2, _, lab, _, _),
            adjacent_slot(Slot1, Slot2)
        ),
        'No teacher has back-to-back lab sessions'
    ).
```

---

## Adding a New Resource Type

### 1. Declare the fact in `backend/knowledge_base.pl`

```prolog
% equipment/3: Represents AV equipment
% Format: equipment(EquipmentID, Name, Type)
:- dynamic equipment/3.
:- multifile equipment/3.

%% get_all_equipment(-Equipment) is det
get_all_equipment(Equipment) :- findall(E, equipment(E, _, _), Equipment).
```

### 2. Export the new predicates

Add to the module export list in `knowledge_base.pl`.

### 3. Add an API endpoint in `backend/api_server.pl`

```prolog
:- http_handler('/api/equipment', handle_equipment, [method(post)]).

handle_equipment(Request) :-
    http_read_json_dict(Request, Data),
    process_equipment(Data),
    reply_json_dict(_{status: ok}).
```

### 4. Add a form in `frontend/index.html` and handler in `frontend/script.js`

Follow the same pattern as the existing teacher/subject/room forms.

---

## Adding a New Optimization Strategy

### 1. Add a heuristic predicate to `backend/csp_solver.pl`

```prolog
%% select_variable_custom(+Unassigned, +Domains, +Assignments, -Selected) is det
%  Custom variable selection: prefer sessions with the most constrained teacher.
select_variable_custom([Session|_], Domains, Assignments, Session) :-
    % Custom logic here
    ...
```

### 2. Plug it into `select_variable/4`

```prolog
select_variable(Unassigned, Domains, Assignments, Selected) :-
    select_variable_custom(Unassigned, Domains, Assignments, Selected), !.
select_variable(Unassigned, Domains, Assignments, Selected) :-
    select_variable_mrv(Unassigned, Domains, Assignments, Selected).
```

---

## Adding a New API Endpoint

### 1. Register the handler in `backend/api_server.pl`

```prolog
:- http_handler('/api/my_endpoint', handle_my_endpoint, [method(get)]).

handle_my_endpoint(_Request) :-
    % Your logic here
    Result = _{status: ok, data: []},
    reply_json_dict(Result).
```

### 2. Add error handling

```prolog
handle_my_endpoint(_Request) :-
    catch(
        ( my_logic(Result),
          reply_json_dict(_{status: ok, result: Result}) ),
        Error,
        ( term_to_atom(Error, Msg),
          reply_json_dict(_{status: error, message: Msg}) )
    ).
```

### 3. Add a frontend call in `frontend/script.js`

```javascript
/**
 * Calls GET /api/my_endpoint and returns the result.
 * @async
 * @returns {Promise<Object>} The API response data.
 */
async function callMyEndpoint() {
    const response = await fetch(`${API_BASE_URL}/my_endpoint`);
    if (!response.ok) throw new Error('Request failed');
    return response.json();
}
```

---

## Testing Procedures

### Unit Tests

Unit tests are in `backend/testing.pl`. Each test group follows this pattern:

```prolog
test_my_feature :-
    % Setup test data
    assertz(teacher(t_test, 'Test Teacher', [s1], 20, [])),
    % Run the predicate
    my_predicate(t_test, Result),
    % Assert expected outcome
    assert_equals(Result, expected_value, 'my_predicate returns correct result'),
    % Cleanup
    retractall(teacher(t_test, _, _, _, _)).
```

Add your test to `run_all_tests/0`:

```prolog
run_all_tests :-
    ...
    run_test_group('My Feature', test_my_feature),
    ...
```

### Property-Based Tests

Property tests verify invariants over randomly generated inputs:

```prolog
prop_my_invariant :-
    % Generate random input
    random_teacher(T),
    random_subject(S),
    % Assert the property holds
    (qualified(T, S) -> true ; true),  % example: no crash on any input
    true.

test_my_property :-
    run_property_test(prop_my_invariant, 100, 'My invariant holds').
```

### Running a Single Test Group

```bash
swipl -g "consult('backend/testing.pl'), test_my_feature" -t halt
```

---

## Module Overview

| Module | Responsibility | Key Exports |
|--------|---------------|-------------|
| `knowledge_base.pl` | FOL facts and rules | `teacher/5`, `qualified/2`, `get_all_teachers/1` |
| `matrix_model.pl` | Matrix operations | `create_matrix/3`, `matrix_get/4`, `matrix_set/5` |
| `constraints.pl` | Constraint checking | `check_all_hard_constraints/6`, `calculate_soft_score/2` |
| `csp_solver.pl` | CSP search | `solve_csp/3` |
| `probability_module.pl` | Reliability | `schedule_reliability/2` |
| `timetable_generator.pl` | Orchestration | `generate_timetable/1`, `detect_conflicts/1` |
| `api_server.pl` | HTTP API | All `/api/*` handlers |
| `logging.pl` | Logging | `log_info/1`, `log_debug/1` |
| `testing.pl` | Test suite | `run_all_tests/0` |

---

## Code Style Guidelines

### Prolog

- Use `%% predicate/arity` for predicate documentation (PlDoc style)
- Document all parameters with `@param` and return values with `@returns`
- Use `is det` / `is semidet` / `is nondet` mode annotations
- Keep predicates short (< 20 lines); extract helpers
- Use `_` for unused variables, `_Name` for named-but-unused

```prolog
%% my_predicate(+Input, -Output) is det
%  Brief description of what this predicate does.
%  @param Input  Description of input
%  @param Output Description of output
my_predicate(Input, Output) :-
    process(Input, Output).
```

### JavaScript

- Use JSDoc for all exported/public functions
- Use `async/await` over raw Promises
- Handle errors with try/catch and `showNotification`
- Keep DOM manipulation in dedicated render functions

---

## Logging

Use the logging module for debug output:

```prolog
:- use_module(logging).

my_predicate(X) :-
    log_debug('Processing input'),
    log_info(X),
    ...
```

Log levels (set in `config.pl`): `debug` < `info` < `warning` < `error`

---

## Known Extension Points

| Feature | Where to Extend |
|---------|----------------|
| New constraint type | `constraints.pl` → `check_all_hard_constraints/6` |
| New heuristic | `csp_solver.pl` → `select_variable/4` or `order_domain_values/4` |
| New resource type | `knowledge_base.pl` + `api_server.pl` + `frontend/` |
| New export format | `timetable_generator.pl` → `format_timetable/3` |
| New NL query pattern | `nl_query.pl` → pattern matching rules |
| New optimization | `genetic_optimizer.pl` or new module |
| New analytics metric | `quality_scorer.pl` or `heatmap_generator.pl` |

---

## Requirements Traceability

Key requirements and their implementing modules:

| Requirement | Module |
|-------------|--------|
| 1.x Resource management | `knowledge_base.pl`, `api_server.pl` |
| 2.x Matrix representation | `matrix_model.pl` |
| 3.x Constraint checking | `constraints.pl` |
| 4.x CSP solving | `csp_solver.pl` |
| 5.x Soft constraints | `constraints.pl` |
| 7.x Generation | `timetable_generator.pl` |
| 8.x Reliability | `probability_module.pl` |
| 9.x Explanations | `timetable_generator.pl` |
| 14.x Documentation | `docs/` |
| 15.x Performance | `csp_solver.pl`, `config.pl` |
| 16.x Error handling | `api_server.pl`, `timetable_generator.pl` |
| 20.x Repair | `conflict_resolver.pl` |
| 22.x Analytics | `quality_scorer.pl`, `heatmap_generator.pl` |
| 24.x Validation | `api_server.pl` |
| 25.x Export | `timetable_generator.pl` |
| 26.x Testing | `backend/testing.pl` |
| 27.x Extensibility | All modules (modular design) |
