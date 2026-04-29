# Design Document: Full Frontend Fix

## Overview

This document covers the design for fixing and completing all major frontend features of the AI Timetable Generation System. The backend (Prolog) is largely working — the problems are in the frontend JavaScript: broken initialization chains, missing null-checks, export not working client-side, analytics not auto-loading, and the "Fix Issues First" button not actually fixing anything.

The approach is surgical: fix each section's JS function, wire up missing event handlers, and add client-side fallbacks where the backend endpoint is unreliable.

## Architecture

```
User Browser
  └── frontend/index.html
        ├── frontend/style.css
        └── frontend/script.js
              ├── DOMContentLoaded → all initialize*() functions
              ├── resourceData (in-memory state)
              ├── currentTimetable (in-memory state)
              └── API calls → http://localhost:8081/api/*
```

All fixes are in `frontend/script.js` only, with minor additions to `frontend/index.html` for missing HTML elements (scenario dropdowns, analytics load button).

## Components and Interfaces

### 1. Fix Issues First (Requirement 1)

**Current state:** Calls `checkConflicts()` and shows a notification. Does nothing to the data.

**Fix:** Replace the click handler with `autoFixIssues()`:

```javascript
async function autoFixIssues() {
  // 1. Parse bottleneck items from the DOM
  // 2. For each bottleneck type, mutate resourceData:
  //    - room shortage (theory) → add Fix_Rooms classrooms
  //    - room shortage (lab)    → add extra lab rooms
  //    - timeslot shortage      → extend to 45 slots (9×5)
  //    - teacher overload       → bump maxload to demand+5
  // 3. POST /api/resources with updated resourceData
  // 4. Re-run checkConflicts()
  // 5. Show success/failure notification
}
```

Fix_Rooms to add for theory shortage: `1002, 1003, 1102, 1103, 1124, 1125` (capacity 72, type classroom).
Extra labs to add: `L-001, L-002, L-003` (capacity 30, type lab).

### 2. Generate Timetable (Requirement 2)

**Current state:** Crashes if `generate-btn` is null. No auto-submit.

**Fix:** Already partially done. Ensure:
- `generateTimetable()` auto-submits if `!_resourcesSubmittedToBackend`
- All DOM lookups are null-safe
- On success, navigate to visualize and call `renderTimetable()`

### 3. Export (Requirement 3)

**Current state:** Calls `GET /api/export?format=pdf` — backend returns JSON, not a file blob. PDF export doesn't work in browsers without a library.

**Fix:** Client-side export:
- **JSON**: `JSON.stringify(currentTimetable)` → Blob download
- **CSV**: Build CSV string from `currentTimetable.assignments` → Blob download  
- **PDF**: Use `window.print()` with a print-specific CSS that shows only the timetable grid

```javascript
function exportTimetable(format) {
  if (!currentTimetable) { showNotification('error', 'Generate a timetable first'); return; }
  if (format === 'json') exportJSON();
  else if (format === 'csv') exportCSV();
  else if (format === 'pdf') exportPDF();
}
```

### 4. Scenarios (Requirement 4)

**Current state:** `initializeScenarios()` exists and wires up buttons. The HTML has scenario type select and param panels. The `simulateScenario()` function calls `POST /api/simulate`. This mostly works but the scenario dropdowns need to be populated with actual teacher/room IDs from `resourceData`.

**Fix:**
- On section switch to `scenarios`, populate `#scenario-teacher-id` select with teachers from `resourceData`
- Populate `#scenario-room-id` select with rooms from `resourceData`
- Add "no timetable" guard at top of `simulateScenario()`

### 5. Analytics (Requirement 5)

**Current state:** Analytics section HTML exists with 4 cards. No auto-load on section switch. `GET /api/analytics` works but nothing calls it when you navigate there.

**Fix:**
- In `initializeNavigation()`, detect when user switches to `analytics` section and call `loadAnalytics()`
- `loadAnalytics()` calls `GET /api/analytics` and renders each card:
  - Teacher Workload: bar chart using CSS widths
  - Room Utilization: percentage bars
  - Schedule Density: sessions/day table
  - Constraint Satisfaction: score badge

```javascript
async function loadAnalytics() {
  const resp = await fetch(`${API_BASE_URL}/analytics`);
  const data = await resp.json();
  renderTeacherWorkload(data.analytics.teacher_workload);
  renderRoomUtilization(data.analytics.room_utilization);
  renderScheduleDensity(data.analytics.schedule_density);
  renderConstraintSatisfaction(data.analytics.constraint_satisfaction);
}
```

### 6. Recommendations (Requirement 6)

**Current state:** `initializeRecommendations()` wires up load button. `GET /api/recommendations` works. Apply button calls `POST /api/apply_recommendation`. This mostly works — just needs auto-load on section switch.

### 7. Heatmap (Requirement 7)

**Current state:** `initializeHeatmap()` and `loadHeatmap()` exist. `GET /api/heatmap` works. Just needs auto-load on section switch.

### 8. All Other Sections (Requirement 9)

**Sections and their auto-load functions:**

