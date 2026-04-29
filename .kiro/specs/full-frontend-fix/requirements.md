# Requirements Document

## Introduction

The AI-Based Timetable Generation System frontend has multiple sections that are either broken, non-functional, or incomplete. This spec covers fixing and completing all major frontend features so the system works end-to-end: from resource submission through timetable generation, visualization, export, scenario management, analytics, and all advanced features.

## Glossary

- **System**: The AI Timetable Generation frontend + Prolog backend
- **Resource_Data**: The in-browser object holding teachers, subjects, rooms, timeslots, classes
- **Backend**: The SWI-Prolog HTTP server running on localhost:8081
- **Timetable**: The generated weekly schedule returned by POST /api/generate
- **Bottleneck**: A resource shortage detected by POST /api/predict_conflicts
- **Fix_Rooms**: A predefined set of extra classrooms added automatically when room shortages are detected: 1002, 1003, 1102, 1103, 1124, 1125

## Requirements

### Requirement 1: Fix Issues First — Auto-Resolution

**User Story:** As a user, I want clicking "Fix Issues First" to automatically resolve all detected bottlenecks so I can generate a timetable without manual intervention.

#### Acceptance Criteria

1. WHEN the user clicks "Fix Issues First", THE System SHALL parse all bottleneck items currently displayed in the risk report
2. WHEN a room shortage (theory) is detected, THE System SHALL automatically add Fix_Rooms classrooms (1002, 1003, 1102, 1103, 1124, 1125, capacity 72) to Resource_Data
3. WHEN a room shortage (lab) is detected, THE System SHALL automatically add lab rooms (L001, L002, L003, capacity 30) to Resource_Data
4. WHEN a timeslot shortage is detected, THE System SHALL automatically extend timeslots to cover the full day (08:00–18:00, 9 periods × 5 days = 45 slots)
5. WHEN a teacher overload is detected, THE System SHALL increase the affected teacher's maxload to accommodate the demand
6. AFTER applying all fixes, THE System SHALL re-submit Resource_Data to the backend via POST /api/resources
7. AFTER re-submission, THE System SHALL automatically re-run conflict check and display updated results
8. IF no bottlenecks remain after fixes, THE System SHALL display a success message "All issues resolved — ready to generate"

### Requirement 2: Generate Timetable

**User Story:** As a user, I want clicking "Generate Timetable" or "Generate Anyway" to always produce a timetable and navigate to the visualization.

#### Acceptance Criteria

1. WHEN the user clicks "Generate Timetable" or "Generate Anyway", THE System SHALL auto-submit Resource_Data to the backend if not already submitted
2. WHEN Resource_Data is empty, THE System SHALL display an error "No resources loaded. Please load the example dataset first."
3. WHEN POST /api/generate returns success, THE System SHALL navigate to the Visualize section and render the timetable grid
4. WHEN POST /api/generate returns an error, THE System SHALL display the error message clearly
5. WHILE generation is in progress, THE System SHALL show a loading spinner and disable the generate buttons
6. WHEN the timetable is rendered, THE System SHALL display day columns (Mon–Fri), period rows (P1–P9), and assignment cells showing class, subject, teacher

### Requirement 3: Visualize — Export

**User Story:** As a user, I want to export the generated timetable in PDF, CSV, and JSON formats.

#### Acceptance Criteria

1. WHEN a timetable has been generated, THE System SHALL enable the Export as PDF, Export as CSV, and Export as JSON buttons
2. WHEN the user clicks "Export as PDF", THE System SHALL generate a printable PDF of the timetable grid and trigger a browser download
3. WHEN the user clicks "Export as CSV", THE System SHALL generate a CSV file with columns: Day, Period, Room, Class, Subject, Teacher and trigger a download
4. WHEN the user clicks "Export as JSON", THE System SHALL trigger a download of the raw timetable JSON
5. IF no timetable has been generated, THE System SHALL show a notification "Generate a timetable first"

### Requirement 4: Scenarios

**User Story:** As a user, I want to simulate scheduling scenarios like absent teachers, room maintenance, extra classes, and exam weeks.

#### Acceptance Criteria

1. THE System SHALL provide scenario options: Absent Teacher, Room Maintenance, Extra Class, Exam Week
2. WHEN the user selects "Absent Teacher" and picks a teacher, THE System SHALL call POST /api/simulate and display the rescheduled timetable
3. WHEN the user selects "Room Maintenance" and picks a room, THE System SHALL call POST /api/simulate and show affected sessions moved to alternative rooms
4. WHEN the user selects "Extra Class" and specifies class/subject/slot, THE System SHALL add the session and show the updated timetable
5. WHEN the user selects "Exam Week", THE System SHALL clear all regular sessions for the selected week and show an empty exam timetable
6. WHEN a scenario result is displayed, THE System SHALL show a diff of changes (added/removed/moved sessions)

### Requirement 5: Analytics

**User Story:** As a user, I want to see detailed analytics about the generated timetable.

#### Acceptance Criteria

1. WHEN the user navigates to Analytics, THE System SHALL call GET /api/analytics and display results
2. THE System SHALL display Teacher Workload as a bar chart showing sessions per teacher vs max load
3. THE System SHALL display Room Utilization as a percentage of slots used per room
4. THE System SHALL display Schedule Density as sessions per day per division
5. THE System SHALL display Constraint Satisfaction as a score showing hard and soft constraint compliance
6. IF no timetable exists, THE System SHALL show "Generate a timetable first to see analytics"

### Requirement 6: Recommendations

**User Story:** As a user, I want AI-generated recommendations to improve the timetable.

#### Acceptance Criteria

1. WHEN the user navigates to Recommendations, THE System SHALL call GET /api/recommendations
2. THE System SHALL display each recommendation with a description and an "Apply" button
3. WHEN the user clicks "Apply", THE System SHALL call POST /api/apply_recommendation and refresh the timetable

### Requirement 7: Heatmap

**User Story:** As a user, I want to see a heatmap of room and teacher utilization across the week.

#### Acceptance Criteria

1. WHEN the user navigates to Heatmap, THE System SHALL call GET /api/heatmap and render a color-coded grid
2. THE System SHALL support switching between Teacher Heatmap and Room Heatmap views
3. THE heatmap SHALL use green (low load) to red (high load) color coding

### Requirement 8: Multi Solutions

**User Story:** As a user, I want to generate and compare multiple timetable solutions.

#### Acceptance Criteria

1. WHEN the user clicks "Generate Multiple", THE System SHALL call POST /api/generate_multiple with the specified count
2. THE System SHALL display each solution as a card with its reliability score
3. WHEN the user clicks "Select" on a solution, THE System SHALL set it as the current timetable

### Requirement 9: Remaining Sections

**User Story:** As a user, I want all navigation sections to load and display meaningful content.

#### Acceptance Criteria

1. WHEN the user navigates to AI Search, THE System SHALL call GET /api/search_stats and display search statistics
2. WHEN the user navigates to Constraints, THE System SHALL display constraint weight sliders and allow adjustment
3. WHEN the user navigates to GA Optimize, THE System SHALL allow running genetic algorithm optimization
4. WHEN the user navigates to Drag & Edit, THE System SHALL display the timetable with draggable cells
5. WHEN the user navigates to Versions, THE System SHALL call GET /api/versions and list saved versions
6. WHEN the user navigates to NL Query, THE System SHALL allow natural language queries about the timetable
7. IF a section requires a generated timetable and none exists, THE System SHALL show a clear "Generate a timetable first" message with a button to navigate to Generate
