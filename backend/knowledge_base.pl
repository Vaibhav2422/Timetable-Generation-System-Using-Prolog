% ============================================================================
% knowledge_base.pl - First Order Logic Knowledge Base
% ============================================================================
% This module demonstrates First Order Logic (FOL) by storing scheduling
% resources as Prolog facts and defining logical inference rules.
%
% MFAI Concept: First Order Logic
% - Facts: teacher/5, subject/5, room/4, timeslot/5, class/3
% - Rules: qualified/2, suitable_room/2, teacher_available/2, etc.
% - Quantifiers: Universal (∀) and Existential (∃) through Prolog variables
% - Logical Inference: Backward chaining through Prolog's inference engine
%
% Author: AI Timetable Generation System
% ============================================================================

:- module(knowledge_base, [
    % Dynamic predicates for runtime updates
    teacher/5,
    subject/5,
    room/4,
    timeslot/5,
    class/3,
    
    % First Order Logic rules
    qualified/2,
    suitable_room/2,
    compatible_type/2,
    teacher_available/2,
    teacher_conflict/3,
    room_conflict/3,
    
    % Query predicates
    get_all_teachers/1,
    get_all_subjects/1,
    get_all_rooms/1,
    get_all_timeslots/1,
    get_all_classes/1
]).

% ============================================================================
% PART 1: DYNAMIC FACT DECLARATIONS
% ============================================================================
% These predicates are declared dynamic to allow runtime modifications
% through assert/retract operations from the API server.
% They are also multifile to allow facts to be defined in other files.

:- dynamic teacher/5.
:- dynamic subject/5.
:- dynamic room/4.
:- dynamic timeslot/5.
:- dynamic class/3.
% batch_of(BatchClassID, ParentClassID) — records that a batch is a subset of a division
:- dynamic batch_of/2.
:- multifile batch_of/2.

:- multifile teacher/5.
:- multifile subject/5.
:- multifile room/4.
:- multifile timeslot/5.
:- multifile class/3.
:- multifile class_size/2.

:- dynamic class_size/2.
:- multifile class_size/2.

% ============================================================================
% PART 2: RESOURCE FACTS
% ============================================================================
% These facts represent the knowledge base using First Order Logic predicates.
% Each fact is a ground instance of a predicate with specific arguments.

% ----------------------------------------------------------------------------
% teacher/5: Represents a teacher resource
% ----------------------------------------------------------------------------
% Format: teacher(TeacherID, Name, QualifiedSubjects, MaxLoad, AvailabilityList)
%
% Arguments:
%   TeacherID         : Unique identifier (atom)
%   Name              : Teacher's full name (atom)
%   QualifiedSubjects : List of subject IDs the teacher can teach (list)
%   MaxLoad           : Maximum weekly teaching hours (integer)
%   AvailabilityList  : List of timeslot IDs when teacher is available (list)
%
% FOL Interpretation:
%   ∀t ∈ Teachers: teacher(t.id, t.name, t.subjects, t.maxLoad, t.availability)
%
% Example:
%   teacher(t1, 'Dr. Smith', [math101, math102], 20, [slot1, slot2, slot3]).

% ----------------------------------------------------------------------------
% subject/5: Represents a subject/course
% ----------------------------------------------------------------------------
% Format: subject(SubjectID, Name, WeeklyHours, Type, Duration)
%
% Arguments:
%   SubjectID   : Unique identifier (atom)
%   Name        : Subject name (atom)
%   WeeklyHours : Required hours per week (integer)
%   Type        : Session type - theory or lab (atom)
%   Duration    : Duration of each session in hours (integer)
%
% FOL Interpretation:
%   ∀s ∈ Subjects: subject(s.id, s.name, s.hours, s.type, s.duration)
%
% Example:
%   subject(math101, 'Calculus I', 4, theory, 1).
%   subject(cs201, 'Data Structures Lab', 3, lab, 2).

% ----------------------------------------------------------------------------
% room/4: Represents a classroom or laboratory
% ----------------------------------------------------------------------------
% Format: room(RoomID, Name, Capacity, Type)
%
% Arguments:
%   RoomID   : Unique identifier (atom)
%   Name     : Room name/number (atom)
%   Capacity : Maximum student capacity (integer)
%   Type     : Room type - classroom or lab (atom)
%
% FOL Interpretation:
%   ∀r ∈ Rooms: room(r.id, r.name, r.capacity, r.type)
%
% Example:
%   room(r101, 'Room 101', 50, classroom).
%   room(lab1, 'Computer Lab 1', 30, lab).

