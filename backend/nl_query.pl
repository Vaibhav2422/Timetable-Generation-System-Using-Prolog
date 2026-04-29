%% ============================================================================
%% nl_query.pl - Natural Language Query Interface
%% ============================================================================
%% This module implements a simple natural language query interface that
%% allows users to ask questions about the timetable in plain English.
%% It uses keyword matching and entity extraction to parse queries and
%% retrieve answers from the knowledge base.
%%
%% MFAI Concept: Symbolic AI + NLP
%% - Intent classification via keyword matching
%% - Entity extraction by matching known names from knowledge base
%% - Answer generation using Prolog inference
%%
%% Supported query intents:
%%   teacher_schedule  - "Show Dr. Smith schedule" / "What does Dr. Smith teach?"
%%   room_availability - "When is Lab 2 free?" / "Is Room 101 available?"
%%   subject_details   - "Which teacher teaches AI?" / "Who teaches Mathematics?"
%%   class_schedule    - "Show CS1 timetable" / "What is CS1 schedule?"
%%
%% Requirements: Feature 18 (Natural Language Query Interface)
%% ============================================================================

:- module(nl_query, [
    answer_query/2,
    parse_nl_query/2,
    query_teacher_schedule/2,
    query_room_availability/2,
    query_subject_details/2,
    query_class_schedule/2,
    format_nl_answer/2
]).

:- use_module(knowledge_base).
:- use_module(library(lists)).

%% ============================================================================
%% Main Entry Point
%% ============================================================================

%% answer_query(+QueryText, -Answer)
%% Parse a natural language query and return a natural language answer.
%% This is the main predicate for the NL query interface.
%%
%% Example:
%%   answer_query("Show Dr. Smith schedule", Answer)
%%   Answer = "Dr. Smith teaches: Mathematics (Monday 09:00), ..."
answer_query(QueryText, Answer) :-
    % Normalize query to lowercase atom
    (atom(QueryText) -> Q = QueryText ; atom_string(Q, QueryText)),
    atom_string(Q, QStr),
    string_lower(QStr, QNorm),
    atom_string(QAtom, QNorm),
    % Parse intent and entities
    parse_nl_query(QAtom, ParsedQuery),
    % Execute query and format answer
    execute_nl_query(ParsedQuery, RawAnswer),
    format_nl_answer(RawAnswer, Answer).

%% parse_nl_query(+QueryAtom, -ParsedQuery)
%% Extract intent and entities from a normalized query atom.
%% Returns a structured term: query(Intent, Entity)
%%
%% Intents: teacher_schedule, room_availability, subject_details, class_schedule
parse_nl_query(Query, query(teacher_schedule, TeacherID)) :-
    is_teacher_schedule_query(Query),
    extract_teacher_entity(Query, TeacherID),
    !.

parse_nl_query(Query, query(room_availability, RoomID)) :-
    is_room_availability_query(Query),
    extract_room_entity(Query, RoomID),
    !.

parse_nl_query(Query, query(subject_details, SubjectID)) :-
    is_subject_details_query(Query),
    extract_subject_entity(Query, SubjectID),
    !.

parse_nl_query(Query, query(class_schedule, ClassID)) :-
    is_class_schedule_query(Query),
    extract_class_entity(Query, ClassID),
    !.

parse_nl_query(_, query(unknown, none)).

%% ============================================================================
%% Intent Detection
%% ============================================================================

%% is_teacher_schedule_query(+Query)
%% True if query is asking about a teacher's schedule.
is_teacher_schedule_query(Query) :-
    (   sub_atom(Query, _, _, _, 'teacher')
    ;   sub_atom(Query, _, _, _, 'dr.')
    ;   sub_atom(Query, _, _, _, 'dr ')
    ;   sub_atom(Query, _, _, _, 'prof.')
    ;   sub_atom(Query, _, _, _, 'prof ')
    ;   sub_atom(Query, _, _, _, 'professor')
    ;   sub_atom(Query, _, _, _, 'lecturer')
    ),
    (   sub_atom(Query, _, _, _, 'schedule')
    ;   sub_atom(Query, _, _, _, 'timetable')
    ;   sub_atom(Query, _, _, _, 'teach')
    ;   sub_atom(Query, _, _, _, 'class')
    ;   sub_atom(Query, _, _, _, 'show')
    ;   sub_atom(Query, _, _, _, 'what')
    ;   sub_atom(Query, _, _, _, 'when')
    ).

