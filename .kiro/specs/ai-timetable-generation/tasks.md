# Implementation Plan: AI-Based Timetable Generation System

## Overview

This implementation plan provides a systematic approach to building a comprehensive AI-Based Timetable Generation System using SWI-Prolog for the backend and HTML/CSS/JavaScript for the frontend. The system demonstrates Mathematical Foundations of AI (MFAI) concepts including Linear Algebra, First Order Logic, Logical Inference, Constraint Satisfaction Problems, and Probabilistic Reasoning.

The implementation is organized into 7 phases covering core backend modules, API server, frontend, 10 advanced features, comprehensive testing, and documentation.

## Tasks

## Phase 1: Project Setup and Foundation

- [-] 1. Set up project structure and development environment
  - Create directory structure: backend/, frontend/, data/, docs/, tests/
  - Install SWI-Prolog 8.x or higher
  - Verify required Prolog libraries: http, json, lists
  - Create main.pl entry point that loads all modules
  - Create config.pl for configuration settings
  - Set up version control (git) with .gitignore
  - _Requirements: 13.1, 13.2, 13.7_

- [ ] 2. Create example dataset and initial documentation
  - Create data/dataset.pl with sample data (5 teachers, 8 subjects, 6 rooms, 30 time slots, 3 classes)
  - Create docs/README.md with installation instructions
  - Document SWI-Prolog installation steps for different platforms
  - Add instructions for running the system with `swipl main.pl`
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5_

## Phase 2: Core Backend Implementation

- [ ] 3. Implement knowledge_base.pl module
  - [ ] 3.1 Define Prolog facts for resources
    - Implement teacher/5 predicate (ID, Name, QualifiedSubjects, MaxLoad, Availability)
    - Implement subject/5 predicate (ID, Name, WeeklyHours, Type, Duration)
    - Implement room/4 predicate (ID, Name, Capacity, Type)
    - Implement timeslot/5 predicate (ID, Day, Period, StartTime, Duration)
    - Implement class/3 predicate (ID, Name, SubjectList)
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_


  - [ ] 3.2 Define First Order Logic rules
    - Implement qualified/2 rule (teacher qualification check)
    - Implement suitable_room/2 rule (room type compatibility)
    - Implement compatible_type/2 rule (theory→classroom, lab→lab)
    - Implement teacher_available/2 rule (availability check)
    - Implement teacher_conflict/3 rule (detect teacher double-booking)
    - Implement room_conflict/3 rule (detect room double-booking)
    - _Requirements: 3.6, 3.7, 3.8, 3.9_

  - [ ] 3.3 Implement query predicates
    - Implement get_all_teachers/1 predicate
    - Implement get_all_subjects/1 predicate
    - Implement get_all_rooms/1 predicate
    - Implement get_all_timeslots/1 predicate
    - Implement get_all_classes/1 predicate
    - _Requirements: 3.10_

- [ ] 4. Implement matrix_model.pl module
  - [ ] 4.1 Create matrix structure operations
    - Implement create_empty_timetable/3 (creates matrix with dimensions)
    - Implement create_matrix/3 helper (recursive matrix creation)
    - Implement create_row/2 helper (creates empty row)
    - Verify matrix dimensions match rooms × time slots
    - _Requirements: 2.1, 2.2, 2.4_

  - [ ] 4.2 Implement matrix access and update operations
    - Implement get_cell/4 (access cell by row and column index)
    - Implement set_cell/5 (update cell value)
    - Implement replace_nth/4 helper (list element replacement)
    - Verify operations preserve matrix structure
    - _Requirements: 2.3, 2.4, 2.7_

  - [ ] 4.3 Implement matrix scanning operations
    - Implement scan_row/3 (get all assignments in a room)
    - Implement scan_column/3 (get all assignments in a time slot)
    - Implement get_all_assignments/2 (flatten matrix to assignment list)
    - Implement is_complete/1 (check if matrix has no empty cells)
    - _Requirements: 2.5, 2.6_

- [ ] 5. Implement constraints.pl module
  - [ ] 5.1 Implement hard constraint checking predicates
    - Implement check_teacher_no_conflict/3 (no teacher double-booking)
    - Implement check_room_no_conflict/3 (no room double-booking)
    - Implement check_teacher_qualified/2 (teacher qualification)
    - Implement check_room_suitable/2 (room type compatibility)
    - Implement check_room_capacity/2 (capacity constraint)
    - Implement check_teacher_available/2 (availability constraint)
    - Implement check_weekly_hours/3 (weekly hours requirement)
    - Implement check_consecutive_slots/2 (consecutive lab sessions)
    - Implement check_all_hard_constraints/6 (combined check)
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9, 4.10_

  - [ ] 5.2 Implement soft constraint scoring predicates
    - Implement soft_balanced_workload/3 (workload balance score)
    - Implement soft_avoid_late_theory/3 (late afternoon penalty)
    - Implement soft_minimize_gaps/3 (schedule compactness)
    - Implement calculate_soft_score/2 (aggregate soft score)
    - Implement helper predicates: group_by_day/2, count_gaps/2
    - _Requirements: 5.1, 5.2, 5.3, 5.5, 5.6_


- [ ] 6. Implement csp_solver.pl module
  - [ ] 6.1 Implement CSP formulation and domain management
    - Implement initialize_domains/2 (create initial domains for all sessions)
    - Implement generate_domain/2 (generate possible assignments for a session)
    - Implement get_domain/3 (retrieve domain for a session)
    - Implement update_domain/4 (update domain after filtering)
    - Implement has_empty_domain/1 (check for empty domains)
    - _Requirements: 6.1, 6.2_

  - [ ] 6.2 Implement backtracking search algorithm
    - Implement solve_csp/3 (main CSP solver entry point)
    - Implement backtracking_search/4 (recursive backtracking)
    - Implement try_values/6 (try each domain value)
    - Implement assign_value/4 (assign value to variable)
    - Implement check_constraints/3 (validate assignment)
    - _Requirements: 6.3, 6.4_

  - [ ] 6.3 Implement forward checking
    - Implement forward_check/5 (prune inconsistent values)
    - Implement forward_check_all/5 (apply to all remaining variables)
    - Implement filter_domain/4 (remove conflicting values)
    - Implement conflicts_with/3 (check if two assignments conflict)
    - _Requirements: 6.5, 19.1, 19.2, 19.3, 19.4_

  - [ ] 6.4 Implement intelligent heuristics
    - Implement select_variable/4 with MRV (Minimum Remaining Values)
    - Implement select_variable_degree/5 with Degree heuristic for tie-breaking
    - Implement order_domain_values/4 with LCV (Least Constraining Value)
    - Implement count_constraints/4 helper
    - Implement count_eliminated_values/4 helper
    - _Requirements: 6.6, 6.7, 18.1, 18.2, 18.3, 18.4_

  - [ ]* 6.5 Write property tests for CSP solver
    - **Property 7: No Teacher Conflicts** - Validates Requirements 4.1
    - **Property 8: No Room Conflicts** - Validates Requirements 4.2
    - **Property 13: Teacher Qualification Constraint** - Validates Requirements 4.7
    - **Property 15: Teacher Availability Constraint** - Validates Requirements 4.9
    - Run 100+ iterations with random data

