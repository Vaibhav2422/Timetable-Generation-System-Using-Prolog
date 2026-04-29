# Requirements Document: Frontend Bug Fixes

## Introduction

The AI-Based Timetable Generation System has a working Prolog backend but the frontend has several bugs preventing normal use. This spec covers fixing those issues so the web interface works correctly end-to-end. The bugs were identified through live testing of the running system.

## Glossary

- **Web_Interface**: The HTML/CSS/JavaScript frontend served at http://localhost:8081
- **API_Server**: The SWI-Prolog HTTP backend serving REST endpoints
- **Resource_Panel**: The "Resources Added" summary panel showing counts and names of added resources
- **Nav_Tab**: A navigation button in the header that switches the visible section
- **Section**: A `<section>` element in index.html that becomes visible when its Nav_Tab is clicked
- **resourceData**: The JavaScript in-memory object holding teachers, subjects, rooms, timeslots, and classes before submission
- **API_BASE_URL**: The JavaScript constant `http://localhost:8081/api` used as the base for all fetch calls

## Requirements

### Requirement 1: Resource Panel Updates After Manual Entry

**User Story:** As a timetable administrator, I want to see the resources I have added reflected immediately in the "Resources Added" panel, so that I can confirm my entries before submitting.

#### Acceptance Criteria

1. WHEN a teacher is added via the teacher form, THE Resource_Panel SHALL immediately update the teacher count badge from 0 to the new count
2. WHEN a teacher is added via the teacher form, THE Resource_Panel SHALL display the teacher's name in the preview list
3. WHEN a subject, room, timeslot, or class is added, THE Resource_Panel SHALL immediately update the corresponding count badge
4. WHEN the example dataset is loaded, THE Resource_Panel SHALL display counts of 5 teachers, 8 subjects, 6 rooms, 25 timeslots, and 3 classes
5. WHEN the example dataset is loaded, THE Resource_Panel SHALL display the names of all loaded teachers and subjects in the preview list

### Requirement 2: Navigation Tab Switching

**User Story:** As a timetable administrator, I want to click any navigation tab and see its content, so that I can access all features of the system.

#### Acceptance Criteria

1. WHEN any Nav_Tab is clicked, THE Web_Interface SHALL hide all other sections and show only the target Section
2. THE Web_Interface SHALL correctly switch to the Generate section when its Nav_Tab is clicked
3. THE Web_Interface SHALL correctly switch to the Visualize section when its Nav_Tab is clicked
4. THE Web_Interface SHALL correctly switch to the Analytics section when its Nav_Tab is clicked
5. THE Web_Interface SHALL correctly switch to the GA Optimize section when its Nav_Tab is clicked
6. THE Web_Interface SHALL correctly switch to the Versions section when its Nav_Tab is clicked
7. THE Web_Interface SHALL correctly switch to the NL Query section when its Nav_Tab is clicked
8. THE Web_Interface SHALL correctly switch to the Constraint Graph section when its Nav_Tab is clicked
9. WHEN a Nav_Tab is clicked, THE Web_Interface SHALL mark that button as active and remove active state from all others

### Requirement 3: Consistent API Base URL Usage

**User Story:** As a developer, I want all API calls to use the same base URL constant, so that changing the server port only requires updating one place.

#### Acceptance Criteria

1. THE Web_Interface SHALL define exactly one constant for the API base URL: `API_BASE_URL`
2. ALL fetch calls in script.js SHALL reference `API_BASE_URL` and not any other variable name
3. IF any fetch call references an undefined variable, THE Web_Interface SHALL NOT throw a ReferenceError that crashes the page
4. THE Web_Interface SHALL successfully call the constraint graph endpoint at `${API_BASE_URL}/constraint_graph`
5. THE Web_Interface SHALL successfully call the NL query endpoint at `${API_BASE_URL}/nl_query`
6. THE Web_Interface SHALL successfully call all version management endpoints using `API_BASE_URL`

### Requirement 4: No Duplicate JavaScript Declarations

**User Story:** As a developer, I want the JavaScript file to have no duplicate variable or function declarations, so that the browser does not throw SyntaxErrors that prevent the page from loading.

#### Acceptance Criteria

1. THE script.js file SHALL NOT contain more than one `const nlQueryHistory` declaration
2. THE script.js file SHALL NOT contain duplicate top-level function definitions with the same name that would cause a conflict
3. WHEN the browser loads script.js, THE Web_Interface SHALL NOT throw any SyntaxError or ReferenceError during initial page load
4. WHEN the browser loads script.js, ALL form event listeners SHALL be attached successfully
5. WHEN the browser loads script.js, ALL navigation event listeners SHALL be attached successfully

### Requirement 5: Example Dataset Loading

**User Story:** As a timetable administrator, I want to load an example dataset with one click, so that I can quickly test the system without manually entering all resources.

#### Acceptance Criteria

1. WHEN the "Load Example Dataset" button is clicked, THE Web_Interface SHALL populate resourceData with 5 teachers, 8 subjects, 6 rooms, 25 timeslots, and 3 classes
2. WHEN the example dataset is loaded, THE Web_Interface SHALL display a success notification
3. WHEN the example dataset is loaded, THE Resource_Panel SHALL immediately reflect the loaded counts
4. WHEN "Submit All Resources to Backend" is clicked after loading the example dataset, THE API_Server SHALL accept the data and return a success response
5. WHEN the example dataset is submitted successfully, THE Web_Interface SHALL navigate to the Generate section automatically
