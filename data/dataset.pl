% dataset.pl - Example dataset for AI-Based Timetable Generation System
% This file contains sample data for testing the timetable generation system
% Includes: 5 teachers, 8 subjects, 6 rooms, 30 time slots, 3 classes

% Make all facts dynamic so they can be retracted when new resources are submitted
:- dynamic teacher/5.
:- dynamic subject/5.
:- dynamic room/4.
:- dynamic timeslot/5.
:- dynamic class/3.
:- dynamic class_size/2.

% ============================================================================
% TEACHERS
% Format: teacher(ID, Name, QualifiedSubjects, MaxLoad, AvailabilityList)
% - ID: Unique teacher identifier
% - Name: Teacher's full name
% - QualifiedSubjects: List of subject IDs the teacher can teach
% - MaxLoad: Maximum weekly teaching hours
% - AvailabilityList: List of time slot IDs when teacher is available
% ============================================================================

teacher(t1, 'Dr. Alice Johnson', [s1, s2], 20, [
    slot1, slot2, slot3, slot4, slot5, slot6,
    slot7, slot8, slot9, slot10, slot11, slot12,
    slot13, slot14, slot15, slot16, slot17, slot18,
    slot19, slot20, slot21, slot22, slot23, slot24
]).

teacher(t2, 'Prof. Bob Smith', [s3, s4], 18, [
    slot1, slot2, slot3, slot4, slot5, slot6,
    slot7, slot8, slot9, slot10, slot11, slot12,
    slot13, slot14, slot15, slot16, slot17, slot18,
    slot25, slot26, slot27, slot28, slot29, slot30
]).

teacher(t3, 'Dr. Carol Williams', [s5, s6], 20, [
    slot1, slot2, slot3, slot4, slot5, slot6,
    slot7, slot8, slot9, slot10, slot11, slot12,
    slot19, slot20, slot21, slot22, slot23, slot24,
    slot25, slot26, slot27, slot28, slot29, slot30
]).

teacher(t4, 'Mr. David Brown', [s7, s8], 16, [
    slot7, slot8, slot9, slot10, slot11, slot12,
    slot13, slot14, slot15, slot16, slot17, slot18,
    slot19, slot20, slot21, slot22, slot23, slot24,
    slot25, slot26, slot27, slot28, slot29, slot30
]).

teacher(t5, 'Ms. Emma Davis', [s1, s3, s5], 22, [
    slot1, slot2, slot3, slot4, slot5, slot6,
    slot7, slot8, slot9, slot10, slot11, slot12,
    slot13, slot14, slot15, slot16, slot17, slot18,
    slot19, slot20, slot21, slot22, slot23, slot24,
    slot25, slot26, slot27, slot28, slot29, slot30
]).

% ============================================================================
% SUBJECTS
% Format: subject(ID, Name, WeeklyHours, Type, Duration)
% - ID: Unique subject identifier
% - Name: Subject name
% - WeeklyHours: Required hours per week
% - Type: theory or lab
% - Duration: Hours per session (1 for theory, 2 for lab)
% ============================================================================

subject(s1, 'Data Structures', 4, theory, 1).
subject(s2, 'Algorithms', 3, theory, 1).
subject(s3, 'Database Systems', 4, theory, 1).
subject(s4, 'Operating Systems', 3, theory, 1).
subject(s5, 'Computer Networks', 4, theory, 1).
subject(s6, 'Software Engineering', 3, theory, 1).
subject(s7, 'Database Lab', 2, lab, 2).
subject(s8, 'Networks Lab', 2, lab, 2).

% ============================================================================
% ROOMS
% Format: room(ID, Name, Capacity, Type)
% - ID: Unique room identifier
% - Name: Room number or name
% - Capacity: Maximum number of students
% - Type: classroom or lab
% ============================================================================

room(r1, 'Room 101', 50, classroom).
room(r2, 'Room 102', 45, classroom).
room(r3, 'Room 103', 40, classroom).
room(r4, 'Lab A', 50, lab).
room(r5, 'Lab B', 50, lab).
room(r6, 'Room 201', 60, classroom).

% ============================================================================
% TIME SLOTS
% Format: timeslot(ID, Day, Period, StartTime, Duration)
% - ID: Unique time slot identifier
% - Day: monday, tuesday, wednesday, thursday, friday
% - Period: Period number (1-6)
% - StartTime: Start time in 24-hour format
% - Duration: Duration in hours
% ============================================================================

% Monday slots
timeslot(slot1, monday, 1, '09:00', 1).
timeslot(slot2, monday, 2, '10:00', 1).
timeslot(slot3, monday, 3, '11:00', 1).
timeslot(slot4, monday, 4, '12:00', 1).
timeslot(slot5, monday, 5, '14:00', 1).
timeslot(slot6, monday, 6, '15:00', 1).

% Tuesday slots
timeslot(slot7, tuesday, 1, '09:00', 1).
timeslot(slot8, tuesday, 2, '10:00', 1).
timeslot(slot9, tuesday, 3, '11:00', 1).
timeslot(slot10, tuesday, 4, '12:00', 1).
timeslot(slot11, tuesday, 5, '14:00', 1).
timeslot(slot12, tuesday, 6, '15:00', 1).

% Wednesday slots
timeslot(slot13, wednesday, 1, '09:00', 1).
timeslot(slot14, wednesday, 2, '10:00', 1).
timeslot(slot15, wednesday, 3, '11:00', 1).
timeslot(slot16, wednesday, 4, '12:00', 1).
timeslot(slot17, wednesday, 5, '14:00', 1).
timeslot(slot18, wednesday, 6, '15:00', 1).

% Thursday slots
timeslot(slot19, thursday, 1, '09:00', 1).
timeslot(slot20, thursday, 2, '10:00', 1).
timeslot(slot21, thursday, 3, '11:00', 1).
timeslot(slot22, thursday, 4, '12:00', 1).
timeslot(slot23, thursday, 5, '14:00', 1).
timeslot(slot24, thursday, 6, '15:00', 1).

% Friday slots
timeslot(slot25, friday, 1, '09:00', 1).
timeslot(slot26, friday, 2, '10:00', 1).
timeslot(slot27, friday, 3, '11:00', 1).
timeslot(slot28, friday, 4, '12:00', 1).
timeslot(slot29, friday, 5, '14:00', 1).
timeslot(slot30, friday, 6, '15:00', 1).

% ============================================================================
% CLASSES
% Format: class(ID, Name, SubjectList)
% - ID: Unique class identifier
% - Name: Class name or section
% - SubjectList: List of subject IDs assigned to this class
% ============================================================================

class(c1, 'CS-A', [s1, s2, s3, s7]).
class(c2, 'CS-B', [s3, s4, s5, s8]).
class(c3, 'CS-C', [s1, s5, s6, s7]).

% ============================================================================
% HELPER PREDICATES
% ============================================================================

% Get class size (for capacity checking)
class_size(c1, 45).
class_size(c2, 40).
class_size(c3, 42).

% ============================================================================
% STATISTICS
% ============================================================================
% Total Teachers: 5
% Total Subjects: 8 (6 theory + 2 lab)
% Total Rooms: 6 (4 classrooms + 2 labs)
% Total Time Slots: 30 (5 days × 6 periods)
% Total Classes: 3
% ============================================================================
