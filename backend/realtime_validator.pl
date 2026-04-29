%% ============================================================================
%% realtime_validator.pl - Real-Time Input Validation Module
%% ============================================================================
%% This module provides real-time validation for all resource input types.
%% It checks data integrity, detects conflicts with existing resources,
%% and suggests corrections for invalid input.
%%
%% Requirements: 1.7, 16.3, 16.4, 24.1, 24.2, 24.3
%%
%% Author: AI Timetable Generation System
%% ============================================================================

:- module(realtime_validator, [
    validate_teacher_input/2,
    validate_subject_input/2,
    validate_room_input/2,
    validate_timeslot_input/2,
    validate_class_input/2,
    check_resource_conflicts/2,
    suggest_corrections/2
]).

:- use_module(knowledge_base).
:- use_module(logging).

%% ============================================================================
%% Teacher Input Validation
%% ============================================================================

%% validate_teacher_input(+Data, -Result)
%% Validate teacher resource data
%% Result: valid or error(Errors, Suggestions)
validate_teacher_input(Data, Result) :-
    findall(Error-Suggestion, check_teacher_field(Data, Error, Suggestion), Pairs),
    (Pairs = [] ->
        Result = valid
    ;
        pairs_keys(Pairs, Errors),
        pairs_values(Pairs, Suggestions),
        Result = error(Errors, Suggestions)
    ).

check_teacher_field(Data, Error, Suggestion) :-
    \+ get_dict(name, Data, _),
    Error = 'Missing required field: name',
    Suggestion = 'Provide a teacher name'.

check_teacher_field(Data, Error, Suggestion) :-
    get_dict(name, Data, Name),
    (atom(Name) -> NameStr = Name ; term_to_atom(Name, NameStr)),
    atom_length(NameStr, Len),
    Len < 2,
    Error = 'Teacher name is too short',
    Suggestion = 'Name must be at least 2 characters'.

check_teacher_field(Data, Error, Suggestion) :-
    \+ get_dict(qualified_subjects, Data, _),
    Error = 'Missing required field: qualified_subjects',
    Suggestion = 'Provide at least one qualified subject ID'.

check_teacher_field(Data, Error, Suggestion) :-
    get_dict(qualified_subjects, Data, Subjects),
    (is_list(Subjects) -> true ; Subjects = []),
    length(Subjects, Len),
    Len =:= 0,
    Error = 'Teacher must have at least one qualified subject',
    Suggestion = 'Add subject IDs to qualified_subjects list'.

check_teacher_field(Data, Error, Suggestion) :-
    \+ get_dict(max_load, Data, _),
    Error = 'Missing required field: max_load',
    Suggestion = 'Provide maximum weekly teaching hours (1-40)'.

check_teacher_field(Data, Error, Suggestion) :-
    get_dict(max_load, Data, MaxLoad),
    number(MaxLoad),
    (MaxLoad < 1 ; MaxLoad > 40),
    Error = 'max_load must be between 1 and 40 hours',
    Suggestion = 'Set max_load to a value between 1 and 40'.

check_teacher_field(Data, Error, Suggestion) :-
    \+ get_dict(availability, Data, _),
    Error = 'Missing required field: availability',
    Suggestion = 'Provide a list of available time slot IDs'.

check_teacher_field(Data, Error, Suggestion) :-
    get_dict(availability, Data, Avail),
    (is_list(Avail) -> true ; Avail = []),
    length(Avail, Len),
    Len =:= 0,
    Error = 'Teacher must have at least one available time slot',
    Suggestion = 'Add time slot IDs to availability list'.

%% ============================================================================
%% Subject Input Validation
%% ============================================================================

%% validate_subject_input(+Data, -Result)
%% Validate subject resource data
validate_subject_input(Data, Result) :-
    findall(Error-Suggestion, check_subject_field(Data, Error, Suggestion), Pairs),
    (Pairs = [] ->
        Result = valid
    ;
        pairs_keys(Pairs, Errors),
        pairs_values(Pairs, Suggestions),
        Result = error(Errors, Suggestions)
    ).

check_subject_field(Data, Error, Suggestion) :-
    \+ get_dict(name, Data, _),
    Error = 'Missing required field: name',
    Suggestion = 'Provide a subject name'.

check_subject_field(Data, Error, Suggestion) :-
    get_dict(name, Data, Name),
    (atom(Name) -> NameStr = Name ; term_to_atom(Name, NameStr)),
    atom_length(NameStr, Len),
    Len < 2,
    Error = 'Subject name is too short',
    Suggestion = 'Name must be at least 2 characters'.

