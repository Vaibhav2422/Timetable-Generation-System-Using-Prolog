# Requirements Document: AI-Based Timetable Generation System

## Introduction

This document specifies requirements for an AI-Based Timetable Generation System that automatically creates valid college timetables using Constraint Satisfaction Problems (CSP), First Order Logic reasoning in Prolog, matrix-based representations, and probabilistic reliability estimation. The system demonstrates mathematical foundations of AI including Linear Algebra, Propositional and First Order Logic, Logical Inference, CSP solving, and Probabilistic Reasoning. The system manages teachers, subjects, rooms, time slots, and classes through a web interface backed by a SWI-Prolog reasoning engine.

## Glossary

- **Timetable_Generator**: The core Prolog-based engine that produces valid timetables
- **CSP_Solver**: The constraint satisfaction problem solver using backtracking search
- **Knowledge_Base**: The Prolog facts and rules database containing scheduling logic
- **Matrix_Model**: The list-of-lists data structure representing the timetable grid
- **Probability_Module**: The component calculating schedule reliability scores
- **Web_Interface**: The HTML/CSS/JavaScript frontend for user interaction
- **API_Server**: The SWI-Prolog HTTP server exposing REST endpoints
- **Hard_Constraint**: A constraint that must never be violated for a valid timetable
- **Soft_Constraint**: A preference constraint that should be optimized when possible
- **Class_Session**: A scheduled instance of a subject for a specific class
- **Time_Slot**: A specific period in the weekly schedule (e.g., Monday 9:00-10:00)
- **Teacher_Assignment**: The allocation of a teacher to a class session
- **Room_Assignment**: The allocation of a room to a class session
- **Conflict**: A situation where a resource is double-booked or a constraint is violated
- **Reliability_Score**: A probability value indicating schedule robustness under uncertainty
- **Inference_Engine**: The Prolog backward chaining mechanism for logical reasoning
- **Backtracking_Search**: The CSP algorithm that explores assignment possibilities

## Requirements

### Requirement 1: Resource Data Management

**User Story:** As a timetable administrator, I want to input and manage all scheduling resources, so that the system has complete data for timetable generation.

#### Acceptance Criteria

1. THE Web_Interface SHALL provide forms for entering teacher information including name, qualified subjects, maximum weekly load, availability windows, and preferences
2. THE Web_Interface SHALL provide forms for entering subject information including name, weekly hours required, type (theory or lab), and session duration
3. THE Web_Interface SHALL provide forms for entering room information including name, capacity, and type (classroom or lab)
4. THE Web_Interface SHALL provide forms for configuring time slot structure including days, periods, start times, and durations
5. THE Web_Interface SHALL provide forms for defining class-subject mappings
6. WHEN resource data is submitted, THE API_Server SHALL validate the data format and store it in the Knowledge_Base
7. WHEN invalid data is submitted, THE API_Server SHALL return descriptive error messages with field-specific validation failures

### Requirement 2: Matrix-Based Timetable Representation

**User Story:** As a system designer, I want the timetable represented as a matrix structure, so that Linear Algebra concepts are demonstrated and efficient access patterns are enabled.

#### Acceptance Criteria

1. THE Matrix_Model SHALL represent the timetable as a list of lists structure where each element corresponds to a room-timeslot combination
2. THE Matrix_Model SHALL provide predicates for creating empty timetable matrices with dimensions matching available rooms and time slots
3. THE Matrix_Model SHALL provide predicates for accessing timetable cells by room index and time slot index
4. THE Matrix_Model SHALL provide predicates for updating timetable cells with class assignments
5. THE Matrix_Model SHALL provide predicates for scanning rows to detect room conflicts
6. THE Matrix_Model SHALL provide predicates for scanning columns to detect time slot conflicts
7. FOR ALL valid timetable matrices, accessing a cell and updating it SHALL preserve matrix dimensions and structure

### Requirement 3: First Order Logic Knowledge Base

**User Story:** As an AI system, I want scheduling rules expressed in First Order Logic, so that logical inference can determine valid assignments.

