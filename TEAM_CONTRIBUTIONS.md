# Team Contributions — AI-Based Timetable Generation System

**Course Project | End Semester Review**
**Academic Year: 2025–26 | Semester: 4**
**Department: Artificial Intelligence and Data Science**

---

## Team Members

| # | Name | Role |
|---|------|------|
| 1 | **Vaibhav Hade** | Group Leader |
| 2 | **Omkar Ghanure** | Assistant Group Leader |
| 3 | **Satyajeet Ghadge** | Member |
| 4 | **Aaryan Giri** | Member |
| 5 | **Onkar Gawade** | Member |

---

## 1. Vaibhav Hade — Group Leader

**Role:** Project Lead, System Architect, Documentation Head

### Responsibilities
- Overall project planning, timeline management, and team coordination
- System architecture design — 3-tier structure (Frontend / REST API / Prolog Engine)
- Workflow design: resource submission → CSP solving → timetable rendering pipeline
- Critical thinking: constraint formulation, hard vs soft constraint classification
- API contract design: endpoint definitions, request/response schemas
- Integration of all modules into a working end-to-end system
- Bug fixing: CORS duplicate header issue, CSP domain initialization for tutorial subjects
- Final testing, deployment guide, and submission preparation

### Files Owned
| File | Description |
|------|-------------|
| `design.md` | Full system design document |
| `requirements.md` | Project requirements specification |
| `task.md` | Implementation task breakdown |
| `config.pl` | Server configuration (port, timeouts, weights) |
| `backend/api_server.pl` | Complete REST API server — all 50+ endpoints |
| `main.pl` | Application entry point |
| `docs/ARCHITECTURE.md` | System architecture documentation |
| `docs/TECHNICAL_REPORT.md` | Technical report |
| `docs/REPORT.md` | Project report |
| `docs/ABSTRACT.md` | Project abstract |
| `docs/OBJECTIVES.md` | Project objectives |
| `TEAM_CONTRIBUTIONS.md` | This file |
| `PROJECT_SETUP.md` | Setup and installation guide |
| `PROJECT_RUNNING_GUIDE.md` | How to run the project |
| `STARTUP_GUIDE.md` | Quick start guide |

---

## 2. Omkar Ghanure — Assistant Group Leader

**Role:** Core Prolog Engine Developer, CSP Solver

### Responsibilities
- Designed and implemented the CSP (Constraint Satisfaction Problem) solver
- Implemented backtracking search with forward checking and MRV/Degree/LCV heuristics
- Domain initialization and pruning logic
- Matrix model for timetable representation
- Timetable generator — session scheduling, slot assignment
- Knowledge base design: teacher, subject, room, timeslot, class facts and rules
- Fixed tutorial-type subject domain bug (empty domain detection)

### Files Owned
| File | Description |
|------|-------------|
| `backend/csp_solver.pl` | CSP solver with backtracking + forward checking |
| `backend/timetable_generator.pl` | Main timetable generation logic |
| `backend/matrix_model.pl` | Timetable matrix data structure |
| `backend/knowledge_base.pl` | Facts, rules, qualified/2, suitable_room/2 |
| `backend/constraints.pl` | Hard and soft constraint checking |
| `backend/dynamic_constraints.pl` | Runtime constraint modification |
| `backend/realtime_validator.pl` | Real-time constraint validation |
| `backend/CSP_SOLVER_SUMMARY.md` | CSP solver documentation |
| `backend/CONSTRAINTS_MODULE_SUMMARY.md` | Constraints module documentation |
| `backend/test_csp_solver.pl` | CSP solver unit tests |
| `backend/test_csp_properties.pl` | CSP property-based tests |
| `backend/test_timetable_generator.pl` | Timetable generator tests |
| `backend/test_timetable_properties.pl` | Timetable property tests |
| `backend/test_timetable_integration.pl` | Integration tests |
| `backend/test_matrix_model.pl` | Matrix model tests |
| `data/dataset.pl` | Sample dataset for testing |

---

## 3. Satyajeet Ghadge — Member

**Role:** AI/ML Modules Developer, Probability & Analytics

