% ============================================================================
% performance_test.pl - Performance Testing for Timetable Generation
% ============================================================================
% Tests timetable generation performance with different problem sizes.
%
% Requirements: 15.1, 15.2
%   - 3 classes, 8 subjects: must complete within 30 seconds
%   - 5 classes, 10 subjects: must complete within 2 minutes (120 seconds)
%   - 10 classes, 15 subjects: observe performance (no pass/fail threshold)
%
% Usage:
%   swipl -g "use_module(tests/performance_test), run_performance_tests, halt" -t halt
% ============================================================================

:- module(performance_test, [run_performance_tests/0]).

:- use_module(library(lists)).
:- use_module(backend/timetable_generator).
:- use_module(backend/knowledge_base).
:- use_module(backend/logging).

% ============================================================================
% Small Dataset: 3 classes, 8 subjects, 6 rooms, 30 time slots
% ============================================================================

load_small_dataset :-
    % Teachers (3 teachers covering 8 subjects)
    assert(teacher(t1, 'Alice Brown',   [s1,s2,s3,s4], 20, [ts1,ts2,ts3,ts4,ts5,ts6,ts7,ts8,ts9,ts10,ts11,ts12,ts13,ts14,ts15])),
    assert(teacher(t2, 'Bob Carter',    [s3,s4,s5,s6], 20, [ts1,ts2,ts3,ts4,ts5,ts6,ts7,ts8,ts9,ts10,ts11,ts12,ts13,ts14,ts15])),
    assert(teacher(t3, 'Carol Davis',   [s5,s6,s7,s8], 20, [ts16,ts17,ts18,ts19,ts20,ts21,ts22,ts23,ts24,ts25,ts26,ts27,ts28,ts29,ts30])),
    % Subjects (8 subjects: mix of theory and lab)
    assert(subject(s1, 'Mathematics',       3, theory, 1)),
    assert(subject(s2, 'Physics',           2, theory, 1)),
    assert(subject(s3, 'Chemistry',         2, lab,    2)),
    assert(subject(s4, 'English',           3, theory, 1)),
    assert(subject(s5, 'Computer Science',  2, lab,    2)),
    assert(subject(s6, 'History',           2, theory, 1)),
    assert(subject(s7, 'Biology',           2, lab,    2)),
    assert(subject(s8, 'Geography',         2, theory, 1)),
    % Rooms (6 rooms: 4 classrooms + 2 labs)
    assert(room(r1, 'Room 101', 40, classroom)),
    assert(room(r2, 'Room 102', 40, classroom)),
    assert(room(r3, 'Room 103', 35, classroom)),
    assert(room(r4, 'Room 104', 35, classroom)),
    assert(room(r5, 'Lab A',    30, lab)),
    assert(room(r6, 'Lab B',    30, lab)),
    % Time slots (30 slots: Mon-Fri, 6 periods/day)
    assert(timeslot(ts1,  monday,    1, '08:00', 1)),
    assert(timeslot(ts2,  monday,    2, '09:00', 1)),
    assert(timeslot(ts3,  monday,    3, '10:00', 1)),
    assert(timeslot(ts4,  monday,    4, '11:00', 1)),
    assert(timeslot(ts5,  monday,    5, '13:00', 1)),
    assert(timeslot(ts6,  monday,    6, '14:00', 1)),
    assert(timeslot(ts7,  tuesday,   1, '08:00', 1)),
    assert(timeslot(ts8,  tuesday,   2, '09:00', 1)),
    assert(timeslot(ts9,  tuesday,   3, '10:00', 1)),
    assert(timeslot(ts10, tuesday,   4, '11:00', 1)),
    assert(timeslot(ts11, tuesday,   5, '13:00', 1)),
    assert(timeslot(ts12, tuesday,   6, '14:00', 1)),
    assert(timeslot(ts13, wednesday, 1, '08:00', 1)),
    assert(timeslot(ts14, wednesday, 2, '09:00', 1)),
    assert(timeslot(ts15, wednesday, 3, '10:00', 1)),
    assert(timeslot(ts16, wednesday, 4, '11:00', 1)),
    assert(timeslot(ts17, wednesday, 5, '13:00', 1)),
    assert(timeslot(ts18, wednesday, 6, '14:00', 1)),
    assert(timeslot(ts19, thursday,  1, '08:00', 1)),
    assert(timeslot(ts20, thursday,  2, '09:00', 1)),
    assert(timeslot(ts21, thursday,  3, '10:00', 1)),
    assert(timeslot(ts22, thursday,  4, '11:00', 1)),
    assert(timeslot(ts23, thursday,  5, '13:00', 1)),
    assert(timeslot(ts24, thursday,  6, '14:00', 1)),
    assert(timeslot(ts25, friday,    1, '08:00', 1)),
    assert(timeslot(ts26, friday,    2, '09:00', 1)),
    assert(timeslot(ts27, friday,    3, '10:00', 1)),
    assert(timeslot(ts28, friday,    4, '11:00', 1)),
    assert(timeslot(ts29, friday,    5, '13:00', 1)),
    assert(timeslot(ts30, friday,    6, '14:00', 1)),
    % Classes (3 classes, each with 8 subjects)
    assert(class(c1, 'Class A', [s1,s2,s3,s4,s5,s6,s7,s8])),
    assert(class(c2, 'Class B', [s1,s2,s3,s4,s5,s6,s7,s8])),
    assert(class(c3, 'Class C', [s1,s2,s3,s4,s5,s6,s7,s8])).