- [ ] 7. Implement probability_module.pl
  - [ ] 7.1 Implement reliability calculation predicates
    - Implement schedule_reliability/2 (overall reliability score)
    - Implement calculate_assignment_reliabilities/2 (per-assignment scores)
    - Implement assignment_reliability/2 (single assignment probability)
    - Implement combine_probabilities/2 (product rule for independent events)
    - Verify reliability score is between 0.0 and 1.0
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.7_

  - [ ] 7.2 Implement conditional probability predicates
    - Implement conditional_reliability/3 (reliability given teacher unavailable)
    - Implement bayesian_reliability/3 (Bayesian inference)
    - Implement expected_disruptions/2 (expected failure count)
    - Implement risk_category/2 (low/medium/high/critical)
    - _Requirements: 8.6_

  - [ ]* 7.3 Write property tests for probability module
    - **Property 20: Reliability Score Range** - Validates Requirements 8.4, 8.7
    - **Property 21: Reliability Calculation Correctness** - Validates Requirements 8.5
    - **Property 22: Conditional Reliability Dependencies** - Validates Requirements 8.6
    - Run 100+ iterations with various timetables

- [ ] 8. Implement timetable_generator.pl module
  - [ ] 8.1 Implement main generation logic
    - Implement generate_timetable/1 (main entry point)
    - Implement retrieve_resources/5 (get all resources from knowledge base)
    - Implement validate_resources/5 (check resource consistency)
    - Implement create_sessions/3 (create session list from classes)
    - Implement validate_timetable/1 (verify all constraints satisfied)
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_

  - [ ] 8.2 Implement explanation and conflict detection
    - Implement explain_assignment/3 (generate reasoning for assignment)
    - Implement format_explanation/2 (format explanation text)
    - Implement detect_conflicts/2 (find all constraint violations)
    - Implement find_conflict/2 (identify specific conflict types)
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_


  - [ ] 8.3 Implement timetable repair functionality
    - Implement repair_timetable/3 (resolve conflicts with minimal changes)
    - Implement identify_conflicting_assignments/3
    - Implement remove_assignments/3
    - Implement create_repair_sessions/2
    - _Requirements: 20.1, 20.2, 20.3_

  - [ ] 8.4 Implement parsing and formatting
    - Implement parse_timetable/2 (JSON to Prolog structure)
    - Implement format_timetable/3 (Prolog to JSON/text/CSV)
    - Implement json_to_prolog/2 helper
    - Implement matrix_to_json/2 helper
    - Implement matrix_to_text/2 helper
    - Implement matrix_to_csv/2 helper
    - Verify round-trip property (parse → format → parse)
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7_

  - [ ]* 8.5 Write property tests for timetable generator
    - **Property 9: Weekly Hours Requirement** - Validates Requirements 4.3
    - **Property 10: Consecutive Lab Sessions** - Validates Requirements 4.4
    - **Property 11: Theory Room Type Constraint** - Validates Requirements 4.5
    - **Property 12: Lab Room Type Constraint** - Validates Requirements 4.6
    - **Property 14: Room Capacity Constraint** - Validates Requirements 4.8
    - **Property 26: Timetable Format Round-Trip** - Validates Requirements 10.7
    - Run 100+ iterations

- [ ] 9. Implement logging.pl module
  - Implement log level management (set_log_level/1, should_log/1)
  - Implement logging predicates (log_info/1, log_warning/1, log_error/1, log_debug/1)
  - Implement get_timestamp/1 helper
  - Implement log_search_node/1 for CSP progress tracking
  - Add log statements to key operations in other modules
  - _Requirements: 23.1, 23.2, 23.3, 23.4, 23.5_

- [ ] 10. Checkpoint - Core backend modules complete
  - Verify all core modules load without errors
  - Test basic timetable generation with dataset.pl
  - Verify all hard constraints are enforced
  - Check that logging works correctly
  - Ensure all tests pass, ask the user if questions arise

## Phase 3: API Server and Integration

- [ ] 11. Implement api_server.pl module
  - [ ] 11.1 Set up HTTP server infrastructure
    - Import required libraries (http/http_server, http/http_json, http/http_cors)
    - Implement start_server/1 (start HTTP server on port)
    - Implement cors_headers/0 (CORS support)
    - Add server startup logging
    - _Requirements: 11.10, 13.3, 13.4_

  - [ ] 11.2 Implement resource management endpoints
    - Implement handle_resources/1 for POST /api/resources
    - Implement validate_resource_data/2 (input validation)
    - Implement store_resources/1 (save to knowledge base)
    - Implement sanitize_inputs/2 (security)
    - Return appropriate HTTP status codes (200, 400, 500)
    - _Requirements: 11.1, 24.1, 24.2, 24.3_

  - [ ] 11.3 Implement timetable generation endpoints
    - Implement handle_generate/1 for POST /api/generate
    - Implement handle_get_timetable/1 for GET /api/timetable
    - Integrate with timetable_generator.pl
    - Return JSON responses with timetable and reliability
    - Handle generation failures gracefully
    - _Requirements: 11.2, 11.3_

  - [ ] 11.4 Implement analysis endpoints
    - Implement handle_reliability/1 for GET /api/reliability
    - Implement handle_explain/1 for POST /api/explain
    - Implement handle_conflicts/1 for GET /api/conflicts
    - Implement handle_repair/1 for POST /api/repair
    - _Requirements: 11.4, 11.5, 11.6_


  - [ ] 11.5 Implement analytics and export endpoints
    - Implement handle_analytics/1 for GET /api/analytics
    - Implement handle_export/1 for GET /api/export
    - Implement calculate_analytics/2 (teacher workload, room utilization, schedule density)
    - Support PDF, CSV, JSON export formats
    - _Requirements: 22.1, 22.2, 22.3, 22.4, 25.1, 25.2, 25.3, 25.4_

  - [ ] 11.6 Implement error handling and validation
    - Add try-catch blocks for all endpoints
    - Implement format_user_error/2 (user-friendly error messages)
    - Implement safe_execute/2 wrapper
    - Handle malformed JSON with 400 responses
    - Handle missing resources with 404 responses
    - Handle server errors with 500 responses
    - Log all errors with error IDs
    - _Requirements: 11.7, 11.8, 11.9, 16.1, 16.2, 16.5, 16.6, 16.7_

  - [ ]* 11.7 Write property tests for API server
    - **Property 30: API JSON Request Parsing** - Validates Requirements 11.7
    - **Property 31: API JSON Response Format** - Validates Requirements 11.8
    - **Property 32: API Error Response Format** - Validates Requirements 11.9
    - **Property 33: CORS Headers Presence** - Validates Requirements 11.10
    - **Property 37: Malformed JSON Handling** - Validates Requirements 16.5
    - Run 100+ iterations with various inputs