check_subject_field(Data, Error, Suggestion) :-
    \+ get_dict(weekly_hours, Data, _),
    Error = 'Missing required field: weekly_hours',
    Suggestion = 'Provide required weekly hours (1-20)'.

check_subject_field(Data, Error, Suggestion) :-
    get_dict(weekly_hours, Data, Hours),
    number(Hours),
    (Hours < 1 ; Hours > 20),
    Error = 'weekly_hours must be between 1 and 20',
    Suggestion = 'Set weekly_hours to a value between 1 and 20'.

check_subject_field(Data, Error, Suggestion) :-
    \+ get_dict(type, Data, _),
    Error = 'Missing required field: type',
    Suggestion = 'Specify subject type: theory or lab'.

check_subject_field(Data, Error, Suggestion) :-
    get_dict(type, Data, Type),
    \+ member(Type, [theory, lab, 'theory', 'lab']),
    Error = 'Subject type must be theory or lab',
    Suggestion = 'Set type to either "theory" or "lab"'.

check_subject_field(Data, Error, Suggestion) :-
    \+ get_dict(duration, Data, _),
    Error = 'Missing required field: duration',
    Suggestion = 'Provide session duration in hours (1-4)'.

check_subject_field(Data, Error, Suggestion) :-
    get_dict(duration, Data, Duration),
    number(Duration),
    (Duration < 0.5 ; Duration > 4),
    Error = 'duration must be between 0.5 and 4 hours',
    Suggestion = 'Set duration to a value between 0.5 and 4'.

%% ============================================================================
%% Room Input Validation
%% ============================================================================

%% validate_room_input(+Data, -Result)
%% Validate room resource data
validate_room_input(Data, Result) :-
    findall(Error-Suggestion, check_room_field(Data, Error, Suggestion), Pairs),
    (Pairs = [] ->
        Result = valid
    ;
        pairs_keys(Pairs, Errors),
        pairs_values(Pairs, Suggestions),
        Result = error(Errors, Suggestions)
    ).

check_room_field(Data, Error, Suggestion) :-
    \+ get_dict(name, Data, _),
    Error = 'Missing required field: name',
    Suggestion = 'Provide a room name or number'.

check_room_field(Data, Error, Suggestion) :-
    get_dict(name, Data, Name),
    (atom(Name) -> NameStr = Name ; term_to_atom(Name, NameStr)),
    atom_length(NameStr, Len),
    Len < 1,
    Error = 'Room name cannot be empty',
    Suggestion = 'Provide a valid room name or number'.

check_room_field(Data, Error, Suggestion) :-
    \+ get_dict(capacity, Data, _),
    Error = 'Missing required field: capacity',
    Suggestion = 'Provide room capacity (10-200 students)'.

check_room_field(Data, Error, Suggestion) :-
    get_dict(capacity, Data, Cap),
    number(Cap),
    (Cap < 1 ; Cap > 500),
    Error = 'capacity must be between 1 and 500',
    Suggestion = 'Set capacity to a realistic value between 1 and 500'.

check_room_field(Data, Error, Suggestion) :-
    \+ get_dict(type, Data, _),
    Error = 'Missing required field: type',
    Suggestion = 'Specify room type: classroom or lab'.

check_room_field(Data, Error, Suggestion) :-
    get_dict(type, Data, Type),
    \+ member(Type, [classroom, lab, 'classroom', 'lab']),
    Error = 'Room type must be classroom or lab',
    Suggestion = 'Set type to either "classroom" or "lab"'.

%% ============================================================================
%% Timeslot Input Validation
%% ============================================================================

%% validate_timeslot_input(+Data, -Result)
%% Validate timeslot resource data
validate_timeslot_input(Data, Result) :-
    findall(Error-Suggestion, check_timeslot_field(Data, Error, Suggestion), Pairs),
    (Pairs = [] ->
        Result = valid
    ;
        pairs_keys(Pairs, Errors),
        pairs_values(Pairs, Suggestions),
        Result = error(Errors, Suggestions)
    ).

check_timeslot_field(Data, Error, Suggestion) :-
    \+ get_dict(day, Data, _),
    Error = 'Missing required field: day',
    Suggestion = 'Specify the day of the week'.

check_timeslot_field(Data, Error, Suggestion) :-
    get_dict(day, Data, Day),
    \+ member(Day, [monday, tuesday, wednesday, thursday, friday,
                    'monday', 'tuesday', 'wednesday', 'thursday', 'friday']),
    Error = 'day must be a weekday (monday-friday)',
    Suggestion = 'Set day to monday, tuesday, wednesday, thursday, or friday'.

