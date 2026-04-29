# AI-Based Timetable Generation System — Guide

## Why Timetable Generation Fails

The CSP solver's `generate_domain` requires every slot in a teacher's availability list to match an actual timeslot ID:

```prolog
member(SlotID, Avail)   % slot must be in teacher's availability list
```

If you enter teachers manually and leave availability blank, or use slot IDs that don't match what you entered in the timeslots form (e.g. `slot_1` vs `slot1`), the domain comes up empty and the CSP fails immediately with no valid assignment.

**The example dataset already handles this correctly.** Use it to get generation working first.

---

## Correct Workflow

1. Go to **Resources** tab → click **"Load Example Dataset"**
2. Click **"Submit All Resources to Backend"** → auto-navigates to Generate
3. Click **"Generate Timetable"** → succeeds in under 1 second (12 sessions assigned)

If entering resources manually, ensure the slot IDs in each teacher's availability **exactly match** the IDs you gave the timeslots.
Example: if timeslot id is `slot1`, availability must list `slot1` — not `slot_1`.

---

## All 19 Tabs — Functions and Purpose

| Tab | Section ID | What it does |
|---|---|---|
| Resources | `resources-section` | Add teachers, subjects, rooms, timeslots, classes manually or load the example dataset. Submit all to backend via POST `/api/resources`. |
| Generate | `generate-section` | Click "Generate Timetable" → POST `/api/generate` → CSP solver runs → auto-navigates to Visualize on success. |
| Visualize | `visualize-section` | Renders the timetable as a room×slot grid. Shows reliability score. Export to PDF / CSV / JSON. |
| Scenarios | `scenarios-section` | Simulate what-if scenarios (teacher absence, room closure) via POST `/api/simulate`. |
| Analytics | `analytics-section` | Room and teacher utilization charts via GET `/api/analytics`. |
| Recommendations | `recommendations-section` | AI suggestions to improve the schedule via GET `/api/recommendations`. |
| Heatmap | `heatmap-section` | Visual heatmap of room/slot usage density via GET `/api/heatmap`. |
| Search Stats | `search-stats-section` | CSP solver search statistics — nodes explored, backtracks, domain sizes — via GET `/api/search_stats`. |
| Multi-Solutions | `multi-solutions-section` | Generate N alternative timetables and compare them via POST `/api/generate_multiple`. |
| Constraints | `constraints-section` | View and edit constraint weights (teacher load, room type preference, etc.) via GET/POST `/api/constraint_weights`. |
| GA Optimize | `ga-section` | Genetic algorithm optimizer to improve the quality score of the current timetable via POST `/api/optimize_ga`. |
| Drag Edit | `drag-edit-section` | Drag-and-drop manual editing of assignments. Validates moves via POST `/api/validate_move`, applies via POST `/api/apply_move`. |
| Learning | `learning-section` | Adaptive learning from past schedules — view stats via GET `/api/learning_stats`, apply learned preferences via POST `/api/apply_learning`. |
| Pattern Discovery | `pattern-discovery-section` | Discover recurring scheduling patterns in historical data via POST `/api/discover_patterns`. |
| What-If Dashboard | `whatif-dashboard-section` | Multi-scenario comparison dashboard — run and compare multiple scenarios via POST `/api/analyze_scenarios`. |
| Constraint Graph | `constraint-graph-section` | Visual graph of resource constraints and their relationships via GET `/api/constraint_graph`. |
| Complexity | `complexity-section` | Problem complexity analysis — session count, domain sizes, constraint density — via GET `/api/complexity_analysis`. |
| NL Query | `nl-query-section` | Natural language queries about the timetable (e.g. "Who teaches on Monday?") via POST `/api/nl_query`. |
| Versions | `versions-section` | Save, load, compare, and rollback timetable versions via `/api/save_version`, `/api/versions`, `/api/version`, `/api/compare_versions`, `/api/rollback`. |

---

## API Endpoints Reference

| Method | Endpoint | Purpose |
|---|---|---|
| POST | `/api/resources` | Submit all resource data |
| POST | `/api/generate` | Run CSP solver and generate timetable |
| GET | `/api/timetable` | Retrieve current timetable |
| GET | `/api/reliability` | Get reliability score and risk category |
| POST | `/api/explain` | Explain a specific assignment |
| POST | `/api/explain_detailed` | Detailed XAI explanation |
| GET | `/api/conflicts` | Detect conflicts in current timetable |
| POST | `/api/repair` | Auto-repair detected conflicts |
| GET | `/api/analytics` | Resource utilization analytics |
| GET | `/api/export` | Export timetable (JSON/CSV/text) |
| POST | `/api/simulate` | Simulate a what-if scenario |
| POST | `/api/compare_scenarios` | Compare two scenarios |
| GET | `/api/quality_score` | Get quality score breakdown |
| GET | `/api/recommendations` | Get AI improvement recommendations |
| GET | `/api/heatmap` | Get room/slot usage heatmap |
| GET | `/api/search_stats` | CSP search statistics |
| POST | `/api/generate_multiple` | Generate N alternative timetables |
| POST | `/api/compare_timetables` | Compare two timetables |
| GET | `/api/constraint_weights` | Get current constraint weights |
| POST | `/api/set_weights` | Update constraint weights |
| POST | `/api/generate_with_weights` | Generate with custom weights |
| POST | `/api/optimize_ga` | Run genetic algorithm optimizer |
| POST | `/api/validate_move` | Validate a drag-edit move |
| POST | `/api/apply_move` | Apply a validated move |
| GET | `/api/learning_stats` | Adaptive learning statistics |
| POST | `/api/apply_learning` | Apply learned preferences |
| POST | `/api/discover_patterns` | Discover scheduling patterns |
| POST | `/api/analyze_scenarios` | Multi-scenario analysis |
| GET | `/api/constraint_graph` | Constraint relationship graph |
| GET | `/api/complexity_analysis` | Problem complexity metrics |
| POST | `/api/nl_query` | Natural language timetable query |
| POST | `/api/predict_conflicts` | Predict potential conflicts |
| POST | `/api/save_version` | Save current timetable as a version |
| GET | `/api/versions` | List all saved versions |
| GET | `/api/version` | Load a specific version |
| POST | `/api/compare_versions` | Compare two saved versions |
| POST | `/api/rollback` | Rollback to a previous version |

---

## Starting the Server

```
& "C:\Program Files\swipl\bin\swipl.exe" main.pl
```

Server runs at `http://localhost:8081`. Frontend is served at the root URL.
