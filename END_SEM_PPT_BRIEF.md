# END SEMESTER REVIEW — PPT BRIEF
# Automated Timetable Generation Using Prolog

> **Instructions for Claude:** Use this document to create a PowerPoint presentation (12–15 slides). Each section below maps to one slide. Use the exact code snippets, data, and wording provided. Keep slides clean — bullet points, not paragraphs. Highlight code slides with monospace font. Add a flowchart/diagram on Slide 6.

---

## SLIDE 1 — Title Slide

- **Title:** Automated Timetable Generation Using Prolog
- **Subject:** Modern Foundations of AI (MFAI)
- **Subtitle:** End Semester Review Presentation
- **Topic:** Logic Programming, Constraint Satisfaction, and Intelligent Scheduling

---

## SLIDE 2 — Problem Statement

- Timetable generation is an **NP-hard combinatorial optimization problem**
- Manual scheduling in colleges is:
  - Time-consuming (avg. 10+ hours per cycle)
  - Error-prone (conflicts in teacher/room/time assignments)
  - Hard to update when changes occur
- Key constraints to satisfy simultaneously:
  - No teacher double-booking
  - No room double-booking
  - Teacher qualification matching
  - Room type compatibility (theory vs lab)
  - Weekly hour requirements per subject
  - Teacher availability windows
- Formal classification: **Constraint Satisfaction Problem (CSP)**

---

## SLIDE 3 — Objectives

- Design and implement an automated timetable generator using **SWI-Prolog**
- Model the scheduling problem as a **CSP with hard and soft constraints**
- Apply **backtracking search with intelligent heuristics** (MRV, Degree, LCV)
- Use **First Order Logic (FOL)** to represent scheduling knowledge
- Expose the system via a **REST API** for frontend integration
- Generate conflict-free timetables with explanations for assignments
- Support timetable repair when conflicts are detected

**Scope:** University-level scheduling — teachers, subjects, rooms, timeslots, classes

---

## SLIDE 4 — Literature Survey (4 Base Papers)

### Paper 1: TRACE-CS (Vasileiou & Yeoh, 2025)
- Hybrid Logic + LLM system for explainable course scheduling
- Uses SAT encoding + Minimal Unsatisfiable Subsets (MUS) for explanations
- Achieves **100% explanation accuracy** vs 54.1% for GPT-4.1 alone
- **Gap addressed by our project:** SAT encoding maps directly to Prolog CLP; Prolog provides inherently transparent, traceable inference

### Paper 2: AutoTimely (Jadhav & Pansare, 2026)
- Genetic Algorithm + CSP hybrid for college timetabling
- Reduces scheduling time by **40%**, conflict rate below **2%**
- Validated on MIT ACS College, Pune
- **Gap addressed:** Their CSP layer is replaced in our project by Prolog's built-in CLP(FD) — more declarative and verifiable

### Paper 3: Fair HSSP (Kiyohara & Ishihata, 2024)
- Integer Programming approach to fair high school scheduling
- Introduces **envy-freeness** as a fairness constraint
- Zero envy violations across all test cases
- **Gap addressed:** IP constraints translate naturally to Prolog predicates; our system can extend to fairness rules

### Paper 4: Logic Programming in AI (Alazmi, 2024)
- Survey of Prolog, CLP, and ASP in AI applications
- Validates LP for scheduling, expert systems, NLP, robotics
- Documents CLP(FD) as ideal for timetabling
- **Gap addressed:** Directly validates our technology choice; our project provides the concrete Prolog timetabling case study this survey lacks

---

## SLIDE 5 — Technology Used

- **Language:** SWI-Prolog (Logic Programming)
- **Paradigm:** Constraint Logic Programming — CLP(FD)
- **Why Prolog over other approaches?**

| Approach | Strength | Weakness |
|---|---|---|
| Prolog / CLP | Declarative, backtracking built-in, readable rules | Scalability on huge datasets |
| Genetic Algorithm | Good for optimization | No correctness guarantee |
| Integer Programming | Mathematically rigorous | Hard to modify constraints |
| Greedy | Fast | Often suboptimal, no backtracking |

- **Prolog advantages for this problem:**
  - Horn clauses naturally encode scheduling rules
  - Built-in backtracking handles constraint violations automatically
  - CLP(FD) provides constraint propagation over finite domains
  - Transparent, auditable inference — every decision is traceable
- **Tools:** SWI-Prolog, HTTP library (api_server.pl), JSON integration

---

## SLIDE 6 — System Architecture / Methodology

