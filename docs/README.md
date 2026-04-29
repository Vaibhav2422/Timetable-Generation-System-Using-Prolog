# AI-Based Timetable Generation System

An intelligent timetable scheduling system using Constraint Satisfaction Problems (CSP),
First Order Logic, and Probabilistic Reasoning to automatically generate valid college timetables.

## Features

- Automated timetable generation using CSP with backtracking and forward checking
- First Order Logic knowledge base with Prolog inference engine
- Matrix-based timetable representation (Linear Algebra)
- Probabilistic reliability estimation for schedule robustness
- Conflict detection with detailed explanations (Explainable AI)
- Multiple timetable alternatives with quality scoring
- Web-based interface for resource management and visualization
- RESTful API for frontend-backend communication
- Export functionality (JSON, CSV, text)
- Advanced analytics: heatmaps, constraint graphs, scenario simulation
- Natural language query interface
- Conflict prediction and intelligent repair suggestions

## System Requirements

- SWI-Prolog 8.x or higher
- Modern web browser (Chrome, Firefox, Safari, Edge)
- Operating System: Windows, macOS, or Linux

## Installation

### Installing SWI-Prolog

#### Windows

1. Download the installer from https://www.swi-prolog.org/download/stable
2. Run the installer and follow the installation wizard
3. Optionally choose "Add SWI-Prolog to PATH" during installation
4. Verify installation:
   ```
   "C:\Program Files\swipl\bin\swipl.exe" --version
   ```

#### macOS

```bash
# Using Homebrew (recommended)
brew install swi-prolog

# Verify
swipl --version
```

#### Linux (Ubuntu/Debian)

```bash
sudo apt-get update && sudo apt-get install swi-prolog
swipl --version
```

## Project Structure

```
ai-timetable-generation/
├── backend/                    # Prolog backend modules
│   ├── knowledge_base.pl       # FOL facts and rules (teachers, subjects, rooms)
│   ├── matrix_model.pl         # Matrix operations (Linear Algebra)
│   ├── constraints.pl          # Hard and soft constraint definitions
│   ├── csp_solver.pl           # CSP backtracking search with heuristics
│   ├── probability_module.pl   # Reliability calculations
│   ├── timetable_generator.pl  # Main generation orchestration
│   ├── api_server.pl           # HTTP REST API server
│   ├── logging.pl              # Logging utilities
│   ├── conflict_resolver.pl    # Conflict repair suggestions
│   ├── recommendation_engine.pl# Scheduling recommendations
│   ├── multi_solution_generator.pl # Multiple timetable alternatives
│   ├── scenario_simulator.pl   # What-if scenario analysis
│   ├── nl_query.pl             # Natural language query interface
│   ├── heatmap_generator.pl    # Resource utilization heatmaps
│   ├── constraint_graph.pl     # Constraint relationship visualization
│   ├── complexity_analyzer.pl  # Problem complexity metrics
│   ├── conflict_predictor.pl   # Predictive conflict detection
│   ├── pattern_analyzer.pl     # Schedule pattern analysis
│   ├── quality_scorer.pl       # Timetable quality scoring
│   ├── genetic_optimizer.pl    # Genetic algorithm optimization
│   ├── learning_module.pl      # Adaptive learning from feedback
│   └── testing.pl              # Unit + property-based test suite
├── frontend/                   # Web interface
│   ├── index.html              # Main HTML structure
│   ├── style.css               # Styling and layout
│   └── script.js               # Frontend logic and API calls
├── data/
│   └── dataset.pl              # Example dataset (5 teachers, 8 subjects, 6 rooms)
├── docs/                       # Documentation
├── tests/                      # Additional integration/performance tests
├── main.pl                     # Entry point
└── config.pl                   # Configuration settings
```

## Quick Start

### 1. Start the Backend Server

```bash
# Windows (if swipl not on PATH)
"C:\Program Files\swipl\bin\swipl.exe" main.pl

# macOS/Linux
swipl main.pl
```

Expected output:
```
% Loading modules...
% Knowledge base loaded
% Server started on http://localhost:8080
% Ready to accept requests
```

### 2. Access the Web Interface

Open your browser and go to: `http://localhost:8080`

### 3. Generate Your First Timetable

1. The system loads example data automatically from `data/dataset.pl`
2. Click "Generate Timetable" to run the CSP solver
3. View the generated timetable grid
4. Check the reliability score (target: > 0.85)
5. Click any cell to see the AI explanation for that assignment
6. Use "Detect Conflicts" to verify constraint satisfaction
7. Export via the buttons at the bottom (JSON, CSV, or text)