### Responsibilities
- Probabilistic reasoning module — teacher/room availability probability
- Reliability scoring for generated timetables
- Conflict prediction before generation (pre-generation risk analysis)
- Conflict detection and resolution after generation
- Quality scoring system (hard constraint score, workload balance, compactness)
- XAI (Explainable AI) module — explaining why assignments were made
- Genetic Algorithm optimizer for timetable improvement

### Files Owned
| File | Description |
|------|-------------|
| `backend/probability_module.pl` | Probabilistic reasoning, reliability scoring |
| `backend/conflict_predictor.pl` | Pre-generation conflict risk analysis |
| `backend/conflict_resolver.pl` | Post-generation conflict detection and repair |
| `backend/quality_scorer.pl` | Timetable quality scoring |
| `backend/xai_explainer.pl` | Explainable AI — assignment explanations |
| `backend/genetic_optimizer.pl` | Genetic Algorithm optimization |
| `backend/complexity_analyzer.pl` | Problem complexity analysis |
| `backend/constraint_graph.pl` | Constraint dependency graph |
| `backend/PROBABILITY_MODULE_IMPLEMENTATION.md` | Probability module documentation |
| `backend/test_probability.pl` | Probability module tests |
| `backend/test_probability_properties.pl` | Probability property tests |
| `backend/test_probability_integration.pl` | Probability integration tests |
| `backend/test_constraints.pl` | Constraint tests |
| `backend/test_constraints_simple.pl` | Simple constraint tests |

---

## 4. Aaryan Giri — Member

**Role:** Advanced Features Developer, Analytics & Scenarios

### Responsibilities
- Multi-solution generation — generate and rank multiple timetable alternatives
- Scenario simulation — what-if analysis (teacher absent, room unavailable)
- Multi-scenario comparison and analysis
- Heatmap generation for resource utilization visualization
- Search statistics collection and visualization
- Recommendation engine — AI suggestions to improve timetable quality
- Learning module — learns from past timetables to improve future scheduling
- Pattern analyzer — discovers scheduling patterns
- Version manager — save, load, compare, rollback timetable versions

### Files Owned
| File | Description |
|------|-------------|
| `backend/multi_solution_generator.pl` | Generate multiple ranked timetable solutions |
| `backend/scenario_simulator.pl` | What-if scenario simulation |
| `backend/multi_scenario_analyzer.pl` | Compare multiple scenarios |
| `backend/heatmap_generator.pl` | Resource utilization heatmaps |
| `backend/search_statistics.pl` | CSP search statistics collection |
| `backend/recommendation_engine.pl` | AI-powered improvement recommendations |
| `backend/learning_module.pl` | Machine learning from past timetables |
| `backend/pattern_analyzer.pl` | Scheduling pattern discovery |
| `backend/version_manager.pl` | Timetable version control |
| `backend/interactive_editor.pl` | Drag-and-drop timetable editing |
| `backend/nl_query.pl` | Natural language query interface |
| `backend/test_api_integration.pl` | API integration tests |
| `backend/test_api_properties.pl` | API property-based tests |
| `backend/test_api_server.pl` | API server tests |

---

## 5. Onkar Gawade — Member

**Role:** Frontend Developer, UI/UX, Testing

### Responsibilities
- Complete frontend UI — HTML structure, CSS styling, JavaScript logic
- Resource management forms (teachers, subjects, rooms, timeslots, classes)
- Timetable visualization grid (Day × Period layout)
- All API integration via fetch() — resources, generate, conflicts, analytics
- Export functionality — CSV, JSON, PDF
- Navigation, section switching, notifications system
- Logging module for backend request/response tracking
- Property-based tests for frontend behavior
- Integration and concurrent tests

