# Quick Reference: AI Intelligent Timetable Decision System

## Document Structure

This specification consists of multiple documents:

1. **design.md** - Main design document with core system architecture
2. **requirements.md** - Feature requirements (if exists)
3. **advanced-features.md** - Features 1-6 detailed specifications
4. **advanced-features-part2.md** - Features 7-10 detailed specifications
5. **ADVANCED_FEATURES_INTEGRATION.md** - Integration guide
6. **QUICK_REFERENCE.md** - This document

## 10 Advanced Features at a Glance

### Feature 1: Explainable AI Timetable (XAI)
**What**: Click on any timetable cell to see WHY that assignment was made
**Module**: `xai_explainer.pl`
**API**: `POST /api/explain_detailed`
**Demo**: Shows Prolog proof tracing and logical inference

### Feature 2: Smart Conflict Suggestion System
**What**: Get AI-powered suggestions to fix conflicts (not just detect them)
**Module**: `conflict_resolver.pl`
**API**: `GET /api/suggest_fixes`, `POST /api/apply_fix`
**Demo**: Shows AI decision support and constraint reasoning

### Feature 3: Scenario Simulation
**What**: Simulate "what if" scenarios (teacher absence, room maintenance, etc.)
**Module**: `scenario_simulator.pl`
**API**: `POST /api/simulate`, `POST /api/compare_scenarios`
**Demo**: Shows AI robustness and adaptability

### Feature 4: Timetable Quality Scoring
**What**: Get comprehensive quality score (0-100) with detailed breakdown
**Module**: `quality_scorer.pl`
**API**: `GET /api/quality_score`
**Demo**: Shows multi-objective optimization

### Feature 5: AI Recommendation Engine
**What**: Get intelligent suggestions to improve your timetable
**Module**: `recommendation_engine.pl`
**API**: `GET /api/recommendations`, `POST /api/apply_recommendation`
**Demo**: Shows AI advisory capabilities

### Feature 6: Visual Heatmap
**What**: See resource utilization as color-coded heatmaps
**Module**: `heatmap_generator.pl`
**API**: `GET /api/heatmap/rooms`, `/teachers`, `/timeslots`
**Demo**: Shows data visualization and pattern recognition

### Feature 7: AI Search Visualization
**What**: See CSP search statistics (nodes explored, backtracks, etc.)
**Module**: `search_statistics.pl`
**API**: `GET /api/search_stats`
**Demo**: Shows algorithm transparency and debugging

### Feature 8: Multiple Timetable Generation
**What**: Generate top N best timetables and choose your favorite
**Module**: `multi_solution_generator.pl`
**API**: `POST /api/generate_multiple`, `POST /api/compare_timetables`
**Demo**: Shows solution space exploration

### Feature 9: Constraint Importance Slider
**What**: Adjust soft constraint priorities with sliders
**Module**: `dynamic_constraints.pl`
**API**: `GET /api/constraint_weights`, `POST /api/set_weights`
**Demo**: Shows customizable AI optimization

### Feature 10: Real-Time Constraint Checking
**What**: Get instant validation feedback as you type
**Module**: `realtime_validator.pl`
**API**: `POST /api/validate/teacher`, `/subject`, `/room`, `/assignment`
**Demo**: Shows proactive AI reasoning

## Key Predicates by Feature

### Feature 1: XAI
```prolog
explain_assignment(+ClassID, +SubjectID, +TeacherID, +RoomID, +SlotID, -Explanation)
trace_assignment_reason(+ClassID, +SubjectID, +TeacherID, +RoomID, +SlotID, -Step)
format_explanation_steps(+Steps, -Explanation)
```

### Feature 2: Conflict Resolution
```prolog
suggest_fix(+Conflict, -Suggestions)
apply_fix(+Suggestion, -UpdatedTimetable)
find_alternative_slots(+TeacherID, +Session, -AlternativeSlots)
find_alternative_teachers(+SubjectID, +SlotID, +CurrentTeacherID, -AlternativeTeachers)
```

### Feature 3: Scenario Simulation
```prolog
simulate_scenario(+ScenarioType, +Parameters, -NewTimetable)
mark_teacher_unavailable(+TeacherID, +Days, +Timetable, -AffectedSessions)
reassign_sessions(+Sessions, +CurrentTimetable, -FinalTimetable)
compare_scenarios(+Scenario1, +Scenario2, -Comparison)
```