check_timeslot_field(Data, Error, Suggestion) :-
    \+ get_dict(period, Data, _),
    Error = 'Missing required field: period',
    Suggestion = 'Provide the period number (1-10)'.

check_timeslot_field(Data, Error, Suggestion) :-
    get_dict(period, Data, Period),
    number(Period),
    (Period < 1 ; Period > 10),
    Error = 'period must be between 1 and 10',
    Suggestion = 'Set period to a value between 1 and 10'.

check_timeslot_field(Data, Error, Suggestion) :-
    \+ get_dict(start_time, Data, _),
    Error = 'Missing required field: start_time',
    Suggestion = 'Provide the start time in HH:MM format'.

check_timeslot_field(Data, Error, Suggestion) :-
    get_dict(start_time, Data, StartTime),
    (atom(StartTime) -> ST = StartTime ; term_to_atom(StartTime, ST)),
    \+ valid_time_format(ST),
    Error = 'start_time must be in HH:MM format',
    Suggestion = 'Use 24-hour format, e.g., 09:00 or 14:30'.

check_timeslot_field(Data, Error, Suggestion) :-
    \+ get_dict(duration, Data, _),
    Error = 'Missing required field: duration',
    Suggestion = 'Provide slot duration in hours (0.5-4)'.

check_timeslot_field(Data, Error, Suggestion) :-
    get_dict(duration, Data, Duration),
    number(Duration),
    (Duration < 0.5 ; Duration > 4),
    Error = 'duration must be between 0.5 and 4 hours',
    Suggestion = 'Set duration to a value between 0.5 and 4'.

%% valid_time_format(+TimeAtom)
%% Check if atom matches HH:MM format
valid_time_format(Time) :-
    atom_string(Time, TimeStr),
    split_string(TimeStr, ":", "", Parts),
    Parts = [HStr, MStr],
    number_string(H, HStr),
    number_string(M, MStr),
    H >= 0, H =< 23,
    M >= 0, M =< 59.

%% ============================================================================
%% Class Input Validation
%% ============================================================================

%% validate_class_input(+Data, -Result)
%% Validate class resource data
validate_class_input(Data, Result) :-
    findall(Error-Suggestion, check_class_field(Data, Error, Suggestion), Pairs),
    (Pairs = [] ->
        Result = valid
    ;
        pairs_keys(Pairs, Errors),
        pairs_values(Pairs, Suggestions),
        Result = error(Errors, Suggestions)
    ).

check_class_field(Data, Error, Suggestion) :-
    \+ get_dict(name, Data, _),
    Error = 'Missing required field: name',
    Suggestion = 'Provide a class name'.

check_class_field(Data, Error, Suggestion) :-
    get_dict(name, Data, Name),
    (atom(Name) -> NameStr = Name ; term_to_atom(Name, NameStr)),
    atom_length(NameStr, Len),
    Len < 2,
    Error = 'Class name is too short',
    Suggestion = 'Name must be at least 2 characters'.

check_class_field(Data, Error, Suggestion) :-
    \+ get_dict(subjects, Data, _),
    Error = 'Missing required field: subjects',
    Suggestion = 'Provide a list of subject IDs for this class'.

check_class_field(Data, Error, Suggestion) :-
    get_dict(subjects, Data, Subjects),
    (is_list(Subjects) -> true ; Subjects = []),
    length(Subjects, Len),
    Len =:= 0,
    Error = 'Class must have at least one subject',
    Suggestion = 'Add subject IDs to the subjects list'.

check_class_field(Data, Error, Suggestion) :-
    get_dict(subjects, Data, Subjects),
    is_list(Subjects),
    get_all_subjects(AllSubjects),
    findall(SID, member(subject(SID, _, _, _, _), AllSubjects), KnownIDs),
    KnownIDs \= [],
    findall(S, (member(S, Subjects), \+ member(S, KnownIDs)), Unknown),
    Unknown \= [],
    format(atom(Error), 'Unknown subject IDs: ~w', [Unknown]),
    format(atom(Suggestion), 'These subject IDs do not exist in the knowledge base: ~w', [Unknown]).

%% ============================================================================
%% Resource Conflict Detection
%% ============================================================================

%% check_resource_conflicts(+Data, -Conflicts)
%% Detect conflicts between new data and existing knowledge base
check_resource_conflicts(Data, Conflicts) :-
    (get_dict(type, Data, Type) -> true ; Type = unknown),
    findall(Conflict, detect_conflict(Type, Data, Conflict), Conflicts).