**Flow:**
```
User / Frontend
      |
      v
REST API (api_server.pl)  <-- HTTP POST/GET
      |
      v
Timetable Generator (timetable_generator.pl)
      |
      +---> Knowledge Base (knowledge_base.pl)
      |         [Teachers, Subjects, Rooms, Timeslots, Classes as FOL facts]
      |
      +---> CSP Solver (csp_solver.pl)
      |         [Backtracking + MRV + Degree + LCV heuristics]
      |
      +---> Constraints (constraints.pl)
      |         [Hard constraints + Soft constraint scoring]
      |
      +---> Matrix Model (matrix_model.pl)
                [Rooms x Timeslots grid — timetable representation]
      |
      v
Output: JSON / Text / CSV timetable
```

**Key modules:**
- `knowledge_base.pl` — FOL facts and inference rules
- `csp_solver.pl` — Backtracking search engine
- `constraints.pl` — Hard and soft constraint checking
- `timetable_generator.pl` — Orchestration and formatting
- `api_server.pl` — REST API layer

---

## SLIDE 7 — Constraint Modeling

### Hard Constraints (must be satisfied — timetable is invalid if violated)

| Constraint | Predicate |
|---|---|
| No teacher double-booking | `check_teacher_no_conflict/3` |
| No room double-booking | `check_room_no_conflict/3` |
| Teacher must be qualified | `check_teacher_qualified/2` |
| Room type must match subject | `check_room_suitable/2` |
| Room capacity sufficient | `check_room_capacity/2` |
| Teacher must be available | `check_teacher_available/2` |

### Soft Constraints (preferences — affect quality score)

| Constraint | Predicate |
|---|---|
| Balanced teacher workload across days | `soft_balanced_workload/3` |
| Avoid late afternoon theory classes | `soft_avoid_late_theory/3` |
| Minimize gaps in student schedule | `soft_minimize_gaps/3` |

**Combined check:**
```prolog
check_all_hard_constraints(RoomID, ClassID, SubjectID, TeacherID, SlotID, Matrix) :-
    check_teacher_no_conflict(TeacherID, SlotID, Matrix),
    check_room_no_conflict(RoomID, SlotID, Matrix),
    check_teacher_qualified(TeacherID, SubjectID),
    check_room_suitable(RoomID, SubjectID),
    check_room_capacity(RoomID, ClassID),
    check_teacher_available(TeacherID, SlotID).
```

---

## SLIDE 8 — Prolog Code Walkthrough

### Knowledge Base — First Order Logic Facts & Rules
```prolog
% FACTS (ground instances)
teacher(t1, 'Dr. Smith', [math101, cs101], 20, [slot1, slot2, slot3]).
subject(math101, 'Calculus I', 4, theory, 1).
room(r101, 'Room 101', 50, classroom).
timeslot(slot1, monday, 1, '09:00', 1).
class(cs1a, 'CS Year 1 Section A', [math101, cs101]).

% RULES (logical inference)
% A teacher is qualified if the subject is in their qualified list
qualified(TeacherID, SubjectID) :-
    get_all_teachers(Teachers),
    member(teacher(TeacherID, _, QualifiedSubjects, _, _), Teachers),
    member(SubjectID, QualifiedSubjects).

% A room is suitable if its type is compatible with the session type
suitable_room(RoomID, SessionType) :-
    get_all_rooms(Rooms),
    member(room(RoomID, _, _, RoomType), Rooms),
    compatible_type(SessionType, RoomType).

compatible_type(theory, classroom).
compatible_type(lab, lab).
```

### CSP Solver — Backtracking with Heuristics
```prolog
% MRV Heuristic: select the session with the smallest domain
select_variable(Sessions, Domains, Selected, Remaining) :-
    findall(Count-Session,
            (member(Session, Sessions),
             get_domain(Session, Domains, D),
             length(D, Count)),
            Pairs),
    sort(Pairs, [_-Selected|_]),  % pick minimum domain size
    select(Selected, Sessions, Remaining).

% Forward Checking: prune conflicting values from remaining domains
conflicts_with(value(T1, R1, S1), _, value(T2, R2, S2)) :-
    (T1 = T2, S1 = S2) ;   % same teacher, same time
    (R1 = R2, S1 = S2).    % same room, same time
```

### Main Generation Entry Point
```prolog
generate_timetable(Timetable) :-
    retrieve_resources(Teachers, Subjects, Rooms, Slots, Classes),
    validate_resources(Teachers, Subjects, Rooms, Slots, Classes),
    create_sessions(Classes, Subjects, Sessions),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    solve_csp(Sessions, EmptyMatrix, Timetable),
    validate_timetable(Timetable).
```