% ============================================================================
% Medium Dataset: 5 classes, 10 subjects, 8 rooms, 40 time slots
% ============================================================================

load_medium_dataset :-
    % Teachers (5 teachers covering 10 subjects)
    assert(teacher(t1, 'Alice Brown',   [s1,s2,s3,s4],    20, [ts1,ts2,ts3,ts4,ts5,ts6,ts7,ts8,ts9,ts10,ts11,ts12,ts13,ts14,ts15,ts16,ts17,ts18,ts19,ts20])),
    assert(teacher(t2, 'Bob Carter',    [s3,s4,s5,s6],    20, [ts1,ts2,ts3,ts4,ts5,ts6,ts7,ts8,ts9,ts10,ts11,ts12,ts13,ts14,ts15,ts16,ts17,ts18,ts19,ts20])),
    assert(teacher(t3, 'Carol Davis',   [s5,s6,s7,s8],    20, [ts21,ts22,ts23,ts24,ts25,ts26,ts27,ts28,ts29,ts30,ts31,ts32,ts33,ts34,ts35,ts36,ts37,ts38,ts39,ts40])),
    assert(teacher(t4, 'David Evans',   [s7,s8,s9,s10],   20, [ts1,ts2,ts3,ts4,ts5,ts6,ts7,ts8,ts9,ts10,ts21,ts22,ts23,ts24,ts25,ts26,ts27,ts28,ts29,ts30])),
    assert(teacher(t5, 'Emma Foster',   [s1,s9,s10,s2],   20, [ts11,ts12,ts13,ts14,ts15,ts16,ts17,ts18,ts19,ts20,ts31,ts32,ts33,ts34,ts35,ts36,ts37,ts38,ts39,ts40])),
    % Subjects (10 subjects: mix of theory and lab)
    assert(subject(s1,  'Mathematics',       3, theory, 1)),
    assert(subject(s2,  'Physics',           2, theory, 1)),
    assert(subject(s3,  'Chemistry',         2, lab,    2)),
    assert(subject(s4,  'English',           3, theory, 1)),
    assert(subject(s5,  'Computer Science',  2, lab,    2)),
    assert(subject(s6,  'History',           2, theory, 1)),
    assert(subject(s7,  'Biology',           2, lab,    2)),
    assert(subject(s8,  'Geography',         2, theory, 1)),
    assert(subject(s9,  'Economics',         2, theory, 1)),
    assert(subject(s10, 'Statistics',        2, theory, 1)),
    % Rooms (8 rooms: 5 classrooms + 3 labs)
    assert(room(r1, 'Room 101', 40, classroom)),
    assert(room(r2, 'Room 102', 40, classroom)),
    assert(room(r3, 'Room 103', 35, classroom)),
    assert(room(r4, 'Room 104', 35, classroom)),
    assert(room(r5, 'Room 105', 30, classroom)),
    assert(room(r6, 'Lab A',    30, lab)),
    assert(room(r7, 'Lab B',    30, lab)),
    assert(room(r8, 'Lab C',    25, lab)),
    % Time slots (40 slots: Mon-Fri, 8 periods/day)
    assert(timeslot(ts1,  monday,    1, '08:00', 1)),
    assert(timeslot(ts2,  monday,    2, '09:00', 1)),
    assert(timeslot(ts3,  monday,    3, '10:00', 1)),
    assert(timeslot(ts4,  monday,    4, '11:00', 1)),
    assert(timeslot(ts5,  monday,    5, '12:00', 1)),
    assert(timeslot(ts6,  monday,    6, '13:00', 1)),
    assert(timeslot(ts7,  monday,    7, '14:00', 1)),
    assert(timeslot(ts8,  monday,    8, '15:00', 1)),
    assert(timeslot(ts9,  tuesday,   1, '08:00', 1)),
    assert(timeslot(ts10, tuesday,   2, '09:00', 1)),
    assert(timeslot(ts11, tuesday,   3, '10:00', 1)),
    assert(timeslot(ts12, tuesday,   4, '11:00', 1)),
    assert(timeslot(ts13, tuesday,   5, '12:00', 1)),
    assert(timeslot(ts14, tuesday,   6, '13:00', 1)),
    assert(timeslot(ts15, tuesday,   7, '14:00', 1)),
    assert(timeslot(ts16, tuesday,   8, '15:00', 1)),
    assert(timeslot(ts17, wednesday, 1, '08:00', 1)),
    assert(timeslot(ts18, wednesday, 2, '09:00', 1)),
    assert(timeslot(ts19, wednesday, 3, '10:00', 1)),
    assert(timeslot(ts20, wednesday, 4, '11:00', 1)),
    assert(timeslot(ts21, wednesday, 5, '12:00', 1)),
    assert(timeslot(ts22, wednesday, 6, '13:00', 1)),
    assert(timeslot(ts23, wednesday, 7, '14:00', 1)),
    assert(timeslot(ts24, wednesday, 8, '15:00', 1)),
    assert(timeslot(ts25, thursday,  1, '08:00', 1)),
    assert(timeslot(ts26, thursday,  2, '09:00', 1)),
    assert(timeslot(ts27, thursday,  3, '10:00', 1)),
    assert(timeslot(ts28, thursday,  4, '11:00', 1)),
    assert(timeslot(ts29, thursday,  5, '12:00', 1)),
    assert(timeslot(ts30, thursday,  6, '13:00', 1)),
    assert(timeslot(ts31, thursday,  7, '14:00', 1)),
    assert(timeslot(ts32, thursday,  8, '15:00', 1)),
    assert(timeslot(ts33, friday,    1, '08:00', 1)),
    assert(timeslot(ts34, friday,    2, '09:00', 1)),
    assert(timeslot(ts35, friday,    3, '10:00', 1)),
    assert(timeslot(ts36, friday,    4, '11:00', 1)),
    assert(timeslot(ts37, friday,    5, '12:00', 1)),
    assert(timeslot(ts38, friday,    6, '13:00', 1)),
    assert(timeslot(ts39, friday,    7, '14:00', 1)),
    assert(timeslot(ts40, friday,    8, '15:00', 1)),
    % Classes (5 classes, each with 10 subjects)
    assert(class(c1, 'Class A', [s1,s2,s3,s4,s5,s6,s7,s8,s9,s10])),
    assert(class(c2, 'Class B', [s1,s2,s3,s4,s5,s6,s7,s8,s9,s10])),
    assert(class(c3, 'Class C', [s1,s2,s3,s4,s5,s6,s7,s8,s9,s10])),
    assert(class(c4, 'Class D', [s1,s2,s3,s4,s5,s6,s7,s8,s9,s10])),
    assert(class(c5, 'Class E', [s1,s2,s3,s4,s5,s6,s7,s8,s9,s10])).

