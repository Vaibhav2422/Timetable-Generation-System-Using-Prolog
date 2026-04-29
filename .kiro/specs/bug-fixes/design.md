# Design Document: Bug Fixes

## Overview

This document describes the design for fixing all known bugs in the AI Timetable Generation System. The fixes are grouped into two areas: backend CORS/response fixes and frontend fetch/flow fixes.

## Architecture

No architectural changes. The system remains:
- SWI-Prolog backend on port 8081 (`backend/api_server.pl`)
- JavaScript frontend served on port 3000 (`frontend/script.js`)

## Components and Interfaces

### Backend: handle_predict_conflicts

**Current (broken):**
```prolog
handle_predict_conflicts(Request) :-
    cors_headers,                          % BUG: no request context, no method list
    member(method(post), Request),
    ...
    reply_json_dict(_{...})               % BUG: no CORS headers on response
```

**Fixed:**
```prolog
handle_predict_conflicts(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(post), Request),
    ...
    reply_json_with_cors(_{...})          % CORS headers included
```

The OPTIONS handler must also be fixed:
```prolog
handle_predict_conflicts(Request) :-
    cors_enable(Request, [methods([post, options])]),
    member(method(options), Request),
    !,
    format('~n').                         % empty 200, not JSON
```

### Frontend: checkConflicts()

**Current (broken):**
```javascript
const response = await fetch(`${API_BASE_URL}/predict_conflicts`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
    // BUG: no body
});
```

**Fixed:**
```javascript
// Guard: resources must be submitted first
if (!_resourcesSubmittedToBackend) {
    showNotification('error', 'Please submit resources first before checking for conflicts.');
    return;
}
const response = await fetch(`${API_BASE_URL}/predict_conflicts`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({})              // required for POST
});
```

### Frontend: generateTimetable flow

The generate function must:
1. POST to `/api/generate`
2. On success: store `currentTimetable`, call `renderTimetable()`, switch to visualize section, update reliability display
3. On error: show notification with error message

## Data Models

No data model changes. All existing API contracts remain the same.

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system.*

Property 1: CORS headers always present
*For any* API endpoint, every response (success or error) SHALL include `Access-Control-Allow-Origin: *`.
**Validates: Requirements 1.1, 4.1, 4.3**

Property 2: predict_conflicts always responds
*For any* POST to `/api/predict_conflicts` (with or without a body), the backend SHALL return a 200 JSON response with `status: success`.
**Validates: Requirements 1.1, 3.1**

Property 3: Resource guard prevents empty calls
*For any* call to `checkConflicts()` where `_resourcesSubmittedToBackend` is false, the fetch SHALL NOT be called.
**Validates: Requirements 6.1, 6.2**

## Error Handling

- All backend handlers use `reply_json_with_cors` — this ensures CORS headers are present even on error responses, so the browser can read the error message
- Frontend wraps all fetch calls in try/catch and calls `showNotification('error', ...)` on failure

## Testing Strategy

Unit tests:
- Test that `handle_predict_conflicts` returns 200 with CORS headers for POST
- Test that `handle_predict_conflicts` returns 200 for OPTIONS preflight
- Test that `checkConflicts()` shows notification when resources not submitted
- Test that `checkConflicts()` includes body in fetch call

Integration tests:
- Load example dataset → submit resources → check conflicts → verify risk report renders
- Load example dataset → submit resources → generate timetable → verify grid renders