- [ ] 12. Integrate main.pl entry point
  - Load all backend modules in correct order
  - Load configuration from config.pl
  - Load example data from data/dataset.pl
  - Initialize logging system
  - Start HTTP server on configured port (default 8080)
  - Display server URL and status
  - Handle missing libraries gracefully
  - _Requirements: 13.1, 13.2, 13.5, 13.6, 13.7, 13.8_

- [ ] 13. Checkpoint - API server functional
  - Test all API endpoints with curl or Postman
  - Verify JSON request/response handling
  - Test error handling with invalid inputs
  - Verify CORS headers are present
  - Ensure all tests pass, ask the user if questions arise

## Phase 4: Frontend Development

- [ ] 14. Create index.html structure
  - [ ] 14.1 Implement HTML structure
    - Create header with navigation menu (Resources, Generate, Visualize, Analytics)
    - Create resources section with forms (teacher, subject, room, timeslot, class)
    - Create generation section with buttons and loading indicator
    - Create visualization section with timetable grid and reliability display
    - Create analytics section with statistics display
    - Create explanation modal for assignment details
    - _Requirements: 12.1, 12.2, 12.3_

  - [ ] 14.2 Add form input fields
    - Teacher form: name, qualified subjects, max load, availability
    - Subject form: name, weekly hours, type (theory/lab), duration
    - Room form: name, capacity, type (classroom/lab)
    - Timeslot form: day, period, start time, duration
    - Class form: name, subject list
    - Add validation attributes (required, min, max, pattern)
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [ ] 15. Create style.css styling
  - [ ] 15.1 Implement base styles and layout
    - Define CSS variables for color scheme
    - Style header and navigation
    - Style forms and input fields
    - Style buttons (primary, secondary, tertiary)
    - Implement responsive layout with flexbox/grid
    - _Requirements: 12.1_

  - [ ] 15.2 Implement timetable grid styles
    - Create grid layout with CSS Grid
    - Style grid cells (header, empty, assigned)
    - Add color coding for subject types
    - Add hover effects and transitions
    - Implement conflict highlighting (red, pulsing animation)
    - _Requirements: 12.5, 12.9, 21.1, 21.2_


  - [ ] 15.3 Implement visualization components
    - Style reliability display with progress bar
    - Style loading indicator with spinner animation
    - Style modal dialogs
    - Style tooltips for cell hover
    - Add responsive design for mobile devices
    - _Requirements: 12.6, 21.4, 21.5_

- [ ] 16. Create script.js frontend logic
  - [ ] 16.1 Implement navigation and state management
    - Set up API base URL constant
    - Implement navigation button handlers
    - Implement section switching logic
    - Initialize state variables (currentTimetable, currentReliability)
    - _Requirements: 12.1_

  - [ ] 16.2 Implement resource submission
    - Implement submitResources/2 function
    - Add form submit handlers for all resource types
    - Implement input validation before submission
    - Display success/error notifications
    - _Requirements: 1.6, 1.7_

  - [ ] 16.3 Implement timetable generation
    - Implement generate button click handler
    - Show loading indicator during generation
    - Call POST /api/generate endpoint
    - Handle success and error responses
    - Switch to visualization section on success
    - _Requirements: 12.3, 12.4, 12.7_

  - [ ] 16.4 Implement timetable visualization
    - Implement renderTimetable/1 function
    - Create grid with headers (time slots and rooms)
    - Populate cells with assignments
    - Apply color coding based on subject type
    - Add click handlers for cell explanations
    - _Requirements: 12.5, 21.1_

  - [ ] 16.5 Implement reliability and conflict display
    - Implement updateReliabilityDisplay/1 function
    - Display reliability score with color-coded bar
    - Display risk level (low/medium/high)
    - Implement checkAndHighlightConflicts/0 function
    - Highlight conflicting cells in red
    - Display conflict list with descriptions
    - _Requirements: 12.6, 12.9, 21.2, 21.3_

  - [ ] 16.6 Implement explanation modal
    - Implement showExplanation/1 function
    - Call POST /api/explain endpoint
    - Display explanation in modal dialog
    - Add modal close handler
    - _Requirements: 12.8_

  - [ ] 16.7 Implement export functionality
    - Implement exportTimetable/1 function
    - Add click handlers for PDF, CSV, JSON export buttons
    - Call GET /api/export endpoint with format parameter
    - Trigger file download
    - _Requirements: 12.10, 25.1, 25.2, 25.3_

  - [ ] 16.8 Implement notification system
    - Implement showNotification/2 function
    - Display success, error, info, warning notifications
    - Auto-dismiss after 3 seconds
    - Style notifications appropriately

- [ ] 17. Checkpoint - Frontend functional
  - Test all forms and resource submission
  - Test timetable generation and visualization
  - Test conflict detection and highlighting
  - Test explanation modal
  - Test export functionality
  - Verify responsive design on different screen sizes
  - Ensure all tests pass, ask the user if questions arise

## Phase 5: Advanced Features Implementation

- [ ] 18. Implement Feature 1: Explainable AI (XAI)
  - [ ] 18.1 Create xai_explainer.pl module
    - Implement explain_assignment/6 (detailed explanation with proof tracing)
    - Implement trace_assignment_reason/6 (collect reasoning steps)
    - Implement format_explanation_steps/2 (format steps as text)
    - Implement calculate_assignment_quality/4 (quality score for assignment)
    - Add helper predicates: teacher_workload_score/2, room_utilization_score/2, time_preference_score/2
    - _Requirements: 9.1, 9.2, 9.3_

  - [ ] 18.2 Add XAI API endpoint
    - Implement handle_explain_detailed/1 for POST /api/explain_detailed
    - Integrate with xai_explainer.pl
    - Return structured explanation with reasoning steps


  - [ ] 18.3 Add XAI frontend components
    - Enhance explanation modal with step-by-step display
    - Add CSS for explanation steps with color coding
    - Implement displayXAIExplanation/1 function
    - Show quality score for each assignment