% ============================================================================
% Large Dataset: 10 classes, 15 subjects, 12 rooms, 50 time slots
% ============================================================================

load_large_dataset :-
    % Teachers (8 teachers covering 15 subjects)
    assert(teacher(t1,  'Alice Brown',    [s1,s2,s3,s4],       25, [ts1,ts2,ts3,ts4,ts5,ts6,ts7,ts8,ts9,ts10,ts11,ts12,ts13,ts14,ts15,ts16,ts17,ts18,ts19,ts20,ts21,ts22,ts23,ts24,ts25])),
    assert(teacher(t2,  'Bob Carter',     [s3,s4,s5,s6],       25, [ts1,ts2,ts3,ts4,ts5,ts6,ts7,ts8,ts9,ts10,ts11,ts12,ts13,ts14,ts15,ts16,ts17,ts18,ts19,ts20,ts21,ts22,ts23,ts24,ts25])),
    assert(teacher(t3,  'Carol Davis',    [s5,s6,s7,s8],       25, [ts26,ts27,ts28,ts29,ts30,ts31,ts32,ts33,ts34,ts35,ts36,ts37,ts38,ts39,ts40,ts41,ts42,ts43,ts44,ts45,ts46,ts47,ts48,ts49,ts50])),
    assert(teacher(t4,  'David Evans',    [s7,s8,s9,s10],      25, [ts1,ts2,ts3,ts4,ts5,ts6,ts7,ts8,ts9,ts10,ts26,ts27,ts28,ts29,ts30,ts31,ts32,ts33,ts34,ts35,ts41,ts42,ts43,ts44,ts45])),
    assert(teacher(t5,  'Emma Foster',    [s9,s10,s11,s12],    25, [ts11,ts12,ts13,ts14,ts15,ts16,ts17,ts18,ts19,ts20,ts36,ts37,ts38,ts39,ts40,ts41,ts42,ts43,ts44,ts45,ts46,ts47,ts48,ts49,ts50])),
    assert(teacher(t6,  'Frank Green',    [s11,s12,s13,s14],   25, [ts1,ts2,ts3,ts4,ts5,ts6,ts7,ts8,ts9,ts10,ts21,ts22,ts23,ts24,ts25,ts26,ts27,ts28,ts29,ts30,ts31,ts32,ts33,ts34,ts35])),
    assert(teacher(t7,  'Grace Harris',   [s13,s14,s15,s1],    25, [ts11,ts12,ts13,ts14,ts15,ts16,ts17,ts18,ts19,ts20,ts36,ts37,ts38,ts39,ts40,ts46,ts47,ts48,ts49,ts50,ts21,ts22,ts23,ts24,ts25])),
    assert(teacher(t8,  'Henry Irving',   [s2,s6,s10,s14,s15], 25, [ts1,ts2,ts3,ts4,ts5,ts6,ts7,ts8,ts9,ts10,ts11,ts12,ts13,ts14,ts15,ts16,ts17,ts18,ts19,ts20,ts21,ts22,ts23,ts24,ts25])),
    % Subjects (15 subjects: mix of theory and lab)
    assert(subject(s1,  'Mathematics',       3, theory, 1)),
    assert(subject(s2,  'Physics',           2, theory, 1)),
    assert(subject(s3,  'Chemistry',         2, lab,    2)),
    assert(subject(s4,  'English',           3, theory, 1)),
    assert(subject(s5,  'Computer Science',  2, lab,    2)),
    assert(subject(s6,  'History',           2, theory, 1)),
    assert(subject(s7,  'Biology',           2, lab,    2)),
    assert(subject(s8,  'Geography',         2, theory, 1)),
    assert(subject(s9,  'Economics',         2, theory, 1)),
    assert(subject(s10, 'Statistics',        2, theory, 1)),
    assert(subject(s11, 'Philosophy',        2, theory, 1)),
    assert(subject(s12, 'Sociology',         2, theory, 1)),
    assert(subject(s13, 'Psychology',        2, theory, 1)),
    assert(subject(s14, 'Art',               2, lab,    2)),
    assert(subject(s15, 'Music',             2, theory, 1)),
    % Rooms (12 rooms: 8 classrooms + 4 labs)
    assert(room(r1,  'Room 101', 45, classroom)),
    assert(room(r2,  'Room 102', 45, classroom)),
    assert(room(r3,  'Room 103', 40, classroom)),
    assert(room(r4,  'Room 104', 40, classroom)),
    assert(room(r5,  'Room 105', 35, classroom)),
    assert(room(r6,  'Room 106', 35, classroom)),
    assert(room(r7,  'Room 107', 30, classroom)),
    assert(room(r8,  'Room 108', 30, classroom)),
    assert(room(r9,  'Lab A',    30, lab)),
    assert(room(r10, 'Lab B',    30, lab)),
    assert(room(r11, 'Lab C',    25, lab)),
    assert(room(r12, 'Lab D',    25, lab)),
    % Time slots (50 slots: Mon-Fri, 10 periods/day)
    assert(timeslot(ts1,  monday,    1,  '07:00', 1)),
    assert(timeslot(ts2,  monday,    2,  '08:00', 1)),
    assert(timeslot(ts3,  monday,    3,  '09:00', 1)),
    assert(timeslot(ts4,  monday,    4,  '10:00', 1)),
    assert(timeslot(ts5,  monday,    5,  '11:00', 1)),
    assert(timeslot(ts6,  monday,    6,  '12:00', 1)),
    assert(timeslot(ts7,  monday,    7,  '13:00', 1)),
    assert(timeslot(ts8,  monday,    8,  '14:00', 1)),
    assert(timeslot(ts9,  monday,    9,  '15:00', 1)),
    assert(timeslot(ts10, monday,    10, '16:00', 1)),
    assert(timeslot(ts11, tuesday,   1,  '07:00', 1)),
    assert(timeslot(ts12, tuesday,   2,  '08:00', 1)),
    assert(timeslot(ts13, tuesday,   3,  '09:00', 1)),
    assert(timeslot(ts14, tuesday,   4,  '10:00', 1)),
    assert(timeslot(ts15, tuesday,   5,  '11:00', 1)),
    assert(timeslot(ts16, tuesday,   6,  '12:00', 1)),
    assert(timeslot(ts17, tuesday,   7,  '13:00', 1)),
    assert(timeslot(ts18, tuesday,   8,  '14:00', 1)),
    assert(timeslot(ts19, tuesday,   9,  '15:00', 1)),
    assert(timeslot(ts20, tuesday,   10, '16:00', 1)),
    assert(timeslot(ts21, wednesday, 1,  '07:00', 1)),
    assert(timeslot(ts22, wednesday, 2,  '08:00', 1)),
    assert(timeslot(ts23, wednesday, 3,  '09:00', 1)),
    assert(timeslot(ts24, wednesday, 4,  '10:00', 1)),
    assert(timeslot(ts25, wednesday, 5,  '11:00', 1)),
    assert(timeslot(ts26, wednesday, 6,  '12:00', 1)),
    assert(timeslot(ts27, wednesday, 7,  '13:00', 1)),
    assert(timeslot(ts28, wednesday, 8,  '14:00', 1)),
    assert(timeslot(ts29, wednesday, 9,  '15:00', 1)),
    assert(timeslot(ts30, wednesday, 10, '16:00', 1)),
    assert(timeslot(ts31, thursday,  1,  '07:00', 1)),
    assert(timeslot(ts32, thursday,  2,  '08:00', 1)),
    assert(timeslot(ts33, thursday,  3,  '09:00', 1)),
    assert(timeslot(ts34, thursday,  4,  '10:00', 1)),
    assert(timeslot(ts35, thursday,  5,  '11:00', 1)),
    assert(timeslot(ts36, thursday,  6,  '12:00', 1)),
    assert(timeslot(ts37, thursday,  7,  '13:00', 1)),
    assert(timeslot(ts38, thursday,  8,  '14:00', 1)),
    assert(timeslot(ts39, thursday,  9,  '15:00', 1)),
    assert(timeslot(ts40, thursday,  10, '16:00', 1)),
    assert(timeslot(ts41, friday,    1,  '07:00', 1)),
    assert(timeslot(ts42, friday,    2,  '08:00', 1)),
    assert(timeslot(ts43, friday,    3,  '09:00', 1)),
    assert(timeslot(ts44, friday,    4,  '10:00', 1)),
    assert(timeslot(ts45, friday,    5,  '11:00', 1)),
    assert(timeslot(ts46, friday,    6,  '12:00', 1)),
    assert(timeslot(ts47, friday,    7,  '13:00', 1)),
    assert(timeslot(ts48, friday,    8,  '14:00', 1)),
    assert(timeslot(ts49, friday,    9,  '15:00', 1)),
    assert(timeslot(ts50, friday,    10, '16:00', 1)),
    % Classes (10 classes, each with 15 subjects)
    assert(class(c1,  'Class A',  [s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15])),
    assert(class(c2,  'Class B',  [s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15])),
    assert(class(c3,  'Class C',  [s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15])),
    assert(class(c4,  'Class D',  [s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15])),
    assert(class(c5,  'Class E',  [s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15])),
    assert(class(c6,  'Class F',  [s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15])),
    assert(class(c7,  'Class G',  [s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15])),
    assert(class(c8,  'Class H',  [s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15])),
    assert(class(c9,  'Class I',  [s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15])),
    assert(class(c10, 'Class J',  [s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15])).