% ----------------------------------------------------------------------------
% timeslot/5: Represents a time period in the weekly schedule
% ----------------------------------------------------------------------------
% Format: timeslot(SlotID, Day, Period, StartTime, Duration)
%
% Arguments:
%   SlotID    : Unique identifier (atom)
%   Day       : Day of week - monday, tuesday, etc. (atom)
%   Period    : Period number in the day (integer)
%   StartTime : Start time in 24-hour format (atom)
%   Duration  : Duration in hours (integer)
%
% FOL Interpretation:
%   ∀t ∈ TimeSlots: timeslot(t.id, t.day, t.period, t.start, t.duration)
%
% Example:
%   timeslot(slot1, monday, 1, '09:00', 1).
%   timeslot(slot2, monday, 2, '10:00', 1).

% ----------------------------------------------------------------------------
% class/3: Represents a student class/section
% ----------------------------------------------------------------------------
% Format: class(ClassID, Name, SubjectList)
%
% Arguments:
%   ClassID     : Unique identifier (atom)
%   Name        : Class name (atom)
%   SubjectList : List of subject IDs this class must take (list)
%
% FOL Interpretation:
%   ∀c ∈ Classes: class(c.id, c.name, c.subjects)
%
% Example:
%   class(cs1a, 'CS Year 1 Section A', [math101, cs101, physics101]).

% ============================================================================
% PART 3: FIRST ORDER LOGIC RULES
% ============================================================================
% These rules demonstrate logical inference through backward chaining.
% Prolog's inference engine uses unification and resolution to derive
% conclusions from facts and rules.

% ----------------------------------------------------------------------------
% qualified/2: Determines if a teacher is qualified to teach a subject
% ----------------------------------------------------------------------------
% Format: qualified(TeacherID, SubjectID)
%
% FOL Formula:
%   ∀t ∀s: qualified(t, s) ← teacher(t, _, subjects, _, _) ∧ s ∈ subjects
%
% Logical Interpretation:
%   A teacher T is qualified for subject S if and only if S is in the list
%   of qualified subjects for teacher T.
%
% Usage:
%   ?- qualified(t1, math101).  % Check if t1 can teach math101
%   ?- qualified(T, math101).   % Find all teachers qualified for math101
%
qualified(TeacherID, SubjectID) :-
    get_all_teachers(Teachers),
    member(teacher(TeacherID, _, QualifiedSubjects, _, _), Teachers),
    member(SubjectID, QualifiedSubjects).

% ----------------------------------------------------------------------------
% suitable_room/2: Determines if a room is suitable for a session type
% ----------------------------------------------------------------------------
% Format: suitable_room(RoomID, SessionType)
%
% FOL Formula:
%   ∀r ∀t: suitable_room(r, t) ← room(r, _, _, type) ∧ compatible_type(t, type)
%
% Logical Interpretation:
%   A room R is suitable for session type T if the room's type is compatible
%   with the session type according to the compatibility rules.
%
% Usage:
%   ?- suitable_room(r101, theory).  % Check if r101 can host theory sessions
%   ?- suitable_room(R, lab).        % Find all rooms suitable for labs
%
suitable_room(RoomID, SessionType) :-
    get_all_rooms(Rooms),
    member(room(RoomID, _, _, RoomType), Rooms),
    compatible_type(SessionType, RoomType).

% ----------------------------------------------------------------------------
% compatible_type/2: Defines compatibility between session and room types
% ----------------------------------------------------------------------------
% Format: compatible_type(SessionType, RoomType)
%
% FOL Formula:
%   compatible_type(theory, classroom) ← true
%   compatible_type(lab, lab) ← true
%
% Logical Interpretation:
%   Theory sessions require classroom-type rooms.
%   Lab sessions require lab-type rooms.
%   This is a hard constraint for valid timetable generation.
%
% Usage:
%   ?- compatible_type(theory, classroom).  % true
%   ?- compatible_type(theory, lab).        % false
%
compatible_type(theory, classroom).
compatible_type(lab, lab).
compatible_type(tutorial, classroom).  % tutorials use classrooms
compatible_type(tutorial, lab).        % tutorials can also use lab rooms if needed

% ----------------------------------------------------------------------------
% teacher_available/2: Checks if a teacher is available at a time slot
% ----------------------------------------------------------------------------
% Format: teacher_available(TeacherID, SlotID)
%
% FOL Formula:
%   ∀t ∀s: teacher_available(t, s) ← teacher(t, _, _, _, avail) ∧ s ∈ avail
%
% Logical Interpretation:
%   A teacher T is available at time slot S if and only if S is in the
%   teacher's availability list.
%
% Usage:
%   ?- teacher_available(t1, slot1).  % Check if t1 is available at slot1
%   ?- teacher_available(t1, S).      % Find all slots when t1 is available
%
teacher_available(TeacherID, SlotID) :-
    get_all_teachers(Teachers),
    member(teacher(TeacherID, _, _, _, AvailabilityList), Teachers),
    member(SlotID, AvailabilityList).

