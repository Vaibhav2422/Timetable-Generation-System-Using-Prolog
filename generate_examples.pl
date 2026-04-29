% generate_examples.pl
% Standalone script to generate example output files from dataset.pl
%
% Usage:
%   Windows: "C:\Program Files\swipl\bin\swipl.exe" -g generate_all_examples -t halt generate_examples.pl
%   macOS/Linux: swipl -g generate_all_examples -t halt generate_examples.pl
%
% Outputs written to: docs/examples/

:- use_module(backend/logging).
:- use_module(backend/knowledge_base).
:- use_module(backend/matrix_model).
:- use_module(backend/constraints).
:- use_module(backend/csp_solver).
:- use_module(backend/probability_module).
:- use_module(backend/timetable_generator).

:- consult('data/dataset.pl').
:- consult('config.pl').

% ============================================================================
% Main entry point
% ============================================================================

generate_all_examples :-
    writeln('Generating example outputs...'),
    % Ensure output directory exists
    (exists_directory('docs/examples') -> true ; make_directory('docs/examples')),
    % Generate timetable
    writeln('  Running CSP solver...'),
    (   catch(generate_timetable(Timetable), Err,
              (format('  CSP error: ~w~n', [Err]), Timetable = []))
    ->  true
    ;   Timetable = []
    ),
    (   Timetable \= []
    ->  writeln('  Timetable generated successfully'),
        generate_json_output(Timetable),
        generate_csv_output(Timetable),
        generate_text_output(Timetable),
        generate_reliability_output(Timetable),
        generate_conflicts_output(Timetable)
    ;   writeln('  No timetable generated - writing empty example files')
    ),
    generate_dataset_summary,
    writeln('Done. Example files written to docs/examples/').

% ============================================================================
% JSON export
% ============================================================================

generate_json_output(Timetable) :-
    writeln('  Writing timetable.json...'),
    get_all_assignments(Timetable, Assignments),
    get_all_rooms(Rooms),
    get_all_timeslots(Slots),
    schedule_reliability(Timetable, Reliability),
    open('docs/examples/timetable.json', write, Stream),
    format(Stream, '{~n', []),
    format(Stream, '  "status": "ok",~n', []),
    length(Assignments, NA),
    format(Stream, '  "reliability": ~4f,~n', [Reliability]),
    format(Stream, '  "total_assignments": ~w,~n', [NA]),
    format(Stream, '  "rooms": [~n', []),
    write_rooms_json(Stream, Rooms),
    format(Stream, '  ],~n', []),
    format(Stream, '  "timeslots": [~n', []),
    write_slots_json(Stream, Slots),
    format(Stream, '  ],~n', []),
    format(Stream, '  "assignments": [~n', []),
    write_assignments_json(Stream, Assignments),
    format(Stream, '  ]~n', []),
    format(Stream, '}~n', []),
    close(Stream).

write_rooms_json(_, []).
write_rooms_json(Stream, [room(ID, Name, Cap, Type)]) :-
    format(Stream, '    {"id": "~w", "name": "~w", "capacity": ~w, "type": "~w"}~n',
           [ID, Name, Cap, Type]).
write_rooms_json(Stream, [room(ID, Name, Cap, Type)|Rest]) :-
    Rest \= [],
    format(Stream, '    {"id": "~w", "name": "~w", "capacity": ~w, "type": "~w"},~n',
           [ID, Name, Cap, Type]),
    write_rooms_json(Stream, Rest).

write_slots_json(_, []).
write_slots_json(Stream, [timeslot(ID, Day, Period, Start, Dur)]) :-
    format(Stream, '    {"id": "~w", "day": "~w", "period": ~w, "start": "~w", "duration": ~w}~n',
           [ID, Day, Period, Start, Dur]).
write_slots_json(Stream, [timeslot(ID, Day, Period, Start, Dur)|Rest]) :-
    Rest \= [],
    format(Stream, '    {"id": "~w", "day": "~w", "period": ~w, "start": "~w", "duration": ~w},~n',
           [ID, Day, Period, Start, Dur]),
    write_slots_json(Stream, Rest).

write_assignments_json(_, []).
write_assignments_json(Stream, [assigned(RoomID, ClassID, SubjectID, TeacherID, SlotID)]) :-
    format(Stream, '    {"room_id": "~w", "class_id": "~w", "subject_id": "~w", "teacher_id": "~w", "slot_id": "~w"}~n',
           [RoomID, ClassID, SubjectID, TeacherID, SlotID]).
write_assignments_json(Stream, [assigned(RoomID, ClassID, SubjectID, TeacherID, SlotID)|Rest]) :-
    Rest \= [],
    format(Stream, '    {"room_id": "~w", "class_id": "~w", "subject_id": "~w", "teacher_id": "~w", "slot_id": "~w"},~n',
           [RoomID, ClassID, SubjectID, TeacherID, SlotID]),
    write_assignments_json(Stream, Rest).

% ============================================================================
% CSV export
% ============================================================================

generate_csv_output(Timetable) :-
    writeln('  Writing timetable.csv...'),
    get_all_assignments(Timetable, Assignments),
    open('docs/examples/timetable.csv', write, Stream),
    format(Stream, 'Class,Subject,Teacher,Room,Day,Period,StartTime~n', []),
    forall(
        member(assigned(RoomID, ClassID, SubjectID, TeacherID, SlotID), Assignments),
        (
            (class(ClassID, CName, _) -> true ; CName = ClassID),
            (subject(SubjectID, SName, _, _, _) -> true ; SName = SubjectID),
            (teacher(TeacherID, TName, _, _, _) -> true ; TName = TeacherID),
            (room(RoomID, RName, _, _) -> true ; RName = RoomID),
            (timeslot(SlotID, Day, Period, Start, _) -> true ; Day = unknown, Period = 0, Start = '00:00'),
            format(Stream, '"~w","~w","~w","~w","~w",~w,"~w"~n',
                   [CName, SName, TName, RName, Day, Period, Start])
        )
    ),
    close(Stream).