## Example Dataset

The bundled `data/dataset.pl` includes:

| Resource | Count | Details |
|----------|-------|---------|
| Teachers | 5 | Dr. Alice Johnson, Prof. Bob Smith, Dr. Carol Williams, Mr. David Brown, Ms. Emma Davis |
| Subjects | 8 | Data Structures, Algorithms, DB Systems, OS, Networks, Software Eng, DB Lab, Networks Lab |
| Rooms | 6 | 4 classrooms (Room 101, 102, 103, 201) + 2 labs (Lab A, Lab B) |
| Time Slots | 30 | Mon–Fri, 6 periods/day (9:00–16:00) |
| Classes | 3 | CS-A, CS-B, CS-C |

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/resources` | Submit teachers, subjects, rooms, slots, classes |
| POST | `/api/generate` | Generate a new timetable |
| GET | `/api/timetable` | Retrieve current timetable |
| GET | `/api/reliability` | Get reliability score |
| POST | `/api/explain` | Get AI explanation for an assignment |
| GET | `/api/conflicts` | Detect all conflicts |
| POST | `/api/repair` | Get repair suggestions for conflicts |
| GET | `/api/analytics` | Resource utilization statistics |
| GET | `/api/export?format=json\|csv\|text` | Export timetable |
| POST | `/api/multi_generate` | Generate multiple alternative timetables |
| POST | `/api/simulate` | Run what-if scenario simulation |
| POST | `/api/nl_query` | Natural language query |
| GET | `/api/heatmap` | Resource utilization heatmap |
| GET | `/api/constraint_graph` | Constraint relationship graph |
| GET | `/api/complexity` | Problem complexity analysis |
| POST | `/api/predict_conflicts` | Predict potential conflicts |
| GET | `/api/recommendations` | Get scheduling recommendations |

See `docs/ARCHITECTURE.md` for full request/response examples.

## Configuration

Edit `config.pl` to customize behavior:

```prolog
server_port(8080).           % HTTP port
log_level(info).             % debug | info | warning | error
max_search_nodes(10000).     % CSP node limit
search_timeout(300).         % seconds before timeout
teacher_availability_prob(0.95).
room_availability_prob(0.98).
class_occurrence_prob(0.99).
```

## Running Tests

```bash
# Windows
"C:\Program Files\swipl\bin\swipl.exe" -g run_all_tests -t halt backend/testing.pl

# macOS/Linux
swipl -g run_all_tests -t halt backend/testing.pl
```

Expected output: 80 tests pass (33 unit + 47 property-based tests).

## Troubleshooting

**Server won't start**
- Verify SWI-Prolog is installed and the path is correct
- Check if port 8080 is already in use (change `server_port` in `config.pl`)
- Run with `log_level(debug)` for verbose output

**Timetable generation fails or times out**
- Ensure teachers are qualified for their assigned subjects in `knowledge_base.pl`
- Verify room types match subject types (theory → classroom, lab → lab room)
- Reduce problem size or increase `max_search_nodes` in `config.pl`
- Check that there are enough time slots for all required sessions

**Cannot access web interface**
- Confirm the server started successfully (look for "Server started" message)
- Try `http://127.0.0.1:8080` instead of `localhost`
- Check firewall/antivirus settings

**Tests fail**
- Ensure you run tests from the project root directory
- Verify all backend `.pl` files are present in `backend/`

## Known Limitations

- Data is stored in-memory; restarting the server clears all data
- PDF export is not implemented (JSON, CSV, and text are available)
- Single-threaded CSP solver; large problems (10+ classes) may be slow
- Natural language query supports a limited set of query patterns
- No user authentication or multi-user support

## Mathematical Foundations (MFAI)

| Concept | Implementation |
|---------|----------------|
| Linear Algebra | Matrix-based timetable with indexing/scanning operations |
| Propositional Logic | Boolean constraint expressions |
| First Order Logic | Predicates with variables and quantifiers in knowledge base |
| Logical Inference | Backward chaining via Prolog inference engine |
| Constraint Satisfaction | CSP with backtracking, forward checking, MRV/Degree/LCV heuristics |
| Probabilistic Reasoning | Reliability via conditional probabilities |

## License

Developed for educational purposes as part of the Mathematical Foundations of AI course.