#### Acceptance Criteria

1. THE Knowledge_Base SHALL define facts for teachers including teacher(ID, Name, Subjects, MaxLoad, Availability)
2. THE Knowledge_Base SHALL define facts for subjects including subject(ID, Name, WeeklyHours, Type, Duration)
3. THE Knowledge_Base SHALL define facts for rooms including room(ID, Name, Capacity, Type)
4. THE Knowledge_Base SHALL define facts for time slots including timeslot(ID, Day, Period, StartTime, Duration)
5. THE Knowledge_Base SHALL define facts for classes including class(ID, Name, SubjectList)
6. THE Knowledge_Base SHALL define rules for determining if a teacher is qualified for a subject
7. THE Knowledge_Base SHALL define rules for determining if a room is suitable for a session type
8. THE Knowledge_Base SHALL define rules for detecting teacher scheduling conflicts
9. THE Knowledge_Base SHALL define rules for detecting room scheduling conflicts
10. WHEN a query is made, THE Inference_Engine SHALL use backward chaining to derive answers from facts and rules

### Requirement 4: Hard Constraint Enforcement

**User Story:** As a timetable administrator, I want the system to enforce mandatory constraints, so that generated timetables are always valid and conflict-free.

#### Acceptance Criteria

1. THE CSP_Solver SHALL enforce that no teacher is assigned to multiple class sessions in the same time slot
2. THE CSP_Solver SHALL enforce that no room is assigned to multiple class sessions in the same time slot
3. THE CSP_Solver SHALL enforce that each subject receives exactly its required weekly hours for each class
4. THE CSP_Solver SHALL enforce that lab sessions are scheduled in consecutive time slots when duration exceeds one period
5. THE CSP_Solver SHALL enforce that theory sessions are scheduled in classroom-type rooms
6. THE CSP_Solver SHALL enforce that lab sessions are scheduled in lab-type rooms
7. THE CSP_Solver SHALL enforce that teachers are only assigned to subjects they are qualified to teach
8. THE CSP_Solver SHALL enforce that room capacity meets or exceeds class size requirements
9. THE CSP_Solver SHALL enforce that teachers are only scheduled during their available time windows
10. WHEN any Hard_Constraint is violated during generation, THE CSP_Solver SHALL backtrack and try alternative assignments

### Requirement 5: Soft Constraint Optimization

**User Story:** As a timetable administrator, I want the system to optimize preferences when possible, so that the timetable is not just valid but also desirable.

#### Acceptance Criteria

1. THE CSP_Solver SHALL attempt to balance teacher workload evenly across the week
2. THE CSP_Solver SHALL attempt to minimize scheduling of theory classes in late afternoon or evening slots
3. THE CSP_Solver SHALL attempt to avoid scheduling back-to-back lab sessions for the same teacher
4. THE CSP_Solver SHALL attempt to honor teacher time slot preferences when specified
5. THE CSP_Solver SHALL attempt to minimize gaps in student class schedules
6. WHEN multiple valid timetables exist, THE CSP_Solver SHALL select the one with the highest soft constraint satisfaction score

### Requirement 6: Constraint Satisfaction Problem Solving

**User Story:** As an AI system, I want to use CSP techniques with backtracking, so that I can systematically explore the search space and find valid timetables.

#### Acceptance Criteria

1. THE CSP_Solver SHALL define variables as class sessions requiring teacher, room, and time slot assignments
2. THE CSP_Solver SHALL define domains as the set of possible values for each variable
3. THE CSP_Solver SHALL implement backtracking search that assigns values to variables sequentially
4. WHEN an assignment violates a Hard_Constraint, THE CSP_Solver SHALL immediately backtrack without exploring further
5. THE CSP_Solver SHALL use forward checking to prune domain values that would violate constraints
6. THE CSP_Solver SHALL use heuristics to order variable selection (most constrained first)
7. THE CSP_Solver SHALL use heuristics to order value selection (least constraining first)
8. WHEN no valid assignment exists, THE CSP_Solver SHALL report that the problem is unsatisfiable with explanation of conflicting constraints