% ============================================================================
% Cleanup: retract all dynamic facts between tests
% ============================================================================

cleanup_dataset :-
    retractall(teacher(_, _, _, _, _)),
    retractall(subject(_, _, _, _, _)),
    retractall(room(_, _, _, _)),
    retractall(timeslot(_, _, _, _, _)),
    retractall(class(_, _, _)).

% ============================================================================
% Individual performance test runners
% ============================================================================

%% run_small_test/0
%  Validates: Requirements 15.1
%  Loads the small dataset (3 classes, 8 subjects), runs generate_timetable/1,
%  and reports PASS if elapsed time is <= 30 seconds.
run_small_test :-
    format('[PERF] Running small dataset test (3 classes, 8 subjects)...~n'),
    cleanup_dataset,
    load_small_dataset,
    get_time(Start),
    catch(
        generate_timetable(_Timetable),
        Error,
        (
            get_time(End),
            Elapsed is End - Start,
            format('[PERF] Small dataset (3 classes): ~2fs - ERROR: ~w~n', [Elapsed, Error]),
            cleanup_dataset,
            fail
        )
    ),
    get_time(End),
    Elapsed is End - Start,
    Threshold = 30.0,
    (   Elapsed =< Threshold
    ->  format('[PERF] Small dataset (3 classes): ~2fs - PASS~n', [Elapsed])
    ;   format('[PERF] Small dataset (3 classes): ~2fs - FAIL (exceeded ~ws threshold)~n', [Elapsed, Threshold])
    ),
    cleanup_dataset.