### Files Owned
| File | Description |
|------|-------------|
| `frontend/index.html` | Complete frontend HTML |
| `frontend/script.js` | All frontend JavaScript (5000+ lines) |
| `frontend/style.css` | Complete CSS styling |
| `backend/logging.pl` | HTTP request/response logging module |
| `backend/LOGGING_MODULE_SUMMARY.md` | Logging documentation |
| `backend/test_logging.pl` | Logging unit tests |
| `backend/test_logging_integration.pl` | Logging integration tests |
| `backend/verify_logging_task.pl` | Logging verification |
| `backend/testing.pl` | Core testing utilities |
| `tests/property_test_api_base_url.ps1` | Frontend property test |
| `tests/property_test_example_dataset_counts.ps1` | Dataset count test |
| `tests/property_test_export_csv_non_empty.ps1` | Export test |
| `tests/property_test_fix_issues_no_duplicates.ps1` | Fix issues test |
| `tests/property_test_resource_badge_count.ps1` | Badge count test |
| `tests/property_test_single_active_section.ps1` | Navigation test |
| `tests/integration_test.pl` | Full integration tests |
| `tests/concurrent_test.pl` | Concurrent request tests |
| `tests/performance_test.pl` | Performance tests |
| `docs/USER_GUIDE.md` | End-user documentation |
| `docs/DEVELOPER_GUIDE.md` | Developer documentation |
| `docs/SYSTEM_GUIDE.md` | System guide |
| `docs/DEPLOYMENT.md` | Deployment instructions |

---

## Module Summary

| Module | Technology | Owner |
|--------|-----------|-------|
| REST API Server | SWI-Prolog HTTP | Vaibhav Hade |
| CSP Solver + Backtracking | Prolog | Omkar Ghanure |
| Timetable Generator | Prolog | Omkar Ghanure |
| Knowledge Base + Constraints | Prolog | Omkar Ghanure |
| Probability + Reliability | Prolog | Satyajeet Ghadge |
| Conflict Prediction + Resolution | Prolog | Satyajeet Ghadge |
| Quality Scorer + XAI | Prolog | Satyajeet Ghadge |
| Genetic Algorithm | Prolog | Satyajeet Ghadge |
| Multi-Solution + Scenarios | Prolog | Aaryan Giri |
| Heatmap + Analytics | Prolog | Aaryan Giri |
| Recommendations + Learning | Prolog | Aaryan Giri |
| Version Manager | Prolog | Aaryan Giri |
| Frontend UI + JavaScript | HTML/CSS/JS | Onkar Gawade |
| Logging + Testing | Prolog/PowerShell | Onkar Gawade |
| System Design + Docs | Markdown | Vaibhav Hade |

---

## Technology Stack

- **Backend Logic:** SWI-Prolog 10.0 (Constraint Logic Programming)
- **API Layer:** SWI-Prolog HTTP Server (port 8081)
- **Frontend:** HTML5, CSS3, Vanilla JavaScript (ES6+)
- **Frontend Server:** Python HTTP Server (port 3000)
- **Algorithm:** CSP with Backtracking, Forward Checking, MRV/Degree/LCV heuristics
- **AI Features:** Genetic Algorithm, Probabilistic Reasoning, XAI, NLP Query
- **Testing:** SWI-Prolog PLUnit, PowerShell Property-Based Tests

---

## Key Technical Contributions (For Professor Review)

### Critical Prolog Predicates
| Predicate | File | Owner |
|-----------|------|-------|
| `generate_timetable/1` | `timetable_generator.pl` | Omkar Ghanure |
| `solve_csp/3` | `csp_solver.pl` | Omkar Ghanure |
| `initialize_domains/2` | `csp_solver.pl` | Omkar Ghanure |
| `backtracking_search/4` | `csp_solver.pl` | Omkar Ghanure |
| `check_constraints/3` | `constraints.pl` | Omkar Ghanure |
| `suitable_room/2` | `knowledge_base.pl` | Omkar Ghanure |
| `qualified/2` | `knowledge_base.pl` | Omkar Ghanure |
| `schedule_reliability/2` | `probability_module.pl` | Satyajeet Ghadge |
| `predict_conflicts/2` | `conflict_predictor.pl` | Satyajeet Ghadge |
| `calculate_quality_score/2` | `quality_scorer.pl` | Satyajeet Ghadge |
| `explain_assignment/3` | `xai_explainer.pl` | Satyajeet Ghadge |
| `optimize_ga/3` | `genetic_optimizer.pl` | Satyajeet Ghadge |
| `generate_multiple/2` | `multi_solution_generator.pl` | Aaryan Giri |
| `simulate_scenario/3` | `scenario_simulator.pl` | Aaryan Giri |
| `start_server/1` | `api_server.pl` | Vaibhav Hade |
| `handle_generate/1` | `api_server.pl` | Vaibhav Hade |
| `reply_json_with_cors/1` | `api_server.pl` | Vaibhav Hade |