### Requirement 7: Timetable Generation

**User Story:** As a timetable administrator, I want to generate a complete timetable with one action, so that I can quickly produce schedules without manual effort.

#### Acceptance Criteria

1. THE Timetable_Generator SHALL provide a main predicate generate_timetable(Timetable) that produces a complete valid timetable
2. WHEN generate_timetable is invoked, THE Timetable_Generator SHALL retrieve all resource data from the Knowledge_Base
3. WHEN generate_timetable is invoked, THE Timetable_Generator SHALL initialize an empty Matrix_Model
4. WHEN generate_timetable is invoked, THE Timetable_Generator SHALL invoke the CSP_Solver to assign all class sessions
5. WHEN generate_timetable is invoked, THE Timetable_Generator SHALL validate that all Hard_Constraints are satisfied
6. WHEN generate_timetable succeeds, THE Timetable_Generator SHALL return a complete timetable structure
7. WHEN generate_timetable fails, THE Timetable_Generator SHALL return an error with explanation of why no valid timetable exists

### Requirement 8: Probabilistic Reliability Estimation

**User Story:** As a timetable administrator, I want to know how reliable a generated timetable is under uncertainty, so that I can assess schedule robustness.

#### Acceptance Criteria

1. THE Probability_Module SHALL model teacher availability uncertainty with probability values
2. THE Probability_Module SHALL model room maintenance failure probability
3. THE Probability_Module SHALL model class cancellation probability
4. THE Probability_Module SHALL provide a predicate schedule_reliability(Timetable, Probability) that calculates overall reliability
5. WHEN calculating reliability, THE Probability_Module SHALL use conditional probability rules to combine individual event probabilities
6. WHEN calculating reliability, THE Probability_Module SHALL consider dependencies between events (e.g., teacher unavailability affects multiple sessions)
7. THE Probability_Module SHALL return a reliability score between 0.0 and 1.0 where 1.0 indicates maximum reliability

### Requirement 9: Conflict Detection and Explanation

**User Story:** As a timetable administrator, I want to understand why specific assignments were made, so that I can verify the system's reasoning and debug issues.

#### Acceptance Criteria

1. THE Timetable_Generator SHALL provide a predicate explain_assignment(ClassSession, Explanation) that returns reasoning for why a session was scheduled
2. WHEN explain_assignment is invoked, THE Timetable_Generator SHALL trace the logical inference steps that led to the assignment
3. WHEN explain_assignment is invoked, THE Timetable_Generator SHALL list all constraints that were satisfied by the assignment
4. THE Timetable_Generator SHALL provide a predicate detect_conflicts(Timetable, ConflictList) that identifies all constraint violations
5. WHEN conflicts exist, THE Timetable_Generator SHALL return detailed descriptions including conflicting resources and time slots
6. THE Web_Interface SHALL display conflict explanations in human-readable format with highlighting of problematic assignments

### Requirement 10: Timetable Parsing and Formatting

**User Story:** As a system integrator, I want to parse timetable data structures and format them for display, so that data can flow between system components reliably.

#### Acceptance Criteria

1. THE Timetable_Generator SHALL provide a predicate parse_timetable(TimetableData, TimetableStructure) that converts external data into internal representation
2. WHEN parsing timetable data, THE Timetable_Generator SHALL validate that all referenced resources exist in the Knowledge_Base
3. WHEN parsing invalid timetable data, THE Timetable_Generator SHALL return descriptive error messages
4. THE Timetable_Generator SHALL provide a predicate format_timetable(TimetableStructure, FormattedOutput) that converts internal representation to display format
5. THE Timetable_Generator SHALL format timetables as JSON structures for API responses
6. THE Timetable_Generator SHALL format timetables as human-readable text for console output
7. FOR ALL valid TimetableStructure values, parsing the formatted output SHALL produce an equivalent structure (round-trip property)

### Requirement 11: Web API Endpoints

**User Story:** As a frontend developer, I want REST API endpoints for all system operations, so that the web interface can communicate with the Prolog backend.