- [ ] 19. Implement Feature 2: Smart Conflict Suggestion System
  - [ ] 19.1 Create conflict_resolver.pl module
    - Implement suggest_fix/2 (generate intelligent suggestions)
    - Implement suggest_teacher_conflict_fix/4 (suggestions for teacher conflicts)
    - Implement find_alternative_slots/3 (find alternative time slots)
    - Implement find_alternative_teachers/4 (find alternative teachers)
    - Implement find_swappable_sessions/3 (find sessions that can be swapped)
    - Implement apply_fix/2 (execute a suggested fix)
    - Implement execute_fix/3 (apply specific fix type)

  - [ ] 19.2 Add conflict suggestion API endpoints
    - Implement handle_suggest_fixes/1 for GET /api/suggest_fixes
    - Implement handle_apply_fix/1 for POST /api/apply_fix
    - Return conflicts with actionable suggestions

  - [ ] 19.3 Add conflict suggestion frontend
    - Create conflict suggestions panel in HTML
    - Implement loadConflictSuggestions/0 function
    - Implement displayConflictSuggestions/1 function
    - Implement applyFix/1 function
    - Add CSS for suggestion buttons and conflict items

- [ ] 20. Implement Feature 3: Scenario Simulation
  - [ ] 20.1 Create scenario_simulator.pl module
    - Implement simulate_scenario/3 (main simulation entry point)
    - Implement teacher_absence scenario (mark teacher unavailable, reassign sessions)
    - Implement room_maintenance scenario (mark room unavailable, reassign sessions)
    - Implement extra_class scenario (add new sessions to timetable)
    - Implement exam_week scenario (adjust timetable for exam constraints)
    - Implement mark_teacher_unavailable/4
    - Implement reassign_sessions/3
    - Implement find_alternative_assignment/2
    - Implement compare_scenarios/3 (compare two scenarios)

  - [ ] 20.2 Add scenario simulation API endpoints
    - Implement handle_simulate/1 for POST /api/simulate
    - Implement handle_compare_scenarios/1 for POST /api/compare_scenarios
    - Return simulated timetable with reliability score

  - [ ] 20.3 Add scenario simulation frontend
    - Create scenario section in HTML with scenario type selector
    - Add parameter input fields for each scenario type
    - Implement simulateScenario/2 function
    - Implement displayScenarioComparison/2 function
    - Show side-by-side comparison of original and simulated timetables
    - Highlight differences between timetables

- [ ] 21. Implement Feature 4: Timetable Quality Scoring
  - [ ] 21.1 Create quality_scorer.pl module
    - Implement calculate_quality_score/2 (comprehensive 0-100 score)
    - Implement hard_constraint_score/2 (constraint satisfaction score)
    - Implement workload_balance_score/2 (teacher workload balance)
    - Implement room_utilization_score/2 (room efficiency)
    - Implement schedule_compactness_score/2 (minimize gaps)
    - Implement quality_breakdown/2 (detailed breakdown)
    - Add helper predicates: count_constraint_violations/3, calculate_balance_metric/2, count_gaps/2

  - [ ] 21.2 Add quality scoring API endpoint
    - Implement handle_quality_score/1 for GET /api/quality_score
    - Return overall score and breakdown

  - [ ] 21.3 Add quality scoring frontend
    - Create quality display panel in HTML
    - Implement displayQualityScore/1 function
    - Show circular quality score indicator
    - Display breakdown with progress bars for each metric
    - Add CSS for quality visualization

- [ ] 22. Implement Feature 5: AI Recommendation Engine
  - [ ] 22.1 Create recommendation_engine.pl module
    - Implement generate_recommendations/2 (analyze and suggest improvements)
    - Implement analyze_workload_imbalance/2 (detect workload issues)
    - Implement analyze_room_underutilization/2 (detect unused rooms)
    - Implement analyze_schedule_gaps/2 (detect excessive gaps)
    - Implement analyze_late_theory_classes/2 (detect suboptimal scheduling)
    - Implement format_recommendation/2 (format as actionable text)
    - Implement apply_recommendation/2 (execute recommendation)


  - [ ] 22.2 Add recommendation API endpoints
    - Implement handle_recommendations/1 for GET /api/recommendations
    - Implement handle_apply_recommendation/1 for POST /api/apply_recommendation
    - Return prioritized list of recommendations

  - [ ] 22.3 Add recommendation frontend
    - Create recommendations panel in HTML
    - Implement loadRecommendations/0 function
    - Implement displayRecommendations/1 function
    - Add apply buttons for each recommendation
    - Show before/after preview when applying recommendations

- [ ] 23. Implement Feature 6: Visual Heatmap
  - [ ] 23.1 Create heatmap_generator.pl module
    - Implement generate_heatmap/2 (create heatmap data structure)
    - Implement calculate_cell_intensity/3 (calculate utilization intensity)
    - Implement teacher_heatmap/2 (teacher workload heatmap)
    - Implement room_heatmap/2 (room utilization heatmap)
    - Implement timeslot_heatmap/2 (time slot popularity heatmap)

  - [ ] 23.2 Add heatmap API endpoint
    - Implement handle_heatmap/1 for GET /api/heatmap
    - Support different heatmap types (teacher, room, timeslot)
    - Return heatmap data as JSON

  - [ ] 23.3 Add heatmap frontend
    - Create heatmap visualization section in HTML
    - Implement renderHeatmap/1 function
    - Use color gradient (green → yellow → red) for intensity
    - Add heatmap type selector
    - Add CSS for heatmap cells with color transitions

- [ ] 24. Implement Feature 7: AI Search Visualization
  - [ ] 24.1 Create search_statistics.pl module
    - Implement initialize_search_stats/0 (reset statistics)
    - Implement increment_stat/1 (increment counter)
    - Implement get_search_statistics/1 (retrieve all stats)
    - Add statistics tracking to CSP solver (nodes, backtracks, heuristics, prunings)
    - Implement solve_csp_with_stats/3 (CSP solver with statistics)
    - Implement backtracking_search_with_stats/4
    - Implement log_search_statistics/1

  - [ ] 24.2 Add search statistics API endpoint
    - Implement handle_search_stats/1 for GET /api/search_stats
    - Return comprehensive search statistics

  - [ ] 24.3 Add search visualization frontend
    - Create search statistics panel in HTML
    - Implement loadSearchStatistics/0 function
    - Implement displaySearchStatistics/1 function
    - Implement visualizeSearchTree/1 (bar chart visualization)
    - Use Canvas API for visualization
    - Auto-load statistics after generation

- [ ] 25. Implement Feature 8: Multiple Timetable Generation
  - [ ] 25.1 Create multi_solution_generator.pl module
    - Implement generate_top_timetables/2 (generate N best timetables)
    - Implement generate_multiple_solutions/4 (generate variants)
    - Implement generate_solution_variant/3 (randomized search)
    - Implement rank_solutions_by_quality/2 (sort by quality score)
    - Implement score_solution/2 (combined quality + reliability score)
    - Implement remove_duplicates/2 (eliminate equivalent timetables)
    - Implement compare_timetables/3 (detailed comparison)

  - [ ] 25.2 Add multiple solutions API endpoints
    - Implement handle_generate_multiple/1 for POST /api/generate_multiple
    - Implement handle_compare_timetables/1 for POST /api/compare_timetables
    - Limit to maximum 10 solutions
    - Return ranked list with scores

  - [ ] 25.3 Add multiple solutions frontend
    - Create multiple solutions panel in HTML
    - Add solution count input (2-10)
    - Implement generateMultipleTimetables/1 function
    - Implement displayMultipleSolutions/1 function
    - Implement previewTimetable/1 (show preview in modal)
    - Implement selectTimetable/1 (choose preferred option)
    - Display quality and reliability badges for each option

