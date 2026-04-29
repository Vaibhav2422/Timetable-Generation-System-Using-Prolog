# Implementation Plan: Full Frontend Fix

## Overview

Fix all frontend sections end-to-end. Each task is a focused code change in `frontend/script.js` (and minor HTML additions). Tasks build on each other — complete in order.

## Tasks

- [-] 1. Fix Issues First — auto-resolution
  - Replace `fix-issues-btn` click handler with `autoFixIssues()`
  - Parse bottleneck DOM text to detect shortage types
  - Add Fix_Rooms (1002, 1003, 1102, 1103, 1124, 1125) for theory shortage
  - Add L-001, L-002, L-003 for lab shortage
  - Extend timeslots to 45 slots for timeslot shortage
  - Bump teacher maxload for overload
  - POST /api/resources then re-run checkConflicts()
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8_

- [ ] 1.1 Write property test for autoFixIssues — no duplicate room IDs
  - **Property 1: Fix Issues adds rooms without duplicates**
  - **Validates: Requirements 1.2, 1.3**

- [-] 2. Fix export (client-side PDF, CSV, JSON)
  - Replace `exportTimetable()` with client-side implementation
  - JSON: Blob download of `JSON.stringify(currentTimetable)`
  - CSV: Build from assignments array, trigger download
  - PDF: `window.print()` with print CSS showing only timetable grid
  - Guard: show notification if `!currentTimetable`
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 2.1 Write property test for exportCSV — non-empty output
  - **Property 2: Export produces non-empty output**
  - **Validates: Requirements 3.2, 3.3**

- [-] 3. Auto-load on section switch + "generate first" guard
  - Add `sectionAutoLoad` map in `switchSection()`
  - Add `requiresTimetable` list
  - Inject "no timetable" banner for sections needing timetable
  - Wire: analytics, recommendations, heatmap, search-stats, learning, constraint-graph, complexity, versions
  - _Requirements: 5.1, 6.1, 7.1, 9.1_

- [ ] 3.1 Write property test for section auto-load
  - **Property 3: Section switch auto-loads data**
  - **Validates: Requirements 5.1, 6.1, 7.1, 9.1**

- [x] 4. Analytics — render all 4 cards
  - Write `loadAnalytics()` calling GET /api/analytics
  - `renderTeacherWorkload()` — CSS bar chart per teacher
  - `renderRoomUtilization()` — percentage bars per room
  - `renderScheduleDensity()` — sessions/day table
  - `renderConstraintSatisfaction()` — score badge + breakdown
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [x] 5. Scenarios — populate dropdowns from resourceData
  - On switch to scenarios section, populate teacher select from `resourceData.teachers`
  - Populate room select from `resourceData.rooms`
  - Add "no timetable" guard in `simulateScenario()`
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [x] 6. Checkpoint — ensure generate, export, analytics, scenarios all work
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Wire remaining sections with auto-load
  - Recommendations: auto-load on section switch
  - Heatmap: auto-load teacher heatmap on section switch
  - AI Search: auto-load search stats on section switch
  - Learning: auto-load learning stats on section switch
  - Constraint Graph: auto-load on section switch
  - Complexity: auto-load on section switch
  - Versions: auto-load version list on section switch
  - _Requirements: 6.1, 7.1, 9.1, 9.5, 9.6_

- [x] 8. Multi Solutions, GA, Drag & Edit, NL Query, What-If, Pattern Discovery
  - Multi Solutions: ensure generate-multiple button works, cards render
  - GA: ensure optimize button works, results render
  - Drag & Edit: ensure timetable renders in drag section, apply-move works
  - NL Query: ensure submit button calls POST /api/nl_query, renders response
  - What-If: ensure analyze button calls POST /api/analyze_scenarios
  - Pattern Discovery: ensure discover button calls POST /api/discover_patterns
  - _Requirements: 9.2, 9.3, 9.4, 9.6_

- [x] 9. Final checkpoint — all sections functional
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- All DOM lookups must be null-safe (`const el = document.getElementById(id); if (el) ...`)
- Property 4 (generate always submits before generating) is already implemented