#### Acceptance Criteria

1. THE API_Server SHALL expose a POST endpoint /api/resources for submitting resource data
2. THE API_Server SHALL expose a POST endpoint /api/generate for triggering timetable generation
3. THE API_Server SHALL expose a GET endpoint /api/timetable for retrieving the current timetable
4. THE API_Server SHALL expose a GET endpoint /api/reliability for retrieving the reliability score
5. THE API_Server SHALL expose a POST endpoint /api/explain for requesting assignment explanations
6. THE API_Server SHALL expose a GET endpoint /api/conflicts for retrieving constraint violations
7. WHEN an API request is received, THE API_Server SHALL parse JSON request bodies
8. WHEN an API request is processed, THE API_Server SHALL return JSON responses with appropriate HTTP status codes
9. WHEN an API request fails, THE API_Server SHALL return error responses with descriptive messages and 4xx or 5xx status codes
10. THE API_Server SHALL handle CORS headers to allow cross-origin requests from the frontend

### Requirement 12: Web User Interface

**User Story:** As a timetable administrator, I want an intuitive web interface, so that I can interact with the system without learning Prolog syntax.

#### Acceptance Criteria

1. THE Web_Interface SHALL display a navigation menu with sections for Resources, Generation, and Visualization
2. THE Web_Interface SHALL display forms for entering teacher, subject, room, time slot, and class data
3. THE Web_Interface SHALL display a button to trigger timetable generation
4. WHEN the generate button is clicked, THE Web_Interface SHALL send a request to the API_Server and display a loading indicator
5. WHEN timetable generation succeeds, THE Web_Interface SHALL display the timetable in a grid layout with rows for time slots and columns for rooms
6. WHEN timetable generation succeeds, THE Web_Interface SHALL display the reliability score prominently
7. WHEN timetable generation fails, THE Web_Interface SHALL display error messages with constraint violation details
8. THE Web_Interface SHALL allow clicking on timetable cells to view assignment explanations
9. THE Web_Interface SHALL highlight conflicting assignments in red when conflicts are detected
10. THE Web_Interface SHALL provide export functionality to download timetables as PDF or CSV files

### Requirement 13: System Initialization and Configuration

**User Story:** As a system administrator, I want to easily start the system and configure it, so that deployment is straightforward.

#### Acceptance Criteria

1. THE API_Server SHALL provide a main.pl entry point that loads all required modules
2. WHEN main.pl is executed with swipl, THE API_Server SHALL initialize the Knowledge_Base
3. WHEN main.pl is executed with swipl, THE API_Server SHALL start the HTTP server on a configurable port (default 8080)
4. WHEN the HTTP server starts, THE API_Server SHALL log the server URL to the console
5. THE API_Server SHALL load configuration from a config.pl file if present
6. THE API_Server SHALL use default configuration values when config.pl is not present
7. WHEN the system starts, THE API_Server SHALL validate that all required Prolog libraries are available
8. WHEN required libraries are missing, THE API_Server SHALL display installation instructions and exit gracefully

### Requirement 14: Example Dataset and Documentation

**User Story:** As a new user, I want example data and clear documentation, so that I can quickly understand and test the system.

#### Acceptance Criteria

1. THE system SHALL include a dataset.pl file with sample teachers, subjects, rooms, time slots, and classes
2. THE dataset.pl file SHALL contain at least 5 teachers, 8 subjects, 6 rooms, 30 time slots, and 3 classes
3. THE system SHALL include a README.md file with installation instructions
4. THE README.md file SHALL include step-by-step instructions to run the system using swipl main.pl
5. THE README.md file SHALL include instructions to access the web interface at http://localhost:8080
6. THE system SHALL include architecture documentation explaining the module structure
7. THE system SHALL include code comments explaining key predicates and algorithms
8. THE system SHALL include example output showing a generated timetable

### Requirement 15: Performance and Scalability

**User Story:** As a timetable administrator, I want the system to generate timetables in reasonable time, so that I can use it for real-world scheduling scenarios.

#### Acceptance Criteria