- [ ] 26. Implement Feature 9: Constraint Importance Slider
  - [ ] 26.1 Create dynamic_constraints.pl module
    - Implement initialize_constraint_weights/0 (set defaults)
    - Implement set_constraint_weight/2 (update weight 0.0-1.0)
    - Implement get_constraint_weight/2 (retrieve weight)
    - Implement calculate_weighted_soft_score/2 (weighted scoring)
    - Implement teacher_preference_score/2
    - Implement room_optimization_score/2
    - Implement student_compact_score/2
    - Implement generate_with_custom_weights/2 (generate with custom priorities)


  - [ ] 26.2 Add constraint weights API endpoints
    - Implement handle_constraint_weights/1 for GET /api/constraint_weights
    - Implement handle_set_weights/1 for POST /api/set_weights
    - Implement handle_generate_with_weights/1 for POST /api/generate_with_weights
    - Return current weights and updated timetable

  - [ ] 26.3 Add constraint sliders frontend
    - Create constraint weights panel in HTML
    - Add range sliders for each soft constraint (0-100%)
    - Implement slider value display and update handlers
    - Implement applyWeights/0 function
    - Implement regenerateWithWeights/0 function
    - Add reset to defaults button
    - Add CSS for sliders with custom styling

- [ ] 27. Implement Feature 10: Real-Time Validation
  - [ ] 27.1 Create realtime_validator.pl module
    - Implement validate_teacher_input/2 (check teacher data)
    - Implement validate_subject_input/2 (check subject data)
    - Implement validate_room_input/2 (check room data)
    - Implement validate_timeslot_input/2 (check timeslot data)
    - Implement validate_class_input/2 (check class data)
    - Implement check_resource_conflicts/2 (detect conflicts with existing data)
    - Implement suggest_corrections/2 (suggest fixes for invalid input)

  - [ ] 27.2 Add real-time validation API endpoint
    - Implement handle_validate_input/1 for POST /api/validate_input
    - Return validation result with errors and suggestions
    - Support all resource types

  - [ ] 27.3 Add real-time validation frontend
    - Add input event listeners to all form fields
    - Implement validateFieldRealtime/2 function
    - Display inline validation messages
    - Show green checkmark for valid input
    - Show red error icon with message for invalid input
    - Disable submit button until all fields are valid
    - Add CSS for validation indicators

- [ ] 28. Checkpoint - Advanced features complete
  - Test all 10 advanced features individually
  - Test integration between features
  - Verify XAI explanations are detailed and accurate
  - Verify conflict suggestions are actionable
  - Verify scenario simulations work correctly
  - Verify quality scoring is comprehensive
  - Verify recommendations are helpful
  - Verify heatmaps display correctly
  - Verify search statistics are accurate
  - Verify multiple solutions are ranked properly
  - Verify constraint sliders affect generation
  - Verify real-time validation works on all forms
  - Ensure all tests pass, ask the user if questions arise

## Phase 5A: Evolutionary Optimization and Next-Generation Features

- [ ] 28A. Implement Feature 11: Genetic Algorithm Optimization
  - [ ] 28A.1 Create genetic_optimizer.pl module
    - Implement chromosome representation for timetable (encode as gene sequence)
    - Implement population_initialization/2 (create initial population of N timetables)
    - Implement fitness_function/2 (evaluate timetable quality: constraints + workload + utilization)
    - Implement crossover_operator/3 (combine two parent timetables)
    - Implement mutation_operator/2 (randomly modify timetable assignments)
    - Implement selection_strategy/3 (tournament or roulette wheel selection)
    - Implement evolution_loop/4 (iterate generations until convergence)
    - Implement optimize_timetable_with_ga/2 (main GA entry point)

  - [ ] 28A.2 Add genetic algorithm API endpoint
    - Implement handle_optimize_ga/1 for POST /api/optimize_ga
    - Accept parameters: population_size, generations, mutation_rate, crossover_rate
    - Return optimized timetable with fitness history

  - [ ] 28A.3 Add genetic algorithm frontend
    - Add "Generate Optimized Timetable (GA)" button
    - Create GA configuration panel (population size, generations, mutation rate)
    - Display evolution progress (generation number, best fitness)
    - Show fitness history chart
    - Compare CSP solution vs GA optimized solution

- [ ] 28B. Implement Feature 12: Interactive Drag-and-Drop Editing
  - [ ] 28B.1 Create interactive_editor.pl module
    - Implement validate_manual_change/4 (check if manual edit is valid)
    - Implement apply_manual_change/4 (update timetable with user edit)
    - Implement suggest_alternative_slots/3 (suggest valid alternatives if invalid)
    - Implement check_cascading_effects/3 (detect if edit affects other assignments)
    - Implement auto_fix_conflicts/2 (automatically resolve conflicts from manual edit)

  - [ ] 28B.2 Add interactive editing API endpoints
    - Implement handle_validate_move/1 for POST /api/validate_move
    - Implement handle_apply_move/1 for POST /api/apply_move
    - Implement handle_suggest_alternatives/1 for POST /api/suggest_alternatives
    - Return validation result with warnings and suggestions

  - [ ] 28B.3 Add drag-and-drop frontend
    - Make timetable cells draggable (HTML5 drag-and-drop API)
    - Implement drag start, drag over, drop event handlers
    - Show visual feedback during drag (ghost image, drop zones)
    - Validate drop target in real-time
    - Show warning modal if constraint violated
    - Display suggested alternatives if invalid
    - Update timetable after successful drop

- [ ] 28C. Implement Feature 13: Historical Learning System
  - [ ] 28C.1 Create learning_module.pl module
    - Implement store_timetable_history/1 (save generated timetables)
    - Implement analyze_scheduling_patterns/2 (detect patterns from history)
    - Implement learn_preferred_slots/2 (identify teacher/subject preferences)
    - Implement learn_successful_assignments/2 (identify high-quality patterns)
    - Implement apply_learned_preferences/2 (bias generation toward learned patterns)
    - Implement get_learning_statistics/1 (show what system has learned)

  - [ ] 28C.2 Add learning system API endpoints
    - Implement handle_learning_stats/1 for GET /api/learning_stats
    - Implement handle_apply_learning/1 for POST /api/apply_learning
    - Implement handle_clear_history/1 for POST /api/clear_history
    - Return learned patterns and statistics

  - [ ] 28C.3 Add learning system frontend
    - Create learning dashboard showing learned patterns
    - Display preferred slots for each teacher
    - Display successful assignment patterns
    - Add toggle to enable/disable learning-based generation
    - Show learning statistics (timetables analyzed, patterns discovered)

