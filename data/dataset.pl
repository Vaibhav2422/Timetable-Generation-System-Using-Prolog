% dataset.pl - Example dataset for AI-Based Timetable Generation System
% Designed to produce ZERO conflicts in pre-generation analysis:
%   - Total sessions: 12  (9 theory + 3 lab)
%   - Theory rooms: 9 classrooms  >= 9 theory sessions
%   - Lab rooms: 3 labs            >= 3 lab sessions
%   - Timeslots: 30                >= 12 sessions
%   - Each teacher's max load      >= sessions they are needed for
%   - Every subject has a qualified teacher
%   - Every subject type has a suitable room

:- dynamic teacher/5.
:- dynamic subject/5.
:- dynamic room/4.
:- dynamic timeslot/5.
:- dynamic class/3.
:- dynamic class_size/2.

% ============================================================================
% TEACHERS
% Format: teacher(ID, Name, QualifiedSubjects, MaxLoad, AvailabilityList)
% ============================================================================

% t1 teaches s1,s2 -> needed for c1(s1,s2) + c3(s1) = 3 sessions, maxload 20
teacher(t1, 'Dr. Alice Johnson', [s1, s2], 20, [
    slot1, slot2, slot3, slot4, slot5, slot6,
    slot7, slot8, slot9, slot10, slot11, slot12,
    slot13, slot14, slot15, slot16, slot17, slot18,
    slot19, slot20, slot21, slot22, slot23, slot24,
    slot25, slot26, slot27, slot28, slot29, slot30
]).

% t2 teaches s3,s4 -> needed for c1(s3) + c2(s3,s4) = 3 sessions, maxload 20
teacher(t2, 'Prof. Bob Smith', [s3, s4], 20, [
    slot1, slot2, slot3, slot4, slot5, slot6,
    slot7, slot8, slot9, slot10, slot11, slot12,
    slot13, slot14, slot15, slot16, slot17, slot18,
    slot19, slot20, slot21, slot22, slot23, slot24,
    slot25, slot26, slot27, slot28, slot29, slot30
]).

% t3 teaches s5,s6 -> needed for c2(s5) + c3(s5,s6) = 3 sessions, maxload 20
teacher(t3, 'Dr. Carol Williams', [s5, s6], 20, [
    slot1, slot2, slot3, slot4, slot5, slot6,
    slot7, slot8, slot9, slot10, slot11, slot12,
    slot13, slot14, slot15, slot16, slot17, slot18,
    slot19, slot20, slot21, slot22, slot23, slot24,
    slot25, slot26, slot27, slot28, slot29, slot30
]).

% t4 teaches s7 (lab) -> needed for c1(s7) + c3(s7) = 2 sessions, maxload 20
teacher(t4, 'Mr. David Brown', [s7], 20, [
    slot1, slot2, slot3, slot4, slot5, slot6,
    slot7, slot8, slot9, slot10, slot11, slot12,
    slot13, slot14, slot15, slot16, slot17, slot18,
    slot19, slot20, slot21, slot22, slot23, slot24,
    slot25, slot26, slot27, slot28, slot29, slot30
]).

% t5 teaches s8 (lab) -> needed for c2(s8) = 1 session, maxload 20
teacher(t5, 'Ms. Emma Davis', [s8], 20, [
    slot1, slot2, slot3, slot4, slot5, slot6,
    slot7, slot8, slot9, slot10, slot11, slot12,
    slot13, slot14, slot15, slot16, slot17, slot18,
    slot19, slot20, slot21, slot22, slot23, slot24,
    slot25, slot26, slot27, slot28, slot29, slot30
]).

% ============================================================================
% SUBJECTS
% Format: subject(ID, Name, WeeklyHours, Type, Duration)
% s1-s6: theory (1h sessions), s7-s8: lab (2h sessions)
% ============================================================================

subject(s1, 'Data Structures',      3, theory, 1).
subject(s2, 'Algorithms',           3, theory, 1).
subject(s3, 'Database Systems',     3, theory, 1).
subject(s4, 'Operating Systems',    3, theory, 1).
subject(s5, 'Computer Networks',    3, theory, 1).
subject(s6, 'Software Engineering', 3, theory, 1).
subject(s7, 'Database Lab',         2, lab,    2).
subject(s8, 'Networks Lab',         2, lab,    2).