| Section | HTML id | Initialize fn | Auto-load fn | Backend endpoint |
|---|---|---|---|---|
| AI Search | search-stats-section | — | loadSearchStatistics() | GET /api/search_stats |
| Multi Solutions | multi-solutions-section | initializeMultiSolutions() | — | POST /api/generate_multiple |
| Constraints | constraints-section | initializeConstraintSliders() | — | GET /api/constraint_weights |
| GA Optimize | ga-section | initializeGA() | — | POST /api/optimize_ga |
| Drag & Edit | drag-edit-section | initializeDragEdit() | — | POST /api/apply_move |
| Learning | learning-section | — | loadLearningStats() | GET /api/learning_stats |
| Pattern Discovery | pattern-discovery-section | — | discoverPatterns() | POST /api/discover_patterns |
| What-If Dashboard | whatif-dashboard-section | — | updateWhatIfDashboard() | POST /api/analyze_scenarios |
| Constraint Graph | constraint-graph-section | — | loadConstraintGraph() | GET /api/constraint_graph |
| Complexity | complexity-section | — | loadComplexityAnalysis() | GET /api/complexity_analysis |
| NL Query | nl-query-section | — | (on submit) | POST /api/nl_query |
| Versions | versions-section | initializeVersioning() | loadVersions() | GET /api/versions |

**Fix for all:** Add a `sectionAutoLoad` map in `switchSection()`:

```javascript
const sectionAutoLoad = {
  'analytics':          loadAnalytics,
  'recommendations':    loadRecommendations,
  'heatmap':            () => loadHeatmap(currentHeatmapType || 'teacher'),
  'search-stats':       loadSearchStatistics,
  'learning':           loadLearningStats,
  'constraint-graph':   loadConstraintGraph,
  'complexity':         loadComplexityAnalysis,
  'versions':           loadVersions,
};
```

For sections requiring a timetable, add a `requiresTimetable` guard:
```javascript
const requiresTimetable = ['visualize','analytics','recommendations','heatmap',
  'search-stats','multi-solutions','constraints','ga','drag-edit','learning',
  'pattern-discovery','whatif-dashboard','constraint-graph','complexity',
  'nl-query','versions'];
```

If `!currentTimetable` and section is in `requiresTimetable`, inject a banner:
```html
<div class="no-timetable-banner">
  ⚠ No timetable generated yet.
  <button onclick="switchSection('generate')">Go to Generate →</button>
</div>
```

## Data Models

### resourceData (frontend state)
```javascript
{
  teachers: [{ id, name, subjects[], maxload, availability[] }],
  subjects: [{ id, name, hours, type, duration }],
  rooms:    [{ id, name, capacity, type }],
  timeslots:[{ id, day, period, start, duration }],
  classes:  [{ id, name, subjects[] }]
}
```

### Fix_Rooms (auto-added on theory shortage)
```javascript
[
  { id: 'fix_r1', name: '1002', capacity: 72, type: 'classroom' },
  { id: 'fix_r2', name: '1003', capacity: 72, type: 'classroom' },
  { id: 'fix_r3', name: '1102', capacity: 72, type: 'classroom' },
  { id: 'fix_r4', name: '1103', capacity: 72, type: 'classroom' },
  { id: 'fix_r5', name: '1124', capacity: 72, type: 'classroom' },
  { id: 'fix_r6', name: '1125', capacity: 72, type: 'classroom' }
]
```

### Extra Labs (auto-added on lab shortage)
```javascript
[
  { id: 'fix_l1', name: 'L-001', capacity: 30, type: 'lab' },
  { id: 'fix_l2', name: 'L-002', capacity: 30, type: 'lab' },
  { id: 'fix_l3', name: 'L-003', capacity: 30, type: 'lab' }
]
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do.*

Property 1: Fix Issues adds rooms without duplicates
*For any* resourceData state with a room shortage, after autoFixIssues() runs, the rooms array should contain the fix rooms and no room ID should appear more than once.
**Validates: Requirements 1.2, 1.3**

Property 2: Export produces non-empty output
*For any* valid currentTimetable with at least one assignment, exportCSV() should produce a string with at least one data row beyond the header.
**Validates: Requirements 3.2, 3.3**

Property 3: Section switch auto-loads data
*For any* section that has an auto-load function, switching to that section should result in the section's content being populated (not showing "No data available") when a timetable exists.
**Validates: Requirements 5.1, 6.1, 7.1, 9.1**

Property 4: Generate always submits before generating
*For any* state where resourceData is non-empty but _resourcesSubmittedToBackend is false, calling generateTimetable() should result in a POST /api/resources call before POST /api/generate.
**Validates: Requirements 2.1**

## Error Handling

- All `fetch()` calls wrapped in try/catch with `showNotification('error', ...)`
- All `getElementById()` calls null-checked before use
- Sections requiring timetable show "Generate first" banner if `!currentTimetable`
- Export functions check `!currentTimetable` before proceeding

## Testing Strategy

Unit tests: verify `autoFixIssues()` adds correct rooms, verify `exportCSV()` output format.
Property tests: verify no duplicate room IDs after fix, verify CSV has correct column count for any timetable.