- [ ] 28D. Implement Feature 14: Automatic Constraint Discovery
  - [ ] 28D.1 Create pattern_analyzer.pl module
    - Implement discover_patterns/2 (analyze dataset for hidden patterns)
    - Implement detect_temporal_patterns/2 (e.g., "AI classes usually in morning")
    - Implement detect_resource_patterns/2 (e.g., "Labs rarely on Friday")
    - Implement detect_teacher_patterns/2 (e.g., "Dr. Smith prefers consecutive slots")
    - Implement suggest_new_constraints/2 (propose soft constraints from patterns)
    - Implement validate_discovered_pattern/2 (verify pattern significance)

  - [ ] 28D.2 Add pattern discovery API endpoint
    - Implement handle_discover_patterns/1 for POST /api/discover_patterns
    - Return discovered patterns with confidence scores
    - Allow user to accept/reject discovered constraints

  - [ ] 28D.3 Add pattern discovery frontend
    - Create pattern discovery panel
    - Display discovered patterns with confidence percentages
    - Add accept/reject buttons for each pattern
    - Show impact preview if pattern is applied
    - Visualize patterns with charts

- [ ] 28E. Implement Feature 15: What-If Optimization Dashboard
  - [ ] 28E.1 Create multi_scenario_analyzer.pl module
    - Implement analyze_multiple_scenarios/2 (run multiple scenarios in parallel)
    - Implement scenario_comparison_matrix/2 (compare all scenarios)
    - Implement rank_scenarios_by_quality/2 (rank by quality and reliability)
    - Implement calculate_scenario_metrics/2 (quality, reliability, resource usage)
    - Implement recommend_best_scenario/2 (AI recommendation based on metrics)

  - [ ] 28E.2 Add multi-scenario API endpoint
    - Implement handle_analyze_scenarios/1 for POST /api/analyze_scenarios
    - Accept list of scenarios to simulate
    - Return comparison matrix with metrics

  - [ ] 28E.3 Add what-if dashboard frontend
    - Create multi-scenario comparison dashboard
    - Display comparison table (Scenario | Quality | Reliability | Changes)
    - Add scenario builder interface
    - Visualize metrics with bar charts
    - Highlight recommended scenario

- [ ] 28F. Implement Feature 16: Constraint Graph Visualization
  - [ ] 28F.1 Create constraint_graph.pl module
    - Implement generate_constraint_graph/1 (create graph structure)
    - Implement add_resource_nodes/2 (teachers, subjects, rooms, timeslots as nodes)
    - Implement add_constraint_edges/2 (constraints as edges)
    - Implement calculate_graph_metrics/2 (node degree, clustering coefficient)
    - Implement export_graph_json/2 (format for visualization libraries)

  - [ ] 28F.2 Add constraint graph API endpoint
    - Implement handle_constraint_graph/1 for GET /api/constraint_graph
    - Return graph structure with nodes and edges

  - [ ] 28F.3 Add constraint graph visualization frontend
    - Integrate graph visualization library (D3.js or vis.js)
    - Display interactive constraint graph
    - Color-code nodes by resource type
    - Show edge labels with constraint types
    - Add zoom and pan controls
    - Highlight conflicts in graph

- [ ] 28G. Implement Feature 17: AI Complexity Analysis Module
  - [ ] 28G.1 Create complexity_analyzer.pl module
    - Implement analyze_solver_complexity/1 (comprehensive complexity metrics)
    - Implement calculate_branching_factor/2 (average branching factor)
    - Implement calculate_search_depth/2 (maximum and average depth)
    - Implement calculate_constraint_density/2 (constraints per variable)
    - Implement calculate_time_complexity/2 (actual vs theoretical complexity)
    - Implement generate_complexity_report/2 (detailed analysis report)

  - [ ] 28G.2 Add complexity analysis API endpoint
    - Implement handle_complexity_analysis/1 for GET /api/complexity_analysis
    - Return comprehensive complexity metrics

  - [ ] 28G.3 Add complexity analysis frontend
    - Create complexity analysis panel
    - Display metrics with charts (branching factor, depth, density)
    - Show Big-O complexity estimation
    - Compare with theoretical bounds
    - Export complexity report

- [ ] 28H. Implement Feature 18: Natural Language Query Interface
  - [ ] 28H.1 Create nl_query.pl module
    - Implement answer_query/2 (parse and answer natural language queries)
    - Implement parse_nl_query/2 (extract intent and entities)
    - Implement query_teacher_schedule/2 ("Show Dr. Smith schedule")
    - Implement query_room_availability/2 ("When is Lab 2 free?")
    - Implement query_subject_details/2 ("Which teacher teaches AI?")
    - Implement query_class_schedule/2 ("Show CS1 timetable")
    - Implement format_nl_answer/2 (format answer in natural language)

  - [ ] 28H.2 Add NL query API endpoint
    - Implement handle_nl_query/1 for POST /api/nl_query
    - Accept natural language text
    - Return natural language answer

  - [ ] 28H.3 Add NL query frontend
    - Create query input box with search icon
    - Implement query submission and display
    - Show query history
    - Display answers with formatting
    - Add example queries as suggestions

- [ ] 28I. Implement Feature 19: AI Conflict Prediction
  - [ ] 28I.1 Create conflict_predictor.pl module
    - Implement predict_conflicts/2 (analyze resources before generation)
    - Implement calculate_conflict_probability/2 (estimate likelihood of conflicts)
    - Implement identify_bottleneck_resources/2 (find scarce resources)
    - Implement suggest_preventive_actions/2 (recommend actions to avoid conflicts)
    - Implement risk_assessment/2 (categorize risk level: low/medium/high)

  - [ ] 28I.2 Add conflict prediction API endpoint
    - Implement handle_predict_conflicts/1 for POST /api/predict_conflicts
    - Return risk report with predictions and suggestions

  - [ ] 28I.3 Add conflict prediction frontend
    - Create risk assessment panel
    - Display predictions before generation
    - Show bottleneck resources with warnings
    - Display preventive action suggestions
    - Add "Generate Anyway" or "Fix Issues First" options

