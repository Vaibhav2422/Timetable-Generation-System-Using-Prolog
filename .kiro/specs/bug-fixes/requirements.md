# Requirements Document

## Introduction

This spec covers all known bugs in the AI Timetable Generation System that prevent the application from working correctly. The system consists of a SWI-Prolog backend (port 8081) and a JavaScript frontend served via Python HTTP server (port 3000). The bugs span CORS handling, API response inconsistencies, frontend fetch calls, and timetable generation failures.

## Glossary

- **Backend**: SWI-Prolog HTTP server running on port 8081
- **Frontend**: HTML/CSS/JavaScript app served on port 3000
- **CORS**: Cross-Origin Resource Sharing headers required for browser-to-backend communication
- **predict_conflicts**: POST /api/predict_conflicts endpoint for pre-generation conflict risk analysis
- **reply_json_with_cors**: Backend helper that sets CORS headers and replies with JSON
- **reply_json_dict**: Backend predicate that replies with JSON but does NOT set CORS headers
- **cors_headers**: Backend predicate that calls cors_enable without request context
- **cors_enable(Request, Options)**: Proper CORS predicate that sets headers with method allowlist

---

## Requirements

### Requirement 1: Fix CORS on predict_conflicts endpoint

**User Story:** As a user, I want the "Check for Conflicts" button to work, so that I can see conflict risk before generating a timetable.

#### Acceptance Criteria

1. WHEN the browser sends a POST to `/api/predict_conflicts`, THE Backend SHALL respond with the correct `Access-Control-Allow-Origin` header.
2. WHEN the browser sends an OPTIONS preflight to `/api/predict_conflicts`, THE Backend SHALL respond with status 200 and all required CORS headers.
3. THE `handle_predict_conflicts` handler SHALL use `cors_enable(Request, [methods([post,options])])` instead of the bare `cors_headers` predicate.
4. THE `handle_predict_conflicts` handler SHALL use `reply_json_with_cors` instead of `reply_json_dict` for all responses.

---

### Requirement 2: Fix timetable generation flow

**User Story:** As a user, I want to submit resources and generate a timetable, so that I can see a working schedule.

#### Acceptance Criteria

1. WHEN a user clicks "Load Example Dataset" and then "Submit All Resources", THE Frontend SHALL POST the resource data to `/api/resources` and receive a success response.
2. WHEN resources are successfully submitted, THE Frontend SHALL navigate to the Generate section automatically.
3. WHEN a user clicks "Generate Timetable", THE Frontend SHALL POST to `/api/generate` and display the resulting timetable grid.
4. IF the backend returns an error during generation, THEN THE Frontend SHALL display the error message to the user.
5. WHEN the timetable is generated, THE Frontend SHALL update `currentTimetable` state and render the timetable grid.

---

### Requirement 3: Fix missing request body in checkConflicts fetch call

**User Story:** As a user, I want conflict prediction to send a valid request, so that the backend can process it correctly.

#### Acceptance Criteria

1. WHEN `checkConflicts()` is called, THE Frontend SHALL include `body: JSON.stringify({})` in the fetch call to `/api/predict_conflicts`.
2. WHEN resources have not been submitted to the backend, THE Frontend SHALL show a warning notification instead of calling the API.
3. WHEN the API returns a non-OK response, THE Frontend SHALL display the error message from the response body.

---

### Requirement 4: Fix inconsistent JSON response helpers in backend

**User Story:** As a developer, I want all API responses to include CORS headers, so that the browser never blocks a response.

#### Acceptance Criteria

1. THE Backend SHALL use `reply_json_with_cors` for all successful and error responses in every handler.
2. THE `handle_predict_conflicts` handler SHALL NOT use `reply_json_dict` anywhere.
3. WHEN any handler returns an error response, THE Backend SHALL include CORS headers so the browser can read the error message.

---

### Requirement 5: Fix OPTIONS preflight response for predict_conflicts

**User Story:** As a browser, I want the OPTIONS preflight to return an empty 200 response with CORS headers, so that the actual POST request is allowed.

#### Acceptance Criteria

1. WHEN the browser sends OPTIONS to `/api/predict_conflicts`, THE Backend SHALL call `cors_enable(Request, [methods([post,options])])` and return an empty 200 response.
2. THE OPTIONS handler SHALL NOT return a JSON body — it SHALL call `format('~n')` to send an empty response.

---

### Requirement 6: Validate resources are submitted before conflict check

**User Story:** As a user, I want to see a clear message if I try to check conflicts before submitting resources, so that I understand what to do next.

#### Acceptance Criteria

1. WHEN `checkConflicts()` is called and `_resourcesSubmittedToBackend` is false, THE Frontend SHALL show a notification: "Please submit resources first before checking for conflicts."
2. WHEN `_resourcesSubmittedToBackend` is false, THE Frontend SHALL NOT call the `/api/predict_conflicts` endpoint.

---

### Requirement 7: Ensure frontend is accessed via HTTP server, not file://

**User Story:** As a user, I want the app to work when I open it in a browser, so that all API calls succeed.

#### Acceptance Criteria

1. THE Frontend SHALL be served via `http://localhost:3000/frontend/index.html` and not opened as a `file://` URL.
2. THE `API_BASE_URL` in `script.js` SHALL match the port configured in `config.pl` (currently 8081).
3. IF the port in `config.pl` is changed, THE `API_BASE_URL` in `script.js` SHALL be updated to match.

---

### Requirement 8: Fix timetable not displaying after generation

**User Story:** As a user, I want the timetable grid to appear after clicking Generate, so that I can see the schedule.

#### Acceptance Criteria

1. WHEN the `/api/generate` response contains a `timetable` field, THE Frontend SHALL call `renderTimetable(result.timetable)`.
2. WHEN the timetable is rendered, THE Frontend SHALL switch to the Visualize section automatically.
3. WHEN the timetable is rendered, THE Frontend SHALL update the reliability score display.
4. IF `result.timetable` is null or missing, THE Frontend SHALL show an error notification.