%% is_room_availability_query(+Query)
%% True if query is asking about room availability.
is_room_availability_query(Query) :-
    (   sub_atom(Query, _, _, _, 'room')
    ;   sub_atom(Query, _, _, _, 'lab')
    ;   sub_atom(Query, _, _, _, 'hall')
    ;   sub_atom(Query, _, _, _, 'classroom')
    ),
    (   sub_atom(Query, _, _, _, 'free')
    ;   sub_atom(Query, _, _, _, 'available')
    ;   sub_atom(Query, _, _, _, 'empty')
    ;   sub_atom(Query, _, _, _, 'when')
    ;   sub_atom(Query, _, _, _, 'schedule')
    ;   sub_atom(Query, _, _, _, 'booked')
    ).

%% is_subject_details_query(+Query)
%% True if query is asking about a subject.
is_subject_details_query(Query) :-
    (   sub_atom(Query, _, _, _, 'subject')
    ;   sub_atom(Query, _, _, _, 'course')
    ;   sub_atom(Query, _, _, _, 'teaches')
    ;   sub_atom(Query, _, _, _, 'teach')
    ;   sub_atom(Query, _, _, _, 'who teaches')
    ;   sub_atom(Query, _, _, _, 'which teacher')
    ).

%% is_class_schedule_query(+Query)
%% True if query is asking about a class schedule.
is_class_schedule_query(Query) :-
    (   sub_atom(Query, _, _, _, 'class')
    ;   sub_atom(Query, _, _, _, 'group')
    ;   sub_atom(Query, _, _, _, 'batch')
    ;   sub_atom(Query, _, _, _, 'year')
    ;   sub_atom(Query, _, _, _, 'section')
    ;   % Also match if a known class ID or name appears in the query
        class(_, ClassName, _),
        atom_string(ClassName, CStr),
        string_lower(CStr, CLower),
        atom_string(CAtom, CLower),
        sub_atom(Query, _, _, _, CAtom)
    ;   class(ClassID, _, _),
        atom_string(ClassID, IDStr),
        string_lower(IDStr, IDLower),
        atom_string(IDAtom, IDLower),
        sub_atom(Query, _, _, _, IDAtom)
    ),
    (   sub_atom(Query, _, _, _, 'schedule')
    ;   sub_atom(Query, _, _, _, 'timetable')
    ;   sub_atom(Query, _, _, _, 'show')
    ;   sub_atom(Query, _, _, _, 'what')
    ).

%% ============================================================================
%% Entity Extraction
%% ============================================================================

%% extract_teacher_entity(+Query, -TeacherID)
%% Find a teacher ID whose name appears in the query.
extract_teacher_entity(Query, TeacherID) :-
    teacher(TeacherID, Name, _, _, _),
    atom_string(Name, NameStr),
    string_lower(NameStr, NameLower),
    atom_string(NameAtom, NameLower),
    sub_atom(Query, _, _, _, NameAtom),
    !.

extract_teacher_entity(Query, TeacherID) :-
    % Try matching last name only
    teacher(TeacherID, Name, _, _, _),
    atom_string(Name, NameStr),
    string_lower(NameStr, NameLower),
    split_string(NameLower, " ", "", Parts),
    last(Parts, LastName),
    atom_string(LastAtom, LastName),
    sub_atom(Query, _, _, _, LastAtom),
    !.

extract_teacher_entity(Query, TeacherID) :-
    % Try matching teacher ID directly
    teacher(TeacherID, _, _, _, _),
    atom_string(TeacherID, IDStr),
    string_lower(IDStr, IDLower),
    atom_string(IDAtom, IDLower),
    sub_atom(Query, _, _, _, IDAtom),
    !.

%% extract_room_entity(+Query, -RoomID)
%% Find a room ID whose name appears in the query.
extract_room_entity(Query, RoomID) :-
    room(RoomID, Name, _, _),
    atom_string(Name, NameStr),
    string_lower(NameStr, NameLower),
    atom_string(NameAtom, NameLower),
    sub_atom(Query, _, _, _, NameAtom),
    !.