% ----------------------------------------------------------------------------
% teacher_conflict/3: Detects if a teacher has conflicting assignments
% ----------------------------------------------------------------------------
% Format: teacher_conflict(TeacherID, SlotID, Timetable)
%
% FOL Formula:
%   ∀t ∀s ∀tt: teacher_conflict(t, s, tt) ← 
%     ∃a1 ∃a2: assignment(a1, t, _, s, tt) ∧ 
%              assignment(a2, t, _, s, tt) ∧ 
%              a1 ≠ a2
%
% Logical Interpretation:
%   A teacher conflict exists if the same teacher is assigned to multiple
%   different sessions at the same time slot. This violates the hard
%   constraint that no teacher can be in two places at once.
%
% Note: This predicate assumes assignments are stored in the timetable
%       in a format that can be queried. The actual implementation depends
%       on the timetable data structure used by matrix_model.pl.
%
% Usage:
%   ?- teacher_conflict(t1, slot1, Timetable).  % Check for conflicts
%
teacher_conflict(TeacherID, SlotID, Timetable) :-
    % Find all assignments for this teacher at this slot
    findall(Assignment,
            (member(Row, Timetable),
             member(Cell, Row),
             Cell = assigned(_, _, _, TeacherID, SlotID),
             Assignment = Cell),
            Assignments),
    % Conflict exists if more than one assignment found
    length(Assignments, Count),
    Count > 1.

% ----------------------------------------------------------------------------
% room_conflict/3: Detects if a room has conflicting assignments
% ----------------------------------------------------------------------------
% Format: room_conflict(RoomID, SlotID, Timetable)
%
% FOL Formula:
%   ∀r ∀s ∀tt: room_conflict(r, s, tt) ← 
%     ∃a1 ∃a2: assignment(r, _, _, s, tt) ∧ 
%              assignment(r, _, _, s, tt) ∧ 
%              a1 ≠ a2
%
% Logical Interpretation:
%   A room conflict exists if the same room is assigned to multiple
%   different sessions at the same time slot. This violates the hard
%   constraint that a room can only host one session at a time.
%
% Usage:
%   ?- room_conflict(r101, slot1, Timetable).  % Check for conflicts
%
room_conflict(RoomID, SlotID, Timetable) :-
    % Find all assignments for this room at this slot
    findall(Assignment,
            (member(Row, Timetable),
             member(Cell, Row),
             Cell = assigned(RoomID, _, _, _, SlotID),
             Assignment = Cell),
            Assignments),
    % Conflict exists if more than one assignment found
    length(Assignments, Count),
    Count > 1.

% ============================================================================
% PART 4: QUERY PREDICATES
% ============================================================================
% These predicates provide convenient access to all resources of a given type.
% They use Prolog's findall/3 to collect all matching facts.

% ----------------------------------------------------------------------------
% get_all_teachers/1: Retrieves all teacher facts
% ----------------------------------------------------------------------------
get_all_teachers(Teachers) :-
    findall(teacher(T, N, S, M, A), 
            user:teacher(T, N, S, M, A), 
            AllTeachers),
    list_to_set(AllTeachers, Teachers).

% ----------------------------------------------------------------------------
% get_all_subjects/1: Retrieves all subject facts
% ----------------------------------------------------------------------------
get_all_subjects(Subjects) :-
    findall(subject(S, N, H, T, D), 
            user:subject(S, N, H, T, D), 
            AllSubjects),
    list_to_set(AllSubjects, Subjects).

% ----------------------------------------------------------------------------
% get_all_rooms/1: Retrieves all room facts
% ----------------------------------------------------------------------------
get_all_rooms(Rooms) :-
    findall(room(R, N, C, T), 
            user:room(R, N, C, T), 
            AllRooms),
    list_to_set(AllRooms, Rooms).

% ----------------------------------------------------------------------------
% get_all_timeslots/1: Retrieves all timeslot facts
% ----------------------------------------------------------------------------
get_all_timeslots(Slots) :-
    findall(timeslot(S, D, P, T, Dur), 
            user:timeslot(S, D, P, T, Dur), 
            AllSlots),
    list_to_set(AllSlots, Slots).

% ----------------------------------------------------------------------------
% get_all_classes/1: Retrieves all class facts
% ----------------------------------------------------------------------------
get_all_classes(Classes) :-
    findall(class(C, N, S), 
            user:class(C, N, S), 
            AllClasses),
    list_to_set(AllClasses, Classes).

% ============================================================================
% END OF MODULE
% ============================================================================
% This module provides the foundational knowledge base for the AI-Based
% Timetable Generation System. It demonstrates First Order Logic through:
%
% 1. Facts: Ground instances of predicates representing resources
% 2. Rules: Logical implications for deriving new knowledge
% 3. Queries: Mechanisms to retrieve and reason about stored knowledge
% 4. Inference: Prolog's backward chaining for logical deduction
%
% The knowledge base is designed to be:
% - Dynamic: Facts can be added/removed at runtime
% - Queryable: Supports both ground and non-ground queries
% - Extensible: New rules and facts can be added easily
% - Logical: Follows First Order Logic semantics
% ============================================================================