- [ ] 28J. Implement Feature 20: Timetable Versioning System
  - [ ] 28J.1 Create version_manager.pl module
    - Implement save_version/2 (save timetable with version ID and timestamp)
    - Implement load_version/2 (retrieve specific version)
    - Implement list_versions/1 (get all saved versions)
    - Implement compare_versions/3 (detailed diff between versions)
    - Implement rollback_to_version/2 (restore previous version)
    - Implement version_metadata/2 (get version info: timestamp, author, reason)

  - [ ] 28J.2 Add versioning API endpoints
    - Implement handle_save_version/1 for POST /api/save_version
    - Implement handle_list_versions/1 for GET /api/versions
    - Implement handle_load_version/1 for GET /api/version/:id
    - Implement handle_compare_versions/1 for POST /api/compare_versions
    - Implement handle_rollback/1 for POST /api/rollback

  - [ ] 28J.3 Add versioning frontend
    - Create version history panel
    - Display version timeline with timestamps
    - Add save version button with comment input
    - Implement version comparison view (side-by-side diff)
    - Add rollback button with confirmation
    - Show version metadata (who, when, why)

- [ ] 28K. Checkpoint - Next-generation features complete
  - Test genetic algorithm optimization (verify improved quality)
  - Test drag-and-drop editing (verify constraint validation)
  - Test historical learning (verify pattern detection)
  - Test constraint discovery (verify pattern significance)
  - Test what-if dashboard (verify scenario comparisons)
  - Test constraint graph visualization (verify graph accuracy)
  - Test complexity analysis (verify metrics correctness)
  - Test natural language queries (verify answer accuracy)
  - Test conflict prediction (verify prediction accuracy)
  - Test version management (verify diff and rollback)
  - Ensure all tests pass, ask the user if questions arise

## Phase 6: Testing and Validation

- [ ] 29. Implement testing.pl module
  - [ ] 29.1 Create unit test framework
    - Implement run_all_tests/0 (main test runner)
    - Implement test_knowledge_base/0 (test FOL predicates)
    - Implement test_matrix_operations/0 (test matrix operations)
    - Implement test_constraints/0 (test constraint checking)
    - Implement test_csp_solver/0 (test CSP solving)
    - Implement test_probability/0 (test reliability calculations)
    - Implement test_timetable_generation/0 (test end-to-end generation)
    - Add assertion helpers: assert_true/2, assert_equals/3
    - _Requirements: 26.1, 26.2, 26.3, 26.4, 26.5_

  - [ ] 29.2 Create property-based test framework
    - Install or implement property-based testing library for Prolog
    - Create test data generators (random teachers, subjects, rooms, etc.)
    - Implement property test runner with configurable iterations (100+)
    - Add property test reporting with counterexamples

  - [ ]* 29.3 Implement core correctness property tests
    - **Property 1: Resource Data Round-Trip** - Validates Requirements 1.6
    - **Property 2: Invalid Data Rejection** - Validates Requirements 1.7
    - **Property 3: Matrix Structure Preservation** - Validates Requirements 2.7
    - **Property 4: Matrix Dimension Correctness** - Validates Requirements 2.2
    - **Property 5: Teacher Qualification Inference** - Validates Requirements 3.6
    - **Property 6: Room Suitability Inference** - Validates Requirements 3.7
    - **Property 16: Workload Balance Measurement** - Validates Requirements 5.1
    - **Property 17: Late Theory Class Detection** - Validates Requirements 5.2
    - **Property 18: Back-to-Back Lab Detection** - Validates Requirements 5.3
    - **Property 19: Schedule Gap Measurement** - Validates Requirements 5.5
    - Run each property test 100+ times


  - [ ]* 29.4 Implement explanation and conflict property tests
    - **Property 23: Assignment Explanation Availability** - Validates Requirements 9.1, 9.3
    - **Property 24: Conflict Detection Completeness** - Validates Requirements 3.8, 3.9, 9.4
    - **Property 25: Conflict Description Completeness** - Validates Requirements 9.5
    - **Property 27: Parse Validation** - Validates Requirements 10.2
    - **Property 28: Invalid Parse Error Messages** - Validates Requirements 10.3
    - **Property 29: JSON Format Validity** - Validates Requirements 10.5
    - Run each property test 100+ times

  - [ ]* 29.5 Implement error handling property tests
    - **Property 34: Concurrent Request Data Consistency** - Validates Requirements 15.5
    - **Property 35: Exception Handling** - Validates Requirements 16.1, 16.2
    - **Property 36: Inconsistent Data Detection** - Validates Requirements 16.3, 16.4
    - **Property 38: Missing Resource Error Reporting** - Validates Requirements 16.6
    - **Property 39: Repair Preserves Valid Assignments** - Validates Requirements 20.2
    - **Property 40: Repair Minimizes Changes** - Validates Requirements 20.3
    - Run each property test 100+ times

  - [ ]* 29.6 Implement analytics and validation property tests
    - **Property 41: Analytics Calculation Completeness** - Validates Requirements 22.1, 22.2, 22.3
    - **Property 42: Analytics JSON Export** - Validates Requirements 22.5
    - **Property 43: Input Validation Completeness** - Validates Requirements 24.1
    - **Property 44: Invalid Identifier Rejection** - Validates Requirements 24.2
    - **Property 45: Text Field Sanitization** - Validates Requirements 24.3
    - **Property 46: Payload Size Limits** - Validates Requirements 24.4
    - **Property 47: Export Format Completeness** - Validates Requirements 25.1, 25.2, 25.3, 25.4
    - Run each property test 100+ times

- [ ] 30. Performance testing and optimization
  - [ ] 30.1 Test performance with different problem sizes
    - Test with 3 classes, 8 subjects (should complete within 30 seconds)
    - Test with 5 classes, 10 subjects (should complete within 2 minutes)
    - Test with 10 classes, 15 subjects (observe performance)
    - _Requirements: 15.1, 15.2_

  - [ ] 30.2 Implement performance optimizations
    - Add node count limit (10000 nodes) with timeout
    - Add progress logging every 1000 nodes
    - Optimize domain initialization
    - Optimize constraint checking
    - Add memoization where applicable
    - _Requirements: 15.3, 15.4_

  - [ ] 30.3 Test concurrent request handling
    - Simulate multiple concurrent API requests
    - Verify no data corruption occurs
    - Verify request timeout limits (5 minutes max)
    - _Requirements: 15.5, 15.6_

- [ ] 31. Integration testing
  - Test complete workflow: resource input → generation → visualization → export
  - Test error recovery: invalid input → error message → correction → success
  - Test scenario simulation workflow
  - Test conflict resolution workflow
  - Test recommendation application workflow
  - Test multiple solution selection workflow
  - Verify all features work together seamlessly

- [ ] 32. Checkpoint - All tests passing
  - Run complete test suite (unit + property tests)
  - Verify all 47 core correctness properties pass
  - Verify all 10 advanced features work correctly
  - Fix any failing tests
  - Document any known limitations
  - Ensure all tests pass, ask the user if questions arise

## Phase 7: Documentation and Deployment