extract_room_entity(Query, RoomID) :-
    % Try matching room ID directly
    room(RoomID, _, _, _),
    atom_string(RoomID, IDStr),
    string_lower(IDStr, IDLower),
    atom_string(IDAtom, IDLower),
    sub_atom(Query, _, _, _, IDAtom),
    !.

%% extract_subject_entity(+Query, -SubjectID)
%% Find a subject ID whose name appears in the query.
extract_subject_entity(Query, SubjectID) :-
    subject(SubjectID, Name, _, _, _),
    atom_string(Name, NameStr),
    string_lower(NameStr, NameLower),
    atom_string(NameAtom, NameLower),
    sub_atom(Query, _, _, _, NameAtom),
    !.

extract_subject_entity(Query, SubjectID) :-
    % Try matching subject ID directly
    subject(SubjectID, _, _, _, _),
    atom_string(SubjectID, IDStr),
    string_lower(IDStr, IDLower),
    atom_string(IDAtom, IDLower),
    sub_atom(Query, _, _, _, IDAtom),
    !.

%% extract_class_entity(+Query, -ClassID)
%% Find a class ID whose name appears in the query.
extract_class_entity(Query, ClassID) :-
    class(ClassID, Name, _),
    atom_string(Name, NameStr),
    string_lower(NameStr, NameLower),
    atom_string(NameAtom, NameLower),
    sub_atom(Query, _, _, _, NameAtom),
    !.

extract_class_entity(Query, ClassID) :-
    % Try matching class ID directly
    class(ClassID, _, _),
    atom_string(ClassID, IDStr),
    string_lower(IDStr, IDLower),
    atom_string(IDAtom, IDLower),
    sub_atom(Query, _, _, _, IDAtom),
    !.

%% ============================================================================
%% Query Execution
%% ============================================================================

%% execute_nl_query(+ParsedQuery, -RawAnswer)
%% Execute a parsed query and return raw answer data.
execute_nl_query(query(teacher_schedule, TeacherID), Answer) :-
    TeacherID \= none,
    !,
    query_teacher_schedule(TeacherID, Answer).

execute_nl_query(query(room_availability, RoomID), Answer) :-
    RoomID \= none,
    !,
    query_room_availability(RoomID, Answer).

execute_nl_query(query(subject_details, SubjectID), Answer) :-
    SubjectID \= none,
    !,
    query_subject_details(SubjectID, Answer).

execute_nl_query(query(class_schedule, ClassID), Answer) :-
    ClassID \= none,
    !,
    query_class_schedule(ClassID, Answer).

execute_nl_query(query(unknown, _), answer(unknown, [], 'I could not understand your query. Try asking about a teacher schedule, room availability, subject details, or class timetable.')).

execute_nl_query(query(Intent, none), answer(no_entity, [], Msg)) :-
    format(atom(Msg), 'I understood you are asking about ~w, but could not identify the specific resource. Please include the name in your query.', [Intent]).

%% ============================================================================
%% Specific Query Handlers
%% ============================================================================

%% query_teacher_schedule(+TeacherID, -Answer)
%% Get the schedule for a specific teacher.
%% Example: "Show Dr. Smith schedule"
query_teacher_schedule(TeacherID, answer(teacher_schedule, Sessions, Summary)) :-
    teacher(TeacherID, TeacherName, _, _, _),
    !,
    % Find all sessions assigned to this teacher in the current timetable
    (   current_timetable_data(Assignments)
    ->  findall(
            session_info(SubjectName, ClassName, RoomName, Day, Period, StartTime),
            (   member(assigned(RoomID, ClassID, SubjectID, TeacherID, SlotID), Assignments),
                subject(SubjectID, SubjectName, _, _, _),
                class(ClassID, ClassName, _),
                room(RoomID, RoomName, _, _),
                timeslot(SlotID, Day, Period, StartTime, _)
            ),
            Sessions
        )
    ;   Sessions = []
    ),
    format(atom(Summary), 'Schedule for ~w', [TeacherName]).

query_teacher_schedule(TeacherID, answer(not_found, [], Msg)) :-
    format(atom(Msg), 'Teacher with ID "~w" not found in the knowledge base.', [TeacherID]).

