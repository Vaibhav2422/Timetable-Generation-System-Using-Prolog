# Implementation Plan: Frontend Bug Fixes

## Overview

Fix five categories of bugs in `frontend/script.js` that prevent the web interface from working. The root cause is a duplicate code block that crashes the script on load. Secondary issues are stale `API_BASE` references (already partially fixed) and the resulting broken resource panel and navigation.

## Tasks

- [x] 1. Remove duplicate NL Query implementation block
  - Delete the second NL query block starting at the `const nlQueryHistory = []` re-declaration (~line 4599) through the duplicate `submitNLQuery`, `initNLQuery`, `renderNLHistory`, `clearNLHistory`, and `escapeHtml` function definitions
  - Keep Implementation A (the first one, ~lines 4480–4590) which uses `let nlQueryHistory`, accepts a `queryText` parameter, and uses `API_BASE_URL` correctly
  - After removal, verify `grep -c "const nlQueryHistory" frontend/script.js` returns `0` (it uses `let`) and `grep -c "function submitNLQuery" frontend/script.js` returns `1`
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 2. Verify and fix all API_BASE_URL references
  - [x] 2.1 Run static check to confirm no remaining `API_BASE` (without `_URL`) references exist in fetch calls
    - Command: `Select-String -Path frontend/script.js -Pattern "\bAPI_BASE\b" | Where-Object { $_.Line -notmatch "API_BASE_URL" }`
    - If any remain, replace them with `API_BASE_URL`
    - _Requirements: 3.1, 3.2_

  - [x] 2.2 Write property test for API_BASE_URL consistency (Property 3)
    - Verify zero matches for `API_BASE[^_U]` pattern in script.js
    - **Property 3: All fetch calls use API_BASE_URL**
    - **Validates: Requirements 3.2**

- [x] 3. Verify resource panel updates correctly
  - [x] 3.1 Confirm `updateResourceCounts()` is called in all five form submit handlers (teacher, subject, room, timeslot, class)
    - Confirm it is also called in `loadExampleDataset()` and `clearAllForms()`
    - _Requirements: 1.1, 1.2, 1.3_

  - [x] 3.2 Write property test for resource badge count (Property 1)
    - After each form submit, assert `badge.textContent === String(resourceData[type].length)`
    - **Property 1: Resource badge count equals array length**
    - **Validates: Requirements 1.1, 1.3**

- [x] 4. Verify navigation tab switching works
  - [x] 4.1 Confirm `switchSection()` correctly adds/removes the `active` class
    - Check that `document.querySelectorAll('.section.active').length === 1` after any nav click
    - Confirm all 19 nav buttons have their `data-section` attribute matching an existing section id
    - _Requirements: 2.1, 2.9_

  - [x] 4.2 Write property test for single active section (Property 2)
    - After calling `switchSection(name)`, assert exactly one `.section.active` exists and its id is `name + '-section'`
    - **Property 2: Exactly one section is active after navigation**
    - **Validates: Requirements 2.1**

- [x] 5. Verify example dataset loading end-to-end
  - [x] 5.1 Confirm `loadExampleDataset()` sets correct array lengths (5/8/6/25/3) and calls `updateResourceCounts()`
    - _Requirements: 1.4, 5.1, 5.3_

  - [x] 5.2 Write property test for example dataset counts (Property 5)
    - Call `loadExampleDataset()` and assert each `resourceData[type].length` matches expected value
    - **Property 5: Example dataset loads correct counts**
    - **Validates: Requirements 1.4, 5.1**

- [x] 6. Final checkpoint — smoke test the running system
  - Restart the server: `& "C:\Program Files\swipl\bin\swipl.exe" main.pl`
  - Open http://localhost:8081 in browser
  - Open DevTools Console — verify zero errors on page load
  - Add one teacher manually — verify badge increments and name appears in preview
  - Click each nav tab — verify correct section shows
  - Click "Load Example Dataset" — verify 5/8/6/25/3 counts
  - Click "Submit All Resources to Backend" — verify success and auto-navigation to Generate
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster fix
- Task 1 is the critical fix — everything else depends on it
- Tasks 2–5 are verification steps to confirm the fixes hold
- No backend changes are needed — all fixes are in `frontend/script.js`
- Property tests here are static analysis + console assertions (no PBT framework needed)
