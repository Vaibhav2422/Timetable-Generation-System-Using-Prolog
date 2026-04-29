# Implementation Plan: Bug Fixes

## Overview

Fix all bugs preventing the AI Timetable Generation System from working. Tasks are ordered so each fix is independently verifiable.

## Tasks

- [x] 1. Fix CORS on handle_predict_conflicts backend handler
  - In `backend/api_server.pl`, replace `cors_headers` with `cors_enable(Request, [methods([post, options])])` in all three clauses of `handle_predict_conflicts`
  - Replace all `reply_json_dict(...)` calls with `reply_json_with_cors(...)` in the POST clause
  - Fix the OPTIONS clause to call `format('~n')` instead of returning JSON
  - Fix the fallback clause to use `reply_json_with_cors`
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 4.1, 4.2, 4.3, 5.1, 5.2_

- [x] 2. Fix checkConflicts() in frontend
  - In `frontend/script.js`, add resource guard at top of `checkConflicts()`: if `!_resourcesSubmittedToBackend` show notification and return
  - Add `body: JSON.stringify({})` to the fetch call
  - _Requirements: 3.1, 3.2, 3.3, 6.1, 6.2_

- [x] 3. Verify generateTimetable flow works end-to-end
  - Find the generate button handler in `frontend/script.js`
  - Confirm it POSTs to `/api/generate`, calls `renderTimetable(result.timetable)`, switches to visualize section, and updates reliability display
  - If any of those steps are missing, add them
  - _Requirements: 2.3, 2.4, 2.5, 8.1, 8.2, 8.3, 8.4_

- [x] 4. Checkpoint — restart backend and verify fixes
  - Stop and restart the SWI-Prolog backend process
  - Test POST to `http://localhost:8081/api/predict_conflicts` returns 200 with CORS headers
  - Test OPTIONS to `http://localhost:8081/api/predict_conflicts` returns 200 with CORS headers
  - Open `http://localhost:3000/frontend/index.html` in browser
  - Click "Load Example Dataset", click "Submit All Resources", click "Check for Conflicts" — verify risk report appears
  - Click "Generate Timetable" — verify timetable grid appears
  - Ensure all tests pass, ask the user if questions arise.