% ============================================================================
% Text export
% ============================================================================

generate_text_output(Timetable) :-
    writeln('  Writing timetable.txt...'),
    get_all_assignments(Timetable, Assignments),
    open('docs/examples/timetable.txt', write, Stream),
    format(Stream, '=============================================================~n', []),
    format(Stream, '  AI-Based Timetable Generation System - Example Output~n', []),
    format(Stream, '=============================================================~n~n', []),
    format(Stream, '~w~t~30|~w~t~55|~w~t~75|~w~t~90|~w~n',
           ['Class', 'Subject', 'Teacher', 'Room', 'Slot']),
    format(Stream, '~`-t~100|~n', []),
    forall(
        member(assigned(RoomID, ClassID, SubjectID, TeacherID, SlotID), Assignments),
        (
            (class(ClassID, CName, _) -> true ; CName = ClassID),
            (subject(SubjectID, SName, _, _, _) -> true ; SName = SubjectID),
            (teacher(TeacherID, TName, _, _, _) -> true ; TName = TeacherID),
            (room(RoomID, RName, _, _) -> true ; RName = RoomID),
            (timeslot(SlotID, Day, Period, Start, _) ->
                format(atom(SlotLabel), '~w P~w ~w', [Day, Period, Start])
            ;   SlotLabel = SlotID),
            format(Stream, '~w~t~30|~w~t~55|~w~t~75|~w~t~90|~w~n',
                   [CName, SName, TName, RName, SlotLabel])
        )
    ),
    format(Stream, '~n~`=t~100|~n', []),
    length(Assignments, NA),
    format(Stream, 'Total assignments: ~w~n', [NA]),
    close(Stream).

% ============================================================================
% Reliability output
% ============================================================================

generate_reliability_output(Timetable) :-
    writeln('  Writing reliability.json...'),
    schedule_reliability(Timetable, Reliability),
    risk_category(Reliability, Category),
    expected_disruptions(Timetable, Expected),
    get_all_assignments(Timetable, Assignments),
    length(Assignments, NA),
    open('docs/examples/reliability.json', write, Stream),
    format(Stream, '{~n', []),
    format(Stream, '  "status": "ok",~n', []),
    format(Stream, '  "reliability": ~4f,~n', [Reliability]),
    format(Stream, '  "risk_category": "~w",~n', [Category]),
    format(Stream, '  "expected_disruptions": ~4f,~n', [Expected]),
    format(Stream, '  "total_assignments": ~w,~n', [NA]),
    format(Stream, '  "interpretation": {~n', []),
    format(Stream, '    "low": "reliability >= 0.95 (very robust schedule)",~n', []),
    format(Stream, '    "medium": "reliability 0.85-0.95 (minor disruption risk)",~n', []),
    format(Stream, '    "high": "reliability 0.70-0.85 (moderate disruption risk)",~n', []),
    format(Stream, '    "critical": "reliability < 0.70 (high disruption risk)"~n', []),
    format(Stream, '  }~n', []),
    format(Stream, '}~n', []),
    close(Stream).

% ============================================================================
% Conflicts output
% ============================================================================

generate_conflicts_output(Timetable) :-
    writeln('  Writing conflicts.json...'),
    detect_conflicts(Timetable, Conflicts),
    length(Conflicts, NC),
    open('docs/examples/conflicts.json', write, Stream),
    format(Stream, '{~n', []),
    format(Stream, '  "status": "ok",~n', []),
    format(Stream, '  "conflict_count": ~w,~n', [NC]),
    format(Stream, '  "conflicts": [~n', []),
    write_conflicts_json(Stream, Conflicts),
    format(Stream, '  ]~n', []),
    format(Stream, '}~n', []),
    close(Stream).

write_conflicts_json(_, []).
write_conflicts_json(Stream, [C]) :-
    format(Stream, '    ~w~n', [C]).
write_conflicts_json(Stream, [C|Rest]) :-
    Rest \= [],
    format(Stream, '    ~w,~n', [C]),
    write_conflicts_json(Stream, Rest).

% ============================================================================
% Dataset summary
% ============================================================================

generate_dataset_summary :-
    writeln('  Writing dataset_summary.json...'),
    get_all_teachers(Teachers), length(Teachers, NT),
    get_all_subjects(Subjects), length(Subjects, NS),
    get_all_rooms(Rooms), length(Rooms, NR),
    get_all_timeslots(Slots), length(Slots, NSl),
    get_all_classes(Classes), length(Classes, NC),
    open('docs/examples/dataset_summary.json', write, Stream),
    format(Stream, '{~n', []),
    format(Stream, '  "dataset": "data/dataset.pl",~n', []),
    format(Stream, '  "teachers": ~w,~n', [NT]),
    format(Stream, '  "subjects": ~w,~n', [NS]),
    format(Stream, '  "rooms": ~w,~n', [NR]),
    format(Stream, '  "timeslots": ~w,~n', [NSl]),
    format(Stream, '  "classes": ~w~n', [NC]),
    format(Stream, '}~n', []),
    close(Stream).