### Feature 4: Quality Scoring
```prolog
calculate_quality_score(+Timetable, -Score)
hard_constraint_score(+Timetable, -Score)
workload_balance_score(+Timetable, -Score)
room_utilization_score(+Timetable, -Score)
schedule_compactness_score(+Timetable, -Score)
quality_breakdown(+Timetable, -Breakdown)
```

### Feature 5: Recommendations
```prolog
recommend_improvements(+Timetable, -Recommendations)
find_improvement_opportunity(+Timetable, -Recommendation)
apply_recommendation(+Recommendation, -UpdatedTimetable)
calculate_improvement_impact(+Details, -Impact)
```

### Feature 6: Heatmaps
```prolog
calculate_utilization(+ResourceType, +ResourceID, -Percentage)
generate_room_heatmap(-HeatmapData)
generate_teacher_heatmap(-HeatmapData)
generate_timeslot_heatmap(-HeatmapData)
```

### Feature 7: Search Statistics
```prolog
initialize_search_stats
increment_stat(+StatName)
get_search_statistics(-Stats)
solve_csp_with_stats(+Sessions, +Matrix, -Solution)
```

### Feature 8: Multiple Solutions
```prolog
generate_top_timetables(+N, -RankedTimetables)
generate_multiple_solutions(+Sessions, +EmptyMatrix, +N, -Solutions)
rank_solutions_by_quality(+Solutions, -RankedSolutions)
compare_timetables(+Timetable1, +Timetable2, -Comparison)
```

### Feature 9: Constraint Sliders
```prolog
set_constraint_weight(+ConstraintType, +Weight)
get_constraint_weight(+ConstraintType, -Weight)
calculate_weighted_soft_score(+Timetable, -TotalScore)
generate_with_custom_weights(+Weights, -Timetable)
```

### Feature 10: Real-Time Validation
```prolog
validate_teacher_input(+TeacherData, -ValidationResult)
validate_subject_input(+SubjectData, -ValidationResult)
validate_room_input(+RoomData, -ValidationResult)
check_assignment_feasibility(+Assignment, -FeasibilityResult)
```

## Frontend Components by Feature

### Feature 1: XAI
- Modal: `#explanation-modal`
- Container: `#explanation-steps`
- Function: `showDetailedExplanation(assignment)`

### Feature 2: Conflict Resolution
- Panel: `#conflict-suggestions-panel`
- List: `#conflict-list`
- Function: `loadConflictSuggestions()`, `applyFix(suggestion)`

### Feature 3: Scenario Simulation
- Section: `#scenario-section`
- Controls: `.scenario-controls`
- Function: `simulateScenario(type, params)`, `displayScenarioComparison()`

### Feature 4: Quality Scoring
- Display: `#quality-display`
- Circle: `.quality-score-circle`
- Function: `loadQualityScore()`, `displayQualityScore()`

### Feature 5: Recommendations
- Panel: `#recommendations-panel`
- List: `#recommendations-list`
- Function: `loadRecommendations()`, `applyRecommendation(rec)`

### Feature 6: Heatmaps
- Section: `#heatmap-section`
- Display: `#heatmap-display`
- Function: `loadHeatmap(type)`, `displayHeatmap(type, data)`

### Feature 7: Search Statistics
- Panel: `#search-stats-panel`
- Display: `#search-stats-display`
- Function: `loadSearchStatistics()`, `displaySearchStatistics()`

### Feature 8: Multiple Solutions
- Panel: `#multiple-solutions-panel`
- List: `#solutions-list`
- Function: `generateMultipleTimetables(count)`, `selectTimetable()`

### Feature 9: Constraint Sliders
- Panel: `#constraint-weights-panel`
- Sliders: `.constraint-slider`
- Function: `applyWeights()`, `regenerateWithWeights()`

### Feature 10: Real-Time Validation
- Feedback: `.validation-feedback`
- Forms: All input forms
- Function: `validateTeacherForm()`, `displayValidationFeedback()`

## API Endpoints Summary