1. WHEN generating a timetable for 3 classes with 8 subjects each, THE Timetable_Generator SHALL complete within 30 seconds
2. WHEN generating a timetable for 5 classes with 10 subjects each, THE Timetable_Generator SHALL complete within 2 minutes
3. WHEN the CSP_Solver explores more than 10000 nodes without finding a solution, THE CSP_Solver SHALL terminate and report that the problem may be over-constrained
4. THE CSP_Solver SHALL log progress information every 1000 search nodes to indicate the system is working
5. THE API_Server SHALL handle concurrent requests from multiple users without data corruption
6. THE API_Server SHALL limit request processing time to 5 minutes maximum to prevent resource exhaustion

### Requirement 16: Error Handling and Robustness

**User Story:** As a system user, I want the system to handle errors gracefully, so that I receive helpful feedback when things go wrong.

#### Acceptance Criteria

1. WHEN a Prolog predicate fails unexpectedly, THE system SHALL catch the exception and log detailed error information
2. WHEN a Prolog predicate fails unexpectedly, THE system SHALL return a user-friendly error message to the API caller
3. WHEN the Knowledge_Base contains inconsistent data, THE system SHALL detect the inconsistency during validation
4. WHEN the Knowledge_Base contains inconsistent data, THE system SHALL report which facts or rules are conflicting
5. WHEN the API_Server receives malformed JSON, THE API_Server SHALL return a 400 Bad Request response with parsing error details
6. WHEN a required resource is missing during generation, THE Timetable_Generator SHALL report which resource is missing and why it is needed
7. THE system SHALL never crash or hang indefinitely regardless of input data

### Requirement 17: MFAI Concept Demonstration

**User Story:** As an academic evaluator, I want to verify that all required MFAI concepts are demonstrated, so that the project meets course requirements.

#### Acceptance Criteria

1. THE Matrix_Model SHALL demonstrate Linear Algebra through matrix-based timetable representation with indexing and scanning operations
2. THE Knowledge_Base SHALL demonstrate Propositional Logic through boolean constraint expressions
3. THE Knowledge_Base SHALL demonstrate First Order Logic through predicates with variables and quantifiers
4. THE Inference_Engine SHALL demonstrate Logical Inference through backward chaining query resolution
5. THE CSP_Solver SHALL demonstrate Constraint Satisfaction Problems through variable assignment with constraint checking and backtracking
6. THE Probability_Module SHALL demonstrate Probabilistic Reasoning through reliability calculation using conditional probabilities
7. THE system documentation SHALL explicitly map each module to the MFAI concept it demonstrates


### Requirement 18: Heuristic Optimization Strategy

**User Story:** As an AI system, I want to use heuristic strategies to guide the search process, so that timetable generation becomes faster and more efficient.

#### Acceptance Criteria

1. THE CSP_Solver SHALL implement the Minimum Remaining Values (MRV) heuristic for variable selection
2. THE CSP_Solver SHALL implement the Degree Heuristic to break ties between variables
3. THE CSP_Solver SHALL implement the Least Constraining Value (LCV) heuristic for domain value ordering
4. WHEN multiple variable assignments are possible, THE CSP_Solver SHALL select the variable that restricts future choices the least
5. THE CSP_Solver SHALL record heuristic decisions in logs for debugging and analysis

### Requirement 19: Forward Checking and Constraint Propagation

**User Story:** As an AI system, I want to prune invalid assignments early, so that the search space is reduced and timetable generation becomes more efficient.

#### Acceptance Criteria

1. THE CSP_Solver SHALL implement Forward Checking after each variable assignment
2. WHEN a variable is assigned a value, THE CSP_Solver SHALL remove conflicting values from neighboring domains
3. IF any domain becomes empty, THE CSP_Solver SHALL immediately trigger backtracking
4. THE CSP_Solver SHALL maintain domain consistency during search
5. THE system SHALL log domain reductions for debugging purposes

### Requirement 20: Timetable Regeneration and Repair