%% query_room_availability(+RoomID, -Answer)
%% Get the availability/schedule for a specific room.
%% Example: "When is Lab 2 free?"
query_room_availability(RoomID, answer(room_availability, Slots, Summary)) :-
    room(RoomID, RoomName, _, _),
    !,
    % Find all booked slots for this room
    (   current_timetable_data(Assignments)
    ->  findall(
            booked(Day, Period, StartTime, SubjectName, ClassName),
            (   member(assigned(RoomID, ClassID, SubjectID, _, SlotID), Assignments),
                timeslot(SlotID, Day, Period, StartTime, _),
                subject(SubjectID, SubjectName, _, _, _),
                class(ClassID, ClassName, _)
            ),
            BookedSlots
        ),
        % Find free slots
        findall(
            free(Day, Period, StartTime),
            (   timeslot(SlotID, Day, Period, StartTime, _),
                \+ member(assigned(RoomID, _, _, _, SlotID), Assignments)
            ),
            FreeSlots
        ),
        Slots = availability(booked(BookedSlots), free(FreeSlots))
    ;   % No timetable yet - all slots are free
        findall(
            free(Day, Period, StartTime),
            timeslot(_, Day, Period, StartTime, _),
            FreeSlots
        ),
        Slots = availability(booked([]), free(FreeSlots))
    ),
    format(atom(Summary), 'Availability for ~w', [RoomName]).

query_room_availability(RoomID, answer(not_found, [], Msg)) :-
    format(atom(Msg), 'Room with ID "~w" not found in the knowledge base.', [RoomID]).

%% query_subject_details(+SubjectID, -Answer)
%% Get details about a subject including which teachers teach it.
%% Example: "Which teacher teaches AI?"
query_subject_details(SubjectID, answer(subject_details, Details, Summary)) :-
    subject(SubjectID, SubjectName, WeeklyHours, Type, Duration),
    !,
    % Find qualified teachers
    findall(TeacherName,
            (teacher(_, TeacherName, QualifiedSubjects, _, _),
             member(SubjectID, QualifiedSubjects)),
            QualifiedTeachers),
    % Find classes that have this subject
    findall(ClassName,
            (class(_, ClassName, SubjectList),
             member(SubjectID, SubjectList)),
            Classes),
    Details = subject_info(
        name(SubjectName),
        weekly_hours(WeeklyHours),
        type(Type),
        duration(Duration),
        qualified_teachers(QualifiedTeachers),
        classes(Classes)
    ),
    format(atom(Summary), 'Details for subject: ~w', [SubjectName]).

query_subject_details(SubjectID, answer(not_found, [], Msg)) :-
    format(atom(Msg), 'Subject with ID "~w" not found in the knowledge base.', [SubjectID]).

%% query_class_schedule(+ClassID, -Answer)
%% Get the full timetable for a specific class.
%% Example: "Show CS1 timetable"
query_class_schedule(ClassID, answer(class_schedule, Sessions, Summary)) :-
    class(ClassID, ClassName, _),
    !,
    (   current_timetable_data(Assignments)
    ->  findall(
            session_info(SubjectName, TeacherName, RoomName, Day, Period, StartTime),
            (   member(assigned(RoomID, ClassID, SubjectID, TeacherID, SlotID), Assignments),
                subject(SubjectID, SubjectName, _, _, _),
                teacher(TeacherID, TeacherName, _, _, _),
                room(RoomID, RoomName, _, _),
                timeslot(SlotID, Day, Period, StartTime, _)
            ),
            Sessions
        )
    ;   Sessions = []
    ),
    format(atom(Summary), 'Timetable for ~w', [ClassName]).

query_class_schedule(ClassID, answer(not_found, [], Msg)) :-
    format(atom(Msg), 'Class with ID "~w" not found in the knowledge base.', [ClassID]).

%% ============================================================================
%% Answer Formatting
%% ============================================================================

%% format_nl_answer(+RawAnswer, -FormattedAnswer)
%% Convert raw answer data into a human-readable natural language string.
format_nl_answer(answer(unknown, _, Msg), Msg) :- !.
format_nl_answer(answer(no_entity, _, Msg), Msg) :- !.
format_nl_answer(answer(not_found, _, Msg), Msg) :- !.

