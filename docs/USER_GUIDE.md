# User Guide

## AI-Based Timetable Generation System

---

## Getting Started

### Step 1: Start the Server

Open a terminal and run:

```bash
# Windows (if swipl not on PATH)
"C:\Program Files\swipl\bin\swipl.exe" main.pl

# macOS / Linux
swipl main.pl
```

Wait for the message: `Server started on http://localhost:8080`

### Step 2: Open the Web Interface

Navigate to `http://localhost:8080` in your browser.

You will see the main navigation with these sections:
- Resources — enter teachers, subjects, rooms, time slots, classes
- Generate — run the timetable generator
- Timetable — view and interact with the generated timetable
- Analytics — view utilization stats, heatmaps, quality scores
- Advanced — scenarios, recommendations, multi-solution, NL queries

---

## Tutorial: Generating Your First Timetable

### 1. Add Resources

Click the "Resources" tab. You need to add five types of resources.

**Teachers**
Fill in the teacher form:
- Name: e.g. `Dr. Alice Johnson`
- Subjects they can teach: select from the list
- Max weekly hours: e.g. `20`
- Click "Add Teacher"

**Subjects**
- Name: e.g. `Data Structures`
- Type: `theory` or `lab`
- Hours per week: e.g. `3`
- Click "Add Subject"

**Rooms**
- Name: e.g. `Room 101`
- Type: `classroom` (for theory) or `lab` (for lab subjects)
- Capacity: e.g. `40`
- Click "Add Room"

**Time Slots**
- Day: Monday–Friday
- Period number and start/end time
- Click "Add Time Slot"

**Classes**
- Name: e.g. `CS-A`
- Size: number of students
- Subjects assigned to this class
- Click "Add Class"

Once all resources are added, click "Submit All Resources".

> Tip: The system comes with example data in `data/dataset.pl`. Start the server and click "Generate" without adding resources to use the example data.

### 2. Generate the Timetable

Click the "Generate" tab, then click "Generate Timetable".

The CSP solver will run. For the example dataset (3 classes, 8 subjects), this takes a few seconds.

You will see:
- "Generation successful" message
- Reliability score (e.g. 0.923 = 92.3% reliable)

### 3. View the Timetable

Click the "Timetable" tab to see the generated schedule as a grid.

- Rows = time slots (day + period)
- Columns = classes
- Each cell shows: subject name, teacher, room

**Click any cell** to see the AI explanation for why that assignment was made. The explanation includes:
- Which FOL rules were satisfied (teacher qualification, room suitability)
- Why this slot was chosen (availability, workload balance)
- Quality breakdown for this assignment

### 4. Check for Conflicts

Click "Detect Conflicts" to scan the timetable. If conflicts exist, they are highlighted in red with descriptions.

Common conflicts:
- Teacher double-booking: same teacher in two places at once
- Room double-booking: same room used by two classes simultaneously
- Qualification violation: teacher assigned to a subject they can't teach

### 5. Export the Timetable

Use the export buttons at the bottom of the Timetable section:
- JSON — machine-readable format for integration
- CSV — open in Excel or Google Sheets
- Text — plain text table for printing

---

## Advanced Features

### Conflict Repair Suggestions

If conflicts are detected, click "Load Suggestions" in the Conflicts panel.

The system suggests minimal changes to resolve each conflict, such as:
- Reassigning a session to a different time slot
- Swapping two assignments

Click "Apply Fix" to apply a suggestion automatically.

### Multiple Timetable Alternatives

In the "Advanced" tab, use "Multi-Solution Generator":
- Set the number of alternatives (e.g. 3)
- Click "Generate Alternatives"
- Compare quality scores and reliability across solutions
- Select the best one

### What-If Scenario Simulation

Use "Scenario Simulator" to test hypothetical changes:

| Scenario | Description |
|----------|-------------|
| Teacher Absence | Remove a teacher and see impact |
| Room Maintenance | Take a room offline |
| Extra Class | Add a new class section |
| Exam Week | Reduce available slots |

Select a scenario type, configure parameters, and click "Simulate". The system shows:
- How many assignments are affected
- Which conflicts arise
- Side-by-side comparison with the original timetable

### Recommendations

Click "Load Recommendations" to get proactive suggestions for improving the timetable, such as:
- Redistributing workload from overloaded teachers
- Moving theory classes away from late afternoon slots
- Reducing schedule gaps for students

Click "Preview" to see the before/after comparison, then "Apply" to accept.

### Natural Language Queries

In the "Advanced" tab, type a question in plain English:

Examples:
- `Who teaches CS-A on Monday?`
- `Which rooms are free on Friday period 3?`
- `How many hours does Dr. Alice teach this week?`
- `What subjects does CS-B have on Tuesday?`

### Heatmaps

View resource utilization as a color-coded heatmap:
- Teacher heatmap: which teachers are most/least utilized
- Room heatmap: which rooms are heavily booked
- Time slot heatmap: which periods are busiest

High intensity (dark color) = heavily used. Low intensity (light) = underutilized.

### Constraint Graph

Shows the constraint relationships between resources as a graph. Nodes are resources; edges represent constraints between them. Useful for understanding why certain assignments are difficult.

### Complexity Analysis

Shows metrics about the scheduling problem:
- Number of variables (sessions to assign)
- Domain size (possible assignments per session)
- Constraint density
- Estimated search space size

### Quality Score

After generation, the quality score panel shows a multi-dimensional breakdown:
- Workload balance (are teachers evenly loaded?)
- Schedule compactness (minimal gaps for students)
- Time preferences (theory classes in morning slots)
- Room utilization (rooms used efficiently)

Each dimension is scored 0–100. Overall score is the weighted average.

---

## FAQ

**Q: The timetable generation times out. What should I do?**
A: Increase `max_search_nodes` in `config.pl`, or reduce the problem size (fewer classes/subjects). Also verify that teachers are qualified for their subjects and rooms match subject types.

**Q: The reliability score is low (below 0.7). Is that a problem?**
A: A low score means the schedule is sensitive to disruptions (teacher absences, room issues). Consider adding backup teachers or reducing the number of sessions per teacher.

**Q: Can I save my timetable and reload it later?**
A: Currently, data is stored in memory and lost when the server restarts. Export to JSON before stopping the server, and re-import via the API if needed.

**Q: How do I add a new subject type (e.g. seminar)?**
A: Add the subject with type `theory` or `lab` (the two supported types). For seminars, use `theory` type with a classroom room.

**Q: The natural language query returns "I don't understand". What queries are supported?**
A: The NL query module supports patterns like "who teaches X", "what subjects does Y have", "which rooms are free on Z", and "how many hours does T teach". Complex or ambiguous queries may not be recognized.

**Q: Can I run multiple instances for different departments?**
A: Not currently — the system is single-instance. Run separate server instances on different ports for different departments.

---

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Close modal | Escape |
| Submit form | Enter |

---

## Troubleshooting

See the Troubleshooting section in `docs/README.md` for common issues and solutions.