---

*Document prepared by Vaibhav Hade (Group Leader)*
*AI-Based Timetable Generation System — End Semester Review 2025-26*


---

## PPT Slide Distribution (End Semester Review)

> Total: 15 slides distributed across 5 members based on their module ownership.

---

### Vaibhav Hade — Group Leader
**Slides: 1, 2, 3, 6**

| Slide | Topic | Reason |
|-------|-------|--------|
| Slide 1 | Title Slide | Group leader presents the project |
| Slide 2 | Problem Statement | System design and critical thinking |
| Slide 3 | Objectives | Project scope and planning |
| Slide 6 | System Architecture / Methodology | Owns the full system design and API layer |

**Speaking points:** Introduce the team, explain the problem, present the architecture diagram, walk through the API flow.

---

### Omkar Ghanure — Assistant Group Leader
**Slides: 7, 8, 10**

| Slide | Topic | Reason |
|-------|-------|--------|
| Slide 7 | Constraint Modeling | Owns `constraints.pl` and CSP solver |
| Slide 8 | Prolog Code Walkthrough | Owns `csp_solver.pl`, `knowledge_base.pl`, `timetable_generator.pl` |
| Slide 10 | Challenges Faced | Faced and solved core CSP challenges |

**Speaking points:** Explain hard vs soft constraints, walk through the backtracking code, explain MRV/Degree/LCV heuristics, discuss domain initialization and empty domain detection.

---

### Satyajeet Ghadge — Member
**Slides: 5, 12**

| Slide | Topic | Reason |
|-------|-------|--------|
| Slide 5 | Technology Used | Owns probability and AI modules — can justify Prolog choice |
| Slide 12 | Mathematical Foundation | Owns probability module, CSP formulation, FOL predicates |

**Speaking points:** Explain why Prolog was chosen over GA/IP/Greedy, present the CSP formulation (variables, domains, constraints), explain SLD resolution and unification, present the FOL predicate mappings.

---

### Aaryan Giri — Member
**Slides: 9, 11**

| Slide | Topic | Reason |
|-------|-------|--------|
| Slide 9 | Sample Output / Results | Owns multi-solution generator and scenario simulator — can show results |
| Slide 11 | Comparison with Other Methods | Owns advanced features — can compare approaches |

**Speaking points:** Show the generated timetable output, explain the JSON API response, compare Prolog CSP vs Genetic Algorithm vs Integer Programming, highlight correctness guarantees.

---

### Onkar Gawade — Member
**Slides: 4, 13, 14, 15**

| Slide | Topic | Reason |
|-------|-------|--------|
| Slide 4 | Literature Survey | Frontend developer — presents research context |
| Slide 13 | Future Scope | Owns frontend — can speak to UI/UX improvements |
| Slide 14 | Conclusion | Summarizes the full system |
| Slide 15 | References | Closes the presentation |

**Speaking points:** Present the 4 base papers and their gaps, explain future enhancements (GUI, hybrid AI, NLP), summarize key achievements, present all references.

---

### Quick Reference Table

| Slide | Topic | Presenter |
|-------|-------|-----------|
| 1 | Title Slide | Vaibhav Hade |
| 2 | Problem Statement | Vaibhav Hade |
| 3 | Objectives | Vaibhav Hade |
| 4 | Literature Survey | Onkar Gawade |
| 5 | Technology Used | Satyajeet Ghadge |
| 6 | System Architecture | Vaibhav Hade |
| 7 | Constraint Modeling | Omkar Ghanure |
| 8 | Prolog Code Walkthrough | Omkar Ghanure |
| 9 | Sample Output / Results | Aaryan Giri |
| 10 | Challenges Faced | Omkar Ghanure |
| 11 | Comparison with Other Methods | Aaryan Giri |
| 12 | Mathematical Foundation | Satyajeet Ghadge |
| 13 | Future Scope | Onkar Gawade |
| 14 | Conclusion | Onkar Gawade |
| 15 | References | Onkar Gawade |

---

*PPT distribution aligned with module ownership — each member presents what they built.*
