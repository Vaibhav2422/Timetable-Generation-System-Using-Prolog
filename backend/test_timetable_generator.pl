:- use_module(library(plunit)).
:- use_module(timetable_generator).
:- use_module(knowledge_base).
:- use_module(matrix_model).
:- use_module(constraints).
:- use_module(csp_solver).

%% test_timetable_generator.pl
%% Unit tests for timetable_generator module
%% Tests main generation logic, explanations, conflict detection, repair, and formatting

:- begin_tests(timetable_generator).

%% ============================================================================
%% Test Setup and Teardown
%% ============================================================================

setup_test_data :-
    % Add test teachers
    assertz(teacher(t1, 'Dr. Alice', [math, physics], 20, [1,2,3,4,5])),
    assertz(teacher(t2, 'Dr. Bob', [chemistry, biology], 20, [1,2,3,4,5])),
    
    % Add test subjects
    assertz(subject(math, 'Mathematics', 4, theory, 1)),
    assertz(subject(physics, 'Physics', 3, theory, 1)),
    assertz(subject(chemistry, 'Chemistry', 3, lab, 1)),
    
    % Add test rooms
    assertz(room(r1, 'Room 101', 40, classroom)),
    assertz(room(r2, 'Room 102', 40, classroom)),
    assertz(room(lab1, 'Lab A', 30, lab)),
    
    % Add test time slots
    assertz(timeslot(1, monday, 1, '09:00', 1)),
    assertz(timeslot(2, monday, 2, '10:00', 1)),
    assertz(timeslot(3, monday, 3, '11:00', 1)),
    assertz(timeslot(4, tuesday, 1, '09:00', 1)),
    assertz(timeslot(5, tuesday, 2, '10:00', 1)),
    
    % Add test classes
    assertz(class(cs1, 'CS Year 1', [math, physics])),
    assertz(class(cs2, 'CS Year 2', [chemistry])).

cleanup_test_data :-
    retractall(teacher(_, _, _, _, _)),
    retractall(subject(_, _, _, _, _)),
    retractall(room(_, _, _, _)),
    retractall(timeslot(_, _, _, _, _)),
    retractall(class(_, _, _)).

%% ============================================================================
%% Subtask 8.1: Main Generation Logic Tests
%% Requirements: 7.1-7.7
%% ============================================================================

