# Design Document: Frontend Bug Fixes

## Overview

This document describes the design for fixing five categories of bugs in the AI-Based Timetable Generation System frontend (`frontend/script.js`). All bugs were identified through live testing of the running system. The fixes are purely JavaScript — no backend changes are needed.

The root cause of most issues is a **duplicate code block** inserted near the end of `script.js` (around line 4599) that re-declares `const nlQueryHistory` and redefines `submitNLQuery`. Because `const` cannot be re-declared in the same scope, this causes a `SyntaxError` (or at minimum a `TypeError` in strict mode) that prevents the entire script from executing, which is why even basic things like the teacher form and resource panel don't work.

The secondary cause is a handful of fetch calls that reference `API_BASE` instead of `API_BASE_URL` — already partially fixed, but needs verification.

---

## Architecture

The system is a single-page application:

```
browser
  └── index.html          (structure + nav)
  └── style.css           (layout + theming)
  └── script.js           (all JS logic, ~5191 lines)
        ├── State: resourceData, currentTimetable, currentReliability
        ├── Navigation: initializeNavigation(), switchSection()
        ├── Resource forms: initializeResourceForms(), updateResourceCounts()
        ├── Generation: generateTimetable()
        ├── Visualization: renderTimetable(), updateReliabilityDisplay()
        ├── NL Query: submitNLQuery(), initNLQuery(), nlQueryHistory
        ├── Versions: initializeVersioning(), loadAndPreviewVersion()
        └── ... (19 other feature sections)
```

All API calls go to `http://localhost:8081/api/*` via `fetch()`.

---

## Components and Interfaces

### 1. Resource Panel (`updateResourceCounts`)

**Current state:** Works correctly in isolation. The function reads `resourceData.*length` and writes to badge DOM elements. The bug is that the function never gets called because the script crashes before `DOMContentLoaded` fires.

**Fix:** Remove the duplicate declarations that crash the script. Once the script loads cleanly, `updateResourceCounts()` will work as-is.

### 2. Navigation (`switchSection`)

**Current state:** `switchSection(name)` looks up `document.getElementById(name + '-section')` and toggles the `active` CSS class. Logic is correct. Same root cause — script crash prevents listeners from attaching.

**Fix:** Same as above — remove duplicates.

### 3. API Base URL (`API_BASE_URL`)

**Current state:** `API_BASE_URL` is defined once at line 11. Several fetch calls (lines 4181, 4695, 4991, 5017, 5088, 5117, 5158) used `API_BASE` (without `_URL`) — already fixed by the bulk replace done in the previous session.

**Fix:** Verify no remaining `API_BASE` (without `_URL`) references exist.

### 4. Duplicate NL Query Code

**Current state:** There are two complete NL query implementations in the file:

- **Implementation A** (lines ~4480–4590): The good one. Uses `let nlQueryHistory`, `submitNLQuery(queryText)` with a parameter, `addToNLHistory()`, `renderNLHistory()`, `escapeHtml()`. Registers its own `DOMContentLoaded` listener at line 4735.
- **Implementation B** (lines ~4599–4740): The duplicate. Declares `const nlQueryHistory = []` (conflicts with Implementation A's `let`), redefines `submitNLQuery()` with no parameter, redefines `initNLQuery()`, `renderNLHistory()`, `clearNLHistory()`, `escapeHtml()`.

**Fix:** Remove Implementation B entirely (lines ~4595–4740). Keep Implementation A which is more complete and uses `API_BASE_URL` correctly.

### 5. Example Dataset Loading

**Current state:** `loadExampleDataset()` correctly populates `resourceData` and calls `updateResourceCounts()`. Works once the script crash is fixed.

**Fix:** No code change needed beyond fixing the crash.

---

## Data Models

No data model changes. The existing `resourceData` object shape is correct:

```javascript
resourceData = {
  teachers:  [{ id, name, subjects, maxload, availability }],
  subjects:  [{ id, name, hours, type, duration }],
  rooms:     [{ id, name, capacity, type }],
  timeslots: [{ id, day, period, start, duration }],
  classes:   [{ id, name, subjects }]
}
```

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Resource badge count equals array length

*For any* resource type (teachers, subjects, rooms, timeslots, classes), after calling `updateResourceCounts()`, the text content of the corresponding badge element equals `resourceData[type].length`.

**Validates: Requirements 1.1, 1.3**

---

### Property 2: Exactly one section is active after navigation

*For any* nav button click, after `switchSection()` completes, exactly one `<section class="section">` element has the `active` CSS class, and it is the section whose id matches `{sectionName}-section`.

**Validates: Requirements 2.1, 2.2–2.8**

---

### Property 3: All fetch calls use API_BASE_URL

*For any* fetch call in script.js, the URL template literal references `API_BASE_URL` and not any other variable. No `ReferenceError` is thrown when any fetch call executes.

**Validates: Requirements 3.1, 3.2, 3.3**

---

### Property 4: No duplicate const/function declarations

*For any* `const` or `function` identifier declared at the top level of script.js, it appears exactly once. The browser can parse and execute the file without a `SyntaxError`.

**Validates: Requirements 4.1, 4.2, 4.3**

---

### Property 5: Example dataset loads correct counts

*For the* specific call to `loadExampleDataset()`, `resourceData` contains exactly 5 teachers, 8 subjects, 6 rooms, 25 timeslots, and 3 classes, and the badge DOM elements reflect these counts immediately after the call.

**Validates: Requirements 1.4, 5.1, 5.3**

---

## Error Handling

- If `document.getElementById(...)` returns `null` (element not in DOM), existing guards (`if (!input || !submitBtn) return`) already handle this gracefully.
- If the backend is unreachable, all fetch calls are wrapped in `try/catch` and call `showNotification('error', ...)`.
- No new error handling is needed — the fixes are structural (removing duplicate code).

---

## Testing Strategy

### Unit tests (examples)

Since this is a browser JS file without a test runner configured, tests are described as manual verification steps and browser console checks:

1. Open browser DevTools → Console. Reload the page. Verify **zero errors** on load.
2. Add a teacher via the form. Verify the Teachers badge increments to 1 and the name appears in the preview.
3. Click each nav tab. Verify the correct section becomes visible and the button turns white/active.
4. Click "Load Example Dataset". Verify badges show 5/8/6/25/3.
5. Click "Submit All Resources to Backend". Verify success notification and auto-navigation to Generate.

### Property-based tests

Because this is a browser frontend without a PBT framework, properties are validated through:

- **Property 1**: Automated by checking `badge.textContent === String(resourceData[type].length)` after each form submit in the browser console.
- **Property 2**: Automated by checking `document.querySelectorAll('.section.active').length === 1` after each nav click.
- **Property 3**: Static analysis — `grep -n "API_BASE[^_]" frontend/script.js` should return no results.
- **Property 4**: Static analysis — `grep -c "const nlQueryHistory" frontend/script.js` should return `1`; `grep -c "function submitNLQuery" frontend/script.js` should return `1`.
- **Property 5**: Console check after `loadExampleDataset()` — verify `resourceData.teachers.length === 5` etc.

### Testing framework note

No PBT library is used here since this is vanilla browser JavaScript. The properties above are verified through static analysis (grep) and manual browser console checks. If a test runner (e.g., Vitest + jsdom) is added in the future, these properties map directly to unit test assertions.