format_nl_answer(answer(teacher_schedule, Sessions, Summary), FormattedAnswer) :-
    !,
    (   Sessions = []
    ->  format(atom(FormattedAnswer), '~w: No sessions scheduled yet (generate a timetable first).', [Summary])
    ;   format_session_list(Sessions, SessionText),
        format(atom(FormattedAnswer), '~w:\n~w', [Summary, SessionText])
    ).

format_nl_answer(answer(room_availability, availability(booked(Booked), free(Free)), Summary), FormattedAnswer) :-
    !,
    length(Booked, NumBooked),
    length(Free, NumFree),
    (   Booked = []
    ->  BookedText = 'No sessions booked.'
    ;   format_booked_list(Booked, BookedListText),
        format(atom(BookedText), 'Booked slots (~w):\n~w', [NumBooked, BookedListText])
    ),
    (   Free = []
    ->  FreeText = 'No free slots available.'
    ;   format(atom(FreeText), '~w free slot(s) available.', [NumFree])
    ),
    format(atom(FormattedAnswer), '~w:\n~w\n~w', [Summary, BookedText, FreeText]).

format_nl_answer(answer(subject_details, subject_info(name(Name), weekly_hours(Hours), type(Type), duration(Duration), qualified_teachers(Teachers), classes(Classes)), _), FormattedAnswer) :-
    !,
    (   Teachers = []
    ->  TeacherText = 'No qualified teachers found.'
    ;   atomic_list_concat(Teachers, ', ', TeacherList),
        format(atom(TeacherText), 'Qualified teachers: ~w', [TeacherList])
    ),
    (   Classes = []
    ->  ClassText = 'Not assigned to any class.'
    ;   atomic_list_concat(Classes, ', ', ClassList),
        format(atom(ClassText), 'Taught to: ~w', [ClassList])
    ),
    format(atom(FormattedAnswer),
           'Subject: ~w\nType: ~w\nWeekly hours: ~w\nSession duration: ~w hour(s)\n~w\n~w',
           [Name, Type, Hours, Duration, TeacherText, ClassText]).

format_nl_answer(answer(class_schedule, Sessions, Summary), FormattedAnswer) :-
    !,
    (   Sessions = []
    ->  format(atom(FormattedAnswer), '~w: No sessions scheduled yet (generate a timetable first).', [Summary])
    ;   format_class_session_list(Sessions, SessionText),
        format(atom(FormattedAnswer), '~w:\n~w', [Summary, SessionText])
    ).

format_nl_answer(_, 'Unable to format the answer. Please try a different query.').

%% format_session_list(+Sessions, -Text)
%% Format a list of teacher sessions as text.
format_session_list([], '').
format_session_list([session_info(Subject, Class, Room, Day, Period, Time)|Rest], Text) :-
    format_session_list(Rest, RestText),
    format(atom(Line), '  - ~w for ~w in ~w on ~w period ~w at ~w\n', [Subject, Class, Room, Day, Period, Time]),
    atom_concat(Line, RestText, Text).

%% format_booked_list(+BookedSlots, -Text)
%% Format a list of booked room slots as text.
format_booked_list([], '').
format_booked_list([booked(Day, Period, Time, Subject, Class)|Rest], Text) :-
    format_booked_list(Rest, RestText),
    format(atom(Line), '  - ~w period ~w at ~w: ~w (~w)\n', [Day, Period, Time, Subject, Class]),
    atom_concat(Line, RestText, Text).

%% format_class_session_list(+Sessions, -Text)
%% Format a list of class sessions as text.
format_class_session_list([], '').
format_class_session_list([session_info(Subject, Teacher, Room, Day, Period, Time)|Rest], Text) :-
    format_class_session_list(Rest, RestText),
    format(atom(Line), '  - ~w with ~w in ~w on ~w period ~w at ~w\n', [Subject, Teacher, Room, Day, Period, Time]),
    atom_concat(Line, RestText, Text).

%% ============================================================================
%% Helper: Access Current Timetable
%% ============================================================================

%% current_timetable_data(-Assignments)
%% Get all assignments from the current timetable stored in api_server.
%% Falls back to empty list if no timetable is available.
:- use_module(matrix_model).

current_timetable_data(Assignments) :-
    % Try to access the current timetable from api_server's dynamic fact
    catch(
        (   current_predicate(api_server:current_timetable/1),
            api_server:current_timetable(Timetable),
            get_all_assignments(Timetable, Assignments)
        ),
        _,
        fail
    ).