%% run_medium_test/0
%  Validates: Requirements 15.2
%  Loads the medium dataset (5 classes, 10 subjects), runs generate_timetable/1,
%  and reports PASS if elapsed time is <= 120 seconds.
run_medium_test :-
    format('[PERF] Running medium dataset test (5 classes, 10 subjects)...~n'),
    cleanup_dataset,
    load_medium_dataset,
    get_time(Start),
    catch(
        generate_timetable(_Timetable),
        Error,
        (
            get_time(End),
            Elapsed is End - Start,
            format('[PERF] Medium dataset (5 classes): ~2fs - ERROR: ~w~n', [Elapsed, Error]),
            cleanup_dataset,
            fail
        )
    ),
    get_time(End),
    Elapsed is End - Start,
    Threshold = 120.0,
    (   Elapsed =< Threshold
    ->  format('[PERF] Medium dataset (5 classes): ~2fs - PASS~n', [Elapsed])
    ;   format('[PERF] Medium dataset (5 classes): ~2fs - FAIL (exceeded ~ws threshold)~n', [Elapsed, Threshold])
    ),
    cleanup_dataset.

%% run_large_test/0
%  Validates: Requirements 15.1, 15.2 (observe only - no pass/fail threshold)
%  Loads the large dataset (10 classes, 15 subjects), runs generate_timetable/1,
%  and reports elapsed time for observation.
run_large_test :-
    format('[PERF] Running large dataset test (10 classes, 15 subjects)...~n'),
    cleanup_dataset,
    load_large_dataset,
    get_time(Start),
    catch(
        generate_timetable(_Timetable),
        Error,
        (
            get_time(End),
            Elapsed is End - Start,
            format('[PERF] Large dataset (10 classes): ~2fs - ERROR: ~w~n', [Elapsed, Error]),
            cleanup_dataset,
            fail
        )
    ),
    get_time(End),
    Elapsed is End - Start,
    format('[PERF] Large dataset (10 classes): ~2fs - OBSERVE~n', [Elapsed]),
    cleanup_dataset.

% ============================================================================
% Main entry point
% ============================================================================

%% run_performance_tests/0
%  Runs all three performance tests sequentially and prints a summary.
%  Tests are isolated: cleanup_dataset/0 is called before and after each test.
run_performance_tests :-
    format('~n============================================================~n'),
    format('[PERF] AI Timetable Generation - Performance Test Suite~n'),
    format('============================================================~n~n'),
    % Small dataset test (Requirement 15.1: <= 30 seconds)
    (   run_small_test
    ->  true
    ;   format('[PERF] Small dataset test did not complete successfully.~n')
    ),
    nl,
    % Medium dataset test (Requirement 15.2: <= 120 seconds)
    (   run_medium_test
    ->  true
    ;   format('[PERF] Medium dataset test did not complete successfully.~n')
    ),
    nl,
    % Large dataset test (observe only)
    (   run_large_test
    ->  true
    ;   format('[PERF] Large dataset test did not complete successfully.~n')
    ),
    nl,
    format('============================================================~n'),
    format('[PERF] Performance tests complete.~n'),
    format('============================================================~n~n').