detect_conflict(teacher, Data, Conflict) :-
    get_dict(id, Data, ID),
    teacher(ID, ExistingName, _, _, _),
    format(atom(Conflict), 'Teacher ID ~w already exists (name: ~w)', [ID, ExistingName]).

detect_conflict(subject, Data, Conflict) :-
    get_dict(id, Data, ID),
    subject(ID, ExistingName, _, _, _),
    format(atom(Conflict), 'Subject ID ~w already exists (name: ~w)', [ID, ExistingName]).

detect_conflict(room, Data, Conflict) :-
    get_dict(id, Data, ID),
    room(ID, ExistingName, _, _),
    format(atom(Conflict), 'Room ID ~w already exists (name: ~w)', [ID, ExistingName]).

detect_conflict(timeslot, Data, Conflict) :-
    get_dict(id, Data, ID),
    timeslot(ID, ExistingDay, ExistingPeriod, _, _),
    format(atom(Conflict), 'Timeslot ID ~w already exists (~w period ~w)', [ID, ExistingDay, ExistingPeriod]).

detect_conflict(timeslot, Data, Conflict) :-
    get_dict(day, Data, Day),
    get_dict(period, Data, Period),
    timeslot(ExistingID, Day, Period, _, _),
    \+ (get_dict(id, Data, ID), ID = ExistingID),
    format(atom(Conflict), 'A timeslot already exists for ~w period ~w (ID: ~w)', [Day, Period, ExistingID]).

detect_conflict(class, Data, Conflict) :-
    get_dict(id, Data, ID),
    class(ID, ExistingName, _),
    format(atom(Conflict), 'Class ID ~w already exists (name: ~w)', [ID, ExistingName]).

detect_conflict(_, _, _) :- fail.

%% ============================================================================
%% Correction Suggestions
%% ============================================================================

%% suggest_corrections(+Data, -Suggestions)
%% Generate actionable suggestions for fixing invalid input
suggest_corrections(Data, Suggestions) :-
    (get_dict(type, Data, Type) -> true ; Type = unknown),
    findall(Suggestion, generate_suggestion(Type, Data, Suggestion), Suggestions).

generate_suggestion(teacher, Data, Suggestion) :-
    get_dict(qualified_subjects, Data, Subjects),
    is_list(Subjects),
    get_all_subjects(AllSubjects),
    findall(SID, member(subject(SID, _, _, _, _), AllSubjects), KnownIDs),
    KnownIDs \= [],
    findall(S, (member(S, Subjects), \+ member(S, KnownIDs)), Unknown),
    Unknown \= [],
    format(atom(Suggestion), 'Unknown subject IDs in qualified_subjects: ~w. Available: ~w', [Unknown, KnownIDs]).

generate_suggestion(teacher, Data, Suggestion) :-
    get_dict(availability, Data, Avail),
    is_list(Avail),
    get_all_timeslots(AllSlots),
    findall(SID, member(timeslot(SID, _, _, _, _), AllSlots), KnownSlots),
    KnownSlots \= [],
    findall(S, (member(S, Avail), \+ member(S, KnownSlots)), Unknown),
    Unknown \= [],
    format(atom(Suggestion), 'Unknown slot IDs in availability: ~w. Available: ~w', [Unknown, KnownSlots]).

generate_suggestion(class, Data, Suggestion) :-
    get_dict(subjects, Data, Subjects),
    is_list(Subjects),
    get_all_subjects(AllSubjects),
    findall(SID, member(subject(SID, _, _, _, _), AllSubjects), KnownIDs),
    KnownIDs \= [],
    findall(S, (member(S, Subjects), \+ member(S, KnownIDs)), Unknown),
    Unknown \= [],
    format(atom(Suggestion), 'Unknown subject IDs: ~w. Available subjects: ~w', [Unknown, KnownIDs]).

generate_suggestion(_, _, _) :- fail.

%% ============================================================================
%% Dispatch validation by resource type
%% ============================================================================

%% validate_by_type(+Type, +Data, -Result)
%% Route validation to the appropriate predicate
validate_by_type(teacher, Data, Result) :- validate_teacher_input(Data, Result).
validate_by_type(subject, Data, Result) :- validate_subject_input(Data, Result).
validate_by_type(room,    Data, Result) :- validate_room_input(Data, Result).
validate_by_type(timeslot, Data, Result) :- validate_timeslot_input(Data, Result).
validate_by_type(class,   Data, Result) :- validate_class_input(Data, Result).
validate_by_type(Type, _, error(['Unknown resource type'], ['Use: teacher, subject, room, timeslot, or class'])) :-
    \+ member(Type, [teacher, subject, room, timeslot, class]),
    log_warning('Unknown resource type for validation').