test(retrieve_resources_success, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    retrieve_resources(Teachers, Subjects, Rooms, Slots, Classes),
    length(Teachers, 2),
    length(Subjects, 3),
    length(Rooms, 3),
    length(Slots, 5),
    length(Classes, 2).

test(validate_resources_success, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    retrieve_resources(Teachers, Subjects, Rooms, Slots, Classes),
    validate_resources(Teachers, Subjects, Rooms, Slots, Classes).

test(validate_resources_empty_teachers, [setup(setup_test_data), cleanup(cleanup_test_data), fail]) :-
    retrieve_resources(_, Subjects, Rooms, Slots, Classes),
    validate_resources([], Subjects, Rooms, Slots, Classes).

test(create_sessions_correct_count, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    retrieve_resources(_, Subjects, _, _, Classes),
    create_sessions(Classes, Subjects, Sessions),
    length(Sessions, 3).  % cs1 has 2 subjects, cs2 has 1 subject

test(create_sessions_correct_structure, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    retrieve_resources(_, Subjects, _, _, Classes),
    create_sessions(Classes, Subjects, Sessions),
    member(session(cs1, math), Sessions),
    member(session(cs1, physics), Sessions),
    member(session(cs2, chemistry), Sessions).

test(validate_teacher_qualifications_valid, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    retrieve_resources(Teachers, Subjects, _, _, _),
    validate_teacher_qualifications(Teachers, Subjects).

test(validate_room_types_valid, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    retrieve_resources(_, _, Rooms, _, _),
    validate_room_types(Rooms).

test(validate_subject_requirements_valid, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    retrieve_resources(_, Subjects, _, _, _),
    validate_subject_requirements(Subjects).

%% ============================================================================
%% Subtask 8.2: Explanation and Conflict Detection Tests
%% Requirements: 9.1-9.5
%% ============================================================================

test(format_explanation_contains_details, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    Assignment = assigned(r1, cs1, math, t1, 1),
    format_explanation(Assignment, Explanation),
    atom(Explanation),
    sub_atom(Explanation, _, _, _, 'Dr. Alice'),
    sub_atom(Explanation, _, _, _, 'Mathematics'),
    sub_atom(Explanation, _, _, _, 'Room 101').

test(explain_assignment_success, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    Session = session(cs1, math),
    Assignment = assigned(r1, cs1, math, t1, 1),
    explain_assignment(Session, Assignment, Explanation),
    atom(Explanation).

test(detect_conflicts_no_conflicts, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    retrieve_resources(_, _, Rooms, Slots, _),
    create_empty_timetable(Rooms, Slots, Matrix),
    detect_conflicts(Matrix, Conflicts),
    Conflicts = [].

test(detect_conflicts_teacher_conflict, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    retrieve_resources(_, _, Rooms, Slots, _),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    % Create conflicting assignments (same teacher, same slot)
    set_cell(EmptyMatrix, 0, 0, assigned(r1, cs1, math, t1, 1), Matrix1),
    set_cell(Matrix1, 1, 0, assigned(r2, cs2, physics, t1, 1), Matrix2),
    detect_conflicts(Matrix2, Conflicts),
    member(teacher_conflict(t1, 1, _), Conflicts).

test(detect_conflicts_room_conflict, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    retrieve_resources(_, _, Rooms, Slots, _),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    % Create conflicting assignments (same room, same slot)
    set_cell(EmptyMatrix, 0, 0, assigned(r1, cs1, math, t1, 1), Matrix1),
    set_cell(Matrix1, 0, 1, assigned(r1, cs2, chemistry, t2, 2), Matrix2),
    set_cell(Matrix2, 0, 0, assigned(r1, cs2, physics, t2, 1), Matrix3),
    detect_conflicts(Matrix3, Conflicts),
    member(room_conflict(r1, 1, _), Conflicts).

test(find_conflict_identifies_teacher_conflict, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    retrieve_resources(_, _, Rooms, Slots, _),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    set_cell(EmptyMatrix, 0, 0, assigned(r1, cs1, math, t1, 1), Matrix1),
    set_cell(Matrix1, 1, 0, assigned(r2, cs2, physics, t1, 1), Matrix2),
    find_conflict(Matrix2, teacher_conflict(t1, 1, Sessions)),
    length(Sessions, Count),
    Count > 1.

%% ============================================================================
%% Subtask 8.3: Timetable Repair Tests
%% Requirements: 20.1-20.3
%% ============================================================================

test(identify_conflicting_assignments_teacher, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    retrieve_resources(_, _, Rooms, Slots, _),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    set_cell(EmptyMatrix, 0, 0, assigned(r1, cs1, math, t1, 1), Matrix1),
    set_cell(Matrix1, 1, 0, assigned(r2, cs2, physics, t1, 1), Matrix2),
    ConflictList = [teacher_conflict(t1, 1, [math, physics])],
    identify_conflicting_assignments(ConflictList, Matrix2, Assignments),
    length(Assignments, 2).

test(remove_assignments_success, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    retrieve_resources(_, _, Rooms, Slots, _),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    set_cell(EmptyMatrix, 0, 0, assigned(r1, cs1, math, t1, 1), Matrix1),
    ConflictingAssignments = [assigned(r1, cs1, math, t1, 1)],
    remove_assignments(ConflictingAssignments, Matrix1, PartialMatrix),
    get_cell(PartialMatrix, 0, 0, Cell),
    Cell = empty.

test(create_repair_sessions_correct, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    ConflictingAssignments = [
        assigned(r1, cs1, math, t1, 1),
        assigned(r2, cs2, physics, t1, 1)
    ],
    create_repair_sessions(ConflictingAssignments, RepairSessions),
    length(RepairSessions, 2),
    member(session(cs1, math), RepairSessions),
    member(session(cs2, physics), RepairSessions).

test(find_room_index_correct, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    find_room_index(r1, Index),
    Index = 0.

test(find_slot_index_correct, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    find_slot_index(1, Index),
    Index = 0.

%% ============================================================================
%% Subtask 8.4: Parsing and Formatting Tests
%% Requirements: 10.1-10.7
%% ============================================================================

test(json_to_prolog_identity, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    JSONData = [assignments-[]],
    json_to_prolog(JSONData, PrologData),
    PrologData = JSONData.

test(validate_parsed_data_valid, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    PrologData = [assignments-[assignment(r1, cs1, math, t1, 1)]],
    validate_parsed_data(PrologData).

test(validate_parsed_data_invalid_room, [setup(setup_test_data), cleanup(cleanup_test_data), fail]) :-
    PrologData = [assignments-[assignment(invalid_room, cs1, math, t1, 1)]],
    validate_parsed_data(PrologData).

test(format_timetable_json, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    retrieve_resources(_, _, Rooms, Slots, _),
    create_empty_timetable(Rooms, Slots, Matrix),
    format_timetable(Matrix, json, JSONOutput),
    JSONOutput = json(_).

test(format_timetable_text, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    retrieve_resources(_, _, Rooms, Slots, _),
    create_empty_timetable(Rooms, Slots, Matrix),
    format_timetable(Matrix, text, TextOutput),
    atom(TextOutput).

test(format_timetable_csv, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    retrieve_resources(_, _, Rooms, Slots, _),
    create_empty_timetable(Rooms, Slots, Matrix),
    format_timetable(Matrix, csv, CSVOutput),
    atom(CSVOutput).

test(matrix_to_json_structure, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    retrieve_resources(_, _, Rooms, Slots, _),
    create_empty_timetable(Rooms, Slots, Matrix),
    matrix_to_json(Matrix, json(JSONData)),
    member(rooms-RoomsJSON, JSONData),
    member(slots-SlotsJSON, JSONData),
    member(assignments-AssignmentsJSON, JSONData),
    is_list(RoomsJSON),
    is_list(SlotsJSON),
    is_list(AssignmentsJSON).

test(format_rooms_json_correct, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    Rooms = [room(r1, 'Room 101', 40, classroom)],
    format_rooms_json(Rooms, RoomsJSON),
    RoomsJSON = [json([id-r1, name-'Room 101', capacity-40, type-classroom])].

test(format_slots_json_correct, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    Slots = [timeslot(1, monday, 1, '09:00', 1)],
    format_slots_json(Slots, SlotsJSON),
    SlotsJSON = [json([id-1, day-monday, period-1, start_time-'09:00', duration-1])].

test(format_assignments_json_correct, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    Assignments = [assigned(r1, cs1, math, t1, 1)],
    format_assignments_json(Assignments, AssignmentsJSON),
    AssignmentsJSON = [json([room_id-r1, class_id-cs1, subject_id-math, teacher_id-t1, slot_id-1])].

test(matrix_to_text_contains_header, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    retrieve_resources(_, _, Rooms, Slots, _),
    create_empty_timetable(Rooms, Slots, Matrix),
    matrix_to_text(Matrix, TextOutput),
    sub_atom(TextOutput, _, _, _, 'Time/Room').

test(matrix_to_csv_contains_header, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    retrieve_resources(_, _, Rooms, Slots, _),
    create_empty_timetable(Rooms, Slots, Matrix),
    matrix_to_csv(Matrix, CSVOutput),
    sub_atom(CSVOutput, _, _, _, 'Time/Room').

test(format_cell_correct, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    format_cell(assigned(r1, cs1, math, t1, 1), FormattedCell),
    atom(FormattedCell),
    sub_atom(FormattedCell, _, _, _, 'CS Year 1'),
    sub_atom(FormattedCell, _, _, _, 'Mathematics').

test(format_csv_cell_quoted, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    format_csv_cell(assigned(r1, cs1, math, t1, 1), FormattedCell),
    atom(FormattedCell),
    sub_atom(FormattedCell, 0, 1, _, '"'),
    sub_atom(FormattedCell, _, 1, 0, '"').

%% ============================================================================
%% Round-Trip Property Test
%% Validates: Requirement 10.7
%% ============================================================================

test(parse_format_roundtrip, [setup(setup_test_data), cleanup(cleanup_test_data)]) :-
    % Create a simple timetable
    retrieve_resources(_, _, Rooms, Slots, _),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    set_cell(EmptyMatrix, 0, 0, assigned(r1, cs1, math, t1, 1), Matrix),
    
    % Format to JSON
    format_timetable(Matrix, json, JSONOutput),
    
    % Convert JSON to Prolog data
    JSONOutput = json(JSONData),
    
    % Parse back
    parse_timetable(JSONData, ParsedMatrix),
    
    % Verify assignments are preserved
    get_all_assignments(Matrix, OriginalAssignments),
    get_all_assignments(ParsedMatrix, ParsedAssignments),
    length(OriginalAssignments, OrigCount),
    length(ParsedAssignments, ParsedCount),
    OrigCount = ParsedCount.

:- end_tests(timetable_generator).

%% Run all tests
run_tests :-
    run_tests(timetable_generator).