| Feature | Endpoint | Method | Purpose |
|---------|----------|--------|---------|
| 1 | `/api/explain_detailed` | POST | Get XAI explanation |
| 2 | `/api/suggest_fixes` | GET | Get conflict suggestions |
| 2 | `/api/apply_fix` | POST | Apply a suggested fix |
| 3 | `/api/simulate` | POST | Simulate scenario |
| 3 | `/api/compare_scenarios` | POST | Compare scenarios |
| 4 | `/api/quality_score` | GET | Get quality score |
| 5 | `/api/recommendations` | GET | Get recommendations |
| 5 | `/api/apply_recommendation` | POST | Apply recommendation |
| 6 | `/api/heatmap/rooms` | GET | Room heatmap data |
| 6 | `/api/heatmap/teachers` | GET | Teacher heatmap data |
| 6 | `/api/heatmap/timeslots` | GET | Timeslot heatmap data |
| 7 | `/api/search_stats` | GET | Search statistics |
| 8 | `/api/generate_multiple` | POST | Generate N solutions |
| 8 | `/api/compare_timetables` | POST | Compare timetables |
| 9 | `/api/constraint_weights` | GET | Get current weights |
| 9 | `/api/set_weights` | POST | Set constraint weights |
| 9 | `/api/generate_with_weights` | POST | Generate with weights |
| 10 | `/api/validate/teacher` | POST | Validate teacher data |
| 10 | `/api/validate/subject` | POST | Validate subject data |
| 10 | `/api/validate/room` | POST | Validate room data |
| 10 | `/api/validate/assignment` | POST | Check assignment feasibility |

## Implementation Checklist

### Backend
- [ ] Create 10 new module files
- [ ] Implement all predicates
- [ ] Add API endpoints to api_server.pl
- [ ] Write unit tests for each module
- [ ] Write property-based tests
- [ ] Test integration with core system

### Frontend
- [ ] Add HTML sections for each feature
- [ ] Add CSS styling
- [ ] Implement JavaScript functions
- [ ] Add event listeners
- [ ] Test UI interactions
- [ ] Test API integration

### Documentation
- [ ] Update design.md with references
- [ ] Document all new predicates
- [ ] Document all new API endpoints
- [ ] Create user guide
- [ ] Create developer guide
- [ ] Add examples and screenshots

### Testing
- [ ] 10 new correctness properties
- [ ] Property-based tests (100+ iterations each)
- [ ] Integration tests
- [ ] Performance tests
- [ ] User acceptance tests

## Performance Targets

| Feature | Target Response Time | Max Memory |
|---------|---------------------|------------|
| XAI Explanation | < 100ms | < 10MB |
| Conflict Suggestions | < 300ms | < 20MB |
| Scenario Simulation | < 3s | < 50MB |
| Quality Score | < 150ms | < 10MB |
| Recommendations | < 400ms | < 30MB |
| Heatmap Generation | < 100ms | < 15MB |
| Search Statistics | < 50ms | < 5MB |
| Multiple Solutions | < 15s | < 100MB |
| Constraint Weights | < 100ms | < 10MB |
| Real-Time Validation | < 50ms | < 5MB |

## Demo Script for Academic Presentation

1. **Start**: Show basic timetable generation
2. **Feature 4**: Display quality score (92/100)
3. **Feature 1**: Click cell → show XAI explanation
4. **Feature 7**: Show search statistics (nodes, backtracks)
5. **Feature 6**: Display room utilization heatmap
6. **Feature 2**: Introduce conflict → show smart suggestions
7. **Feature 5**: Show AI recommendations for improvement
8. **Feature 9**: Adjust constraint sliders → regenerate
9. **Feature 8**: Generate 3 options → compare quality
10. **Feature 3**: Simulate teacher absence → show adaptation
11. **Feature 10**: Add new teacher → show real-time validation

## Key Selling Points

1. **Transparency**: XAI shows WHY decisions were made
2. **Intelligence**: Smart suggestions, not just detection
3. **Robustness**: Handles real-world disruptions
4. **Quality**: Measurable, multi-objective optimization
5. **Advisory**: Proactive recommendations
6. **Visual**: Intuitive heatmap visualizations
7. **Transparent**: Search process visibility
8. **Choice**: Multiple solutions to choose from
9. **Customizable**: User-controlled priorities
10. **Proactive**: Real-time validation prevents errors

## Academic Value

This project demonstrates:
- **10 MFAI concepts** (Linear Algebra, FOL, Inference, CSP, Probability, XAI, Decision Support, Multi-Objective, Customization, Proactive AI)
- **57 correctness properties** (47 core + 10 advanced)
- **Property-based testing** (5700+ test iterations)
- **Real-world application** (practical scheduling problem)
- **Cutting-edge AI** (XAI, decision support, adaptability)
- **Production-ready** (security, performance, extensibility)

This makes it an exemplary MFAI project suitable for top grades and academic publication.