**Backtracking logic:** Prolog automatically backtracks when `check_all_hard_constraints` fails — no explicit undo code needed. This is the power of logic programming.

---

## SLIDE 9 — Sample Output / Results

### Sample Knowledge Base Input
```
Teachers : Dr. Smith (Math, CS), Dr. Jones (Physics, Math)
Subjects : Calculus I (4h/week, theory), CS Lab (3h/week, lab)
Rooms    : Room 101 (50 seats, classroom), Lab 1 (30 seats, lab)
Timeslots: Monday–Friday, Periods 1–8 (09:00–17:00)
Classes  : CS Year 1 Section A, CS Year 1 Section B
```

### Generated Timetable (Text Format)
```
Time/Room     | Room 101              | Lab 1
--------------+-----------------------+----------------------
Mon Period 1  | CS1A: Calculus (Smith)| -
Mon Period 2  | CS1B: Calculus (Jones)| -
Tue Period 3  | -                     | CS1A: CS Lab (Smith)
Wed Period 1  | CS1A: Calculus (Smith)| -
```

### Constraint Satisfaction Verified
- Zero teacher conflicts
- Zero room conflicts
- All teacher qualifications matched
- All room types compatible
- Soft constraint score: 0.85 / 1.0

### API Response (JSON)
```json
{
  "status": "success",
  "assignments": [
    {"room": "r101", "class": "cs1a", "subject": "math101",
     "teacher": "t1", "slot": "slot1"}
  ]
}
```

---

## SLIDE 10 — Challenges Faced

- **Backtracking complexity:** With many sessions, the search space grows exponentially
  - Solution: MRV heuristic reduces branching factor significantly
  - Node limit set at 10,000 to prevent infinite loops

- **Domain initialization:** Generating valid (teacher, room, slot) tuples for each session
  - Solution: Domain caching with `assertz(domain_cache/2)` to avoid recomputation

- **Module system conflicts:** Prolog's multifile/dynamic declarations across modules
  - Solution: Used `user:` namespace prefix for cross-module fact access

- **Empty domain detection:** Forward checking must detect dead ends early
  - Solution: `has_empty_domain/1` check after every assignment before recursing

- **Scalability:** Large institutions with hundreds of sessions hit node limits
  - Solution: Degree heuristic + LCV ordering to minimize backtracking

- **API integration:** Bridging Prolog's term-based data with JSON
  - Solution: Custom `json_to_prolog/2` and `matrix_to_json/2` converters

---

## SLIDE 11 — Comparison with Other Methods

| Feature | Our Prolog/CLP | Genetic Algorithm (Paper 2) | Integer Programming (Paper 3) | Greedy |
|---|---|---|---|---|
| Correctness guarantee | Yes (hard constraints enforced) | No | Yes | No |
| Backtracking | Built-in | No | No | No |
| Explainability | High (traceable inference) | Low | Medium | Low |
| Soft constraints | Yes (scoring) | Yes (fitness function) | Yes (objective function) | No |
| Scalability | Medium | High | Medium | High |
| Code readability | High (declarative) | Medium | Low | High |
| Setup complexity | Low | High | High | Low |

**Why CLP is suitable here:**
- Scheduling is inherently a constraint problem — CLP is the natural fit
- Prolog's unification handles variable binding automatically
- Backtracking is free — no need to implement undo logic manually
- Rules are readable and match the problem domain directly

---

## SLIDE 12 — Mathematical Foundation

### CSP Formulation
- **Variables:** Sessions S = {session(ClassID, SubjectID)} for each class-subject pair
- **Domains:** D(s) = {value(TeacherID, RoomID, SlotID)} — all valid assignments
- **Constraints:** C = {no_teacher_conflict, no_room_conflict, qualified, suitable, available}
- **Goal:** Find assignment A: S → D such that all constraints in C are satisfied

### Complexity
- Timetable generation is **NP-hard** (proven by reduction from graph coloring)
- Brute force: O(|D|^|S|) — exponential in number of sessions
- With MRV + Forward Checking: practical polynomial-time performance on typical instances
- Node limit: 10,000 search nodes before declaring over-constrained

### How Prolog Handles It
- **SLD Resolution:** Prolog's inference engine uses Selective Linear Definite clause resolution
- **Unification:** Variables are bound during constraint checking — no explicit assignment code
- **Backtracking:** Automatic on constraint failure — Prolog's core mechanism
- **CLP(FD):** Constraint propagation reduces domains before search begins