**User Story:** As a timetable administrator, I want the ability to regenerate or repair parts of a timetable, so that small conflicts can be resolved without rebuilding the entire schedule.

#### Acceptance Criteria

1. THE Timetable_Generator SHALL provide a predicate repair_timetable/3 that modifies a timetable to resolve conflicts
2. WHEN a user requests regeneration, THE system SHALL preserve valid assignments where possible
3. WHEN repairing a timetable, THE system SHALL attempt minimal changes to existing assignments
4. THE Web_Interface SHALL provide a Regenerate Timetable button
5. WHEN regeneration is requested, THE system SHALL display a comparison between the previous and new timetable

### Requirement 21: Visualization Enhancements

**User Story:** As a timetable administrator, I want visual indicators of scheduling quality, so that I can easily evaluate the generated timetable.

#### Acceptance Criteria

1. THE Web_Interface SHALL display color-coded timetable cells based on subject type or class
2. THE Web_Interface SHALL highlight teacher conflicts in red
3. THE Web_Interface SHALL highlight room utilization levels
4. THE Web_Interface SHALL display a soft constraint satisfaction score
5. THE Web_Interface SHALL provide tooltips explaining assignments when hovering over timetable cells

### Requirement 22: Resource Utilization Analytics

**User Story:** As a timetable administrator, I want statistics about how resources are used, so that I can evaluate efficiency.

#### Acceptance Criteria

1. THE system SHALL calculate teacher workload statistics
2. THE system SHALL calculate room utilization percentages
3. THE system SHALL calculate average student schedule density
4. THE Web_Interface SHALL display these statistics in charts or tables
5. THE system SHALL export analytics data in JSON format

### Requirement 23: Logging and Debugging Support

**User Story:** As a system developer, I want detailed logs of the timetable generation process, so that I can debug constraint issues.

#### Acceptance Criteria

1. THE system SHALL log every variable assignment during CSP solving
2. THE system SHALL log each backtracking event
3. THE system SHALL log constraint violations encountered during search
4. THE system SHALL provide log levels (INFO, WARNING, ERROR)
5. THE system SHALL allow enabling or disabling logging through configuration

### Requirement 24: Security and Input Validation

**User Story:** As a system administrator, I want the API to validate and sanitize user input, so that the system is protected from malformed or malicious requests.

#### Acceptance Criteria

1. THE API_Server SHALL validate all JSON input fields before processing
2. THE API_Server SHALL reject requests containing invalid resource identifiers
3. THE API_Server SHALL sanitize text fields to prevent injection attacks
4. THE API_Server SHALL limit request payload sizes
5. THE API_Server SHALL log suspicious requests

### Requirement 25: Export and Reporting

**User Story:** As a timetable administrator, I want to export generated timetables in different formats, so that they can be distributed easily.

#### Acceptance Criteria

1. THE system SHALL allow exporting timetables as PDF files
2. THE system SHALL allow exporting timetables as CSV files
3. THE system SHALL allow exporting timetables as JSON files
4. THE exported files SHALL include teacher names, subject names, room numbers, and time slots
5. THE Web_Interface SHALL provide download buttons for each format

### Requirement 26: Testing Framework

**User Story:** As a developer, I want automated tests for key system components, so that I can verify correctness.

#### Acceptance Criteria

1. THE system SHALL include unit tests for Knowledge_Base predicates
2. THE system SHALL include unit tests for CSP constraint validation
3. THE system SHALL include tests for timetable generation correctness
4. THE tests SHALL verify that no hard constraints are violated
5. THE tests SHALL be executable through a single command in SWI-Prolog

### Requirement 27: System Extensibility

**User Story:** As a system developer, I want the architecture to support future extensions, so that additional AI algorithms can be integrated later.

#### Acceptance Criteria

1. THE system SHALL separate CSP logic from data storage modules
2. THE system SHALL allow new constraint types to be added without modifying existing rules
3. THE system SHALL allow new optimization strategies to be added as separate modules
4. THE system SHALL support adding new resource types (e.g., equipment, labs, assistants)
5. THE documentation SHALL describe how to extend the system with new features