- [ ] 33. Complete documentation
  - [ ] 33.1 Update README.md
    - Add comprehensive installation instructions for all platforms
    - Add step-by-step usage guide
    - Add troubleshooting section
    - Add screenshots of the web interface
    - Add example commands and outputs
    - _Requirements: 14.3, 14.4, 14.5_

  - [ ] 33.2 Create architecture.md
    - Document system architecture with diagrams
    - Explain module interactions and data flow
    - Document MFAI concept mapping
    - Explain CSP formulation and algorithms
    - Document API endpoints with examples
    - _Requirements: 14.6, 17.1, 17.2, 17.3, 17.4, 17.5, 17.6, 17.7_


  - [ ] 33.3 Add code documentation
    - Add comprehensive comments to all Prolog predicates
    - Document predicate signatures with parameter descriptions
    - Add usage examples in comments
    - Document key algorithms (CSP, heuristics, probability)
    - Add JSDoc comments to JavaScript functions
    - _Requirements: 14.7_

  - [ ] 33.4 Create user guide
    - Write step-by-step tutorial for first-time users
    - Document all features with screenshots
    - Explain advanced features (XAI, scenarios, recommendations, etc.)
    - Add FAQ section
    - Add video tutorial (optional)

  - [ ] 33.5 Create developer guide
    - Document how to extend the system with new features
    - Explain how to add new constraint types
    - Document how to add new optimization strategies
    - Explain how to add new resource types
    - Document testing procedures
    - _Requirements: 27.1, 27.2, 27.3, 27.4, 27.5_

- [ ] 34. Prepare example outputs
  - Generate example timetable with dataset.pl
  - Export timetable in all formats (PDF, CSV, JSON)
  - Capture screenshots of web interface
  - Create example scenario simulations
  - Document example quality scores and reliability
  - _Requirements: 14.8_

- [ ] 35. Create deployment guide
  - Document server deployment steps
  - Document environment configuration
  - Document security considerations
  - Document backup and recovery procedures
  - Document monitoring and logging setup
  - Add Docker containerization (optional)
  - Add cloud deployment guide (optional)

- [ ] 36. Final system validation
  - Verify all 27 requirements are implemented
  - Verify all 10 advanced features are functional
  - Verify all 47+ correctness properties pass
  - Verify documentation is complete and accurate
  - Verify example data works correctly
  - Perform end-to-end system test
  - Get user acceptance feedback

## Notes

### Task Organization
- Tasks are organized into 7 logical phases for systematic implementation
- Each phase builds on previous phases
- Checkpoints ensure incremental validation
- Optional tasks (marked with `*`) are property-based tests that can be skipped for faster MVP

### Requirements Coverage
- All 27 requirements are covered by implementation tasks
- Each task references specific requirements for traceability
- Property tests validate correctness properties derived from requirements

### Advanced Features
- 20 innovative advanced features transform the system into an "AI-Driven Intelligent Timetable Decision Support System"
- Features 1-10 demonstrate: XAI, Decision Support, Robustness, Multi-Objective Optimization, Interactive AI, Visualization
- Features 11-20 demonstrate: Evolutionary AI, Human-AI Collaboration, Adaptive Learning, Knowledge Discovery, CSP Visualization, Algorithm Analysis, Symbolic AI, Probabilistic Prediction, Version Control
- Each feature includes backend module, API endpoint, and frontend components

### Testing Strategy
- Dual approach: Unit tests + Property-based tests
- 47+ correctness properties ensure comprehensive validation
- Each property test runs 100+ iterations with random data
- Property tests are optional but highly recommended for production systems

### Technology Stack
- Backend: SWI-Prolog 8.x with http, json, lists libraries
- Frontend: HTML5, CSS3, Vanilla JavaScript (no frameworks required)
- Data: Prolog fact database (in-memory with file persistence)
- Testing: Custom property-based testing framework

### Implementation Tips
- Start with core modules (knowledge_base, matrix_model, constraints)
- Test each module independently before integration
- Use logging extensively for debugging CSP solver
- Optimize only after correctness is verified
- Document as you code, not after

### MFAI Concept Demonstration
This system explicitly demonstrates all required MFAI concepts:
- **Linear Algebra**: Matrix-based timetable representation (matrix_model.pl)
- **Propositional Logic**: Boolean constraint expressions (constraints.pl)
- **First Order Logic**: Predicates with variables and quantifiers (knowledge_base.pl)
- **Logical Inference**: Backward chaining query resolution (Prolog inference engine)
- **Constraint Satisfaction**: Backtracking search with heuristics (csp_solver.pl)
- **Probabilistic Reasoning**: Reliability calculation using conditional probabilities (probability_module.pl)
- **Explainable AI**: Proof tracing and reasoning transparency (xai_explainer.pl)
- **Evolutionary AI**: Genetic algorithms for optimization (genetic_optimizer.pl)
- **Adaptive Learning**: Pattern recognition and preference learning (learning_module.pl)
- **Knowledge Discovery**: Automatic constraint discovery (pattern_analyzer.pl)
- **Symbolic AI**: Natural language query processing (nl_query.pl)
- **Predictive AI**: Conflict prediction using probabilistic reasoning (conflict_predictor.pl)

### Estimated Timeline
- Phase 1 (Setup): 1-2 days
- Phase 2 (Core Backend): 5-7 days
- Phase 3 (API Server): 2-3 days
- Phase 4 (Frontend): 3-4 days
- Phase 5 (Advanced Features 1-10): 7-10 days
- Phase 5A (Next-Gen Features 11-20): 10-14 days
- Phase 6 (Testing): 4-6 days
- Phase 7 (Documentation): 2-3 days
- **Total: 34-49 days** (approximately 7-10 weeks)

### Feature Impact Summary

| Feature | AI Concept | Academic Impact |
|---------|-----------|-----------------|
| Feature 11: Genetic Algorithm | Evolutionary AI | Demonstrates bio-inspired optimization |
| Feature 12: Drag-Drop Editing | Human-AI Collaboration | Shows interactive AI systems |
| Feature 13: Historical Learning | Adaptive AI | Demonstrates machine learning |
| Feature 14: Constraint Discovery | Knowledge Mining | Shows pattern recognition |
| Feature 15: What-If Dashboard | Decision Support | Multi-scenario analysis |
| Feature 16: Constraint Graph | CSP Visualization | Visual algorithm explanation |
| Feature 17: Complexity Analysis | Algorithm Evaluation | Theoretical CS analysis |
| Feature 18: NL Query Interface | Symbolic AI + NLP | Natural language processing |
| Feature 19: Conflict Prediction | Probabilistic AI | Predictive analytics |
| Feature 20: Version Control | Intelligent Management | System evolution tracking |

### Success Criteria
- All 27 requirements implemented and verified
- All 10 advanced features functional
- All 47+ correctness properties pass (100+ iterations each)
- Complete documentation (README, architecture, user guide, developer guide)
- Example dataset generates valid timetable
- Web interface is intuitive and responsive
- System demonstrates all MFAI concepts clearly