### Key Predicates (FOL mapping)
```
∀t ∀s: qualified(t,s) ← teacher(t,_,subjects,_,_) ∧ s ∈ subjects
∀r ∀t: suitable_room(r,t) ← room(r,_,_,type) ∧ compatible_type(t,type)
∀t ∀s: teacher_available(t,s) ← teacher(t,_,_,_,avail) ∧ s ∈ avail
```

---

## SLIDE 13 — Future Scope

- **GUI Integration:** Connect the existing REST API to a full drag-and-drop timetable editor
- **Larger Datasets:** Optimize CSP solver for 500+ sessions using constraint propagation improvements
- **Hybrid AI:** Combine Prolog CSP with a Genetic Algorithm for multi-objective optimization
- **Fairness Constraints:** Implement envy-freeness (from Paper 3) as Prolog soft constraint rules
- **Natural Language Explanations:** Integrate an LLM (like Paper 1's TRACE-CS) to explain timetable decisions in plain English
- **Real-time Updates:** Support incremental re-scheduling when a teacher is absent or a room is unavailable
- **Probabilistic Scheduling:** Use ProbLog for uncertainty-aware scheduling (teacher absence probability)
- **Multi-semester Planning:** Extend the system to plan across full academic years

---

## SLIDE 14 — Conclusion

- Successfully implemented an **automated timetable generator in SWI-Prolog**
- The system models scheduling as a **CSP** and solves it using backtracking search with **MRV, Degree, and LCV heuristics**
- **First Order Logic** is used to represent teachers, subjects, rooms, and rules — making the knowledge base transparent and auditable
- **Hard constraints** (no conflicts, qualification, capacity) are enforced with 100% correctness
- **Soft constraints** (workload balance, time preferences) are scored to optimize quality
- The system exposes a **REST API** for frontend integration and supports JSON/text/CSV output
- Demonstrates that **Logic Programming is a natural, powerful fit** for constraint-based scheduling problems

**Key Takeaway:** Prolog's declarative nature, built-in backtracking, and CLP extensions make it uniquely suited for timetable generation — combining correctness guarantees with readable, maintainable code.

---

## SLIDE 15 — References

> **Instruction for Claude:** On this slide, make each reference a clickable hyperlink button. Books get a Google Books / publisher link. Papers get their arXiv/DOI link. Websites get their homepage. Style them as colored button-style hyperlinks so the slide looks interactive.

### 📄 Base Research Papers (with hyperlinks)

1. **TRACE-CS — Hybrid Logic + LLM Scheduling**
   Vasileiou & Yeoh, 2025
   🔗 https://arxiv.org/abs/2409.03671

2. **AutoTimely — Automated Timetable Generator**
   Jadhav & Pansare, IJARSCT 2026
   🔗 https://www.ijarsct.co.in

3. **Fair High School Course Scheduling (CSP + IP)**
   Kiyohara & Ishihata, 2024
   🔗 https://arxiv.org/abs/2408.12032

4. **Logic Programming for AI — Survey**
   Alazmi, Advances in Robotics & Automation, 2024
   🔗 https://doi.org/10.37421/2168-9695.2024.13.284

### 📚 Books (3–4, with hyperlinks)

5. **The Art of Prolog** — Sterling & Shapiro (MIT Press)
   🔗 https://mitpress.mit.edu/9780262691635/the-art-of-prolog/

6. **Artificial Intelligence: A Modern Approach** — Russell & Norvig (Chapter 6: CSP)
   🔗 https://aima.cs.berkeley.edu/

7. **Principles of Constraint Programming** — Apt (Cambridge University Press)
   🔗 https://www.cambridge.org/core/books/principles-of-constraint-programming/

8. **Programming with Constraints** — Marriott & Stuckey (MIT Press)
   🔗 https://mitpress.mit.edu/9780262133418/

### 🌐 Online Resources (with hyperlinks)

9. **SWI-Prolog Official Documentation**
   🔗 https://www.swi-prolog.org/pldoc/doc_for?object=manual

10. **SWI-Prolog CLP(FD) — Constraint Logic Programming over Finite Domains**
    🔗 https://www.swi-prolog.org/man/clpfd.html

11. **GeeksforGeeks — Constraint Satisfaction Problems in AI**
    🔗 https://www.geeksforgeeks.org/constraint-satisfaction-problems-csp-in-artificial-intelligence/

12. **Wikipedia — Timetabling Problem**
    🔗 https://en.wikipedia.org/wiki/Timetabling_problem

---

*End of PPT Brief — Feed this entire document to Claude to generate the PowerPoint presentation.*