% ============================================================================
% ROOMS
% 9 classrooms >= 9 theory sessions
% 3 labs       >= 3 lab sessions
% ============================================================================

room(r1,  'Room 101', 50, classroom).
room(r2,  'Room 102', 50, classroom).
room(r3,  'Room 103', 50, classroom).
room(r4,  'Room 104', 50, classroom).
room(r5,  'Room 105', 50, classroom).
room(r6,  'Room 106', 50, classroom).
room(r7,  'Room 107', 50, classroom).
room(r8,  'Room 108', 50, classroom).
room(r9,  'Room 109', 50, classroom).
room(r10, 'Lab A',    50, lab).
room(r11, 'Lab B',    50, lab).
room(r12, 'Lab C',    50, lab).

% ============================================================================
% TIME SLOTS  (30 slots >= 12 sessions)
% ============================================================================

timeslot(slot1,  monday,    1, '09:00', 1).
timeslot(slot2,  monday,    2, '10:00', 1).
timeslot(slot3,  monday,    3, '11:00', 1).
timeslot(slot4,  monday,    4, '12:00', 1).
timeslot(slot5,  monday,    5, '14:00', 1).
timeslot(slot6,  monday,    6, '15:00', 1).
timeslot(slot7,  tuesday,   1, '09:00', 1).
timeslot(slot8,  tuesday,   2, '10:00', 1).
timeslot(slot9,  tuesday,   3, '11:00', 1).
timeslot(slot10, tuesday,   4, '12:00', 1).
timeslot(slot11, tuesday,   5, '14:00', 1).
timeslot(slot12, tuesday,   6, '15:00', 1).
timeslot(slot13, wednesday, 1, '09:00', 1).
timeslot(slot14, wednesday, 2, '10:00', 1).
timeslot(slot15, wednesday, 3, '11:00', 1).
timeslot(slot16, wednesday, 4, '12:00', 1).
timeslot(slot17, wednesday, 5, '14:00', 1).
timeslot(slot18, wednesday, 6, '15:00', 1).
timeslot(slot19, thursday,  1, '09:00', 1).
timeslot(slot20, thursday,  2, '10:00', 1).
timeslot(slot21, thursday,  3, '11:00', 1).
timeslot(slot22, thursday,  4, '12:00', 1).
timeslot(slot23, thursday,  5, '14:00', 1).
timeslot(slot24, thursday,  6, '15:00', 1).
timeslot(slot25, friday,    1, '09:00', 1).
timeslot(slot26, friday,    2, '10:00', 1).
timeslot(slot27, friday,    3, '11:00', 1).
timeslot(slot28, friday,    4, '12:00', 1).
timeslot(slot29, friday,    5, '14:00', 1).
timeslot(slot30, friday,    6, '15:00', 1).

% ============================================================================
% CLASSES
% 3 classes x 4 subjects = 12 sessions total
%   Theory sessions: c1(s1,s2,s3) + c2(s3,s4,s5) + c3(s1,s5,s6) = 9
%   Lab sessions:    c1(s7) + c2(s8) + c3(s7)                    = 3
% ============================================================================

class(c1, 'CS-A', [s1, s2, s3, s7]).
class(c2, 'CS-B', [s3, s4, s5, s8]).
class(c3, 'CS-C', [s1, s5, s6, s7]).

% ============================================================================
% CLASS SIZES
% ============================================================================

class_size(c1, 45).
class_size(c2, 40).
class_size(c3, 42).

% ============================================================================
% SUMMARY
%   Teachers  : 5  (each qualified for exactly the subjects they teach)
%   Subjects  : 8  (6 theory + 2 lab)
%   Rooms     : 12 (9 classrooms + 3 labs)
%   Timeslots : 30 (5 days x 6 periods)
%   Classes   : 3
%   Sessions  : 12 (9 theory + 3 lab)
%
%   Conflict checks:
%     theory sessions (9) <= classrooms (9)  -> OK
%     lab sessions    (3) <= labs        (3) -> OK
%     total sessions (12) <= timeslots  (30) -> OK
%     teacher loads all within maxload       -> OK
% ============================================================================
