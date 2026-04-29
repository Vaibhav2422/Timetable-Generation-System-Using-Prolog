:- use_module(backend/logging).
:- use_module(backend/knowledge_base).
:- use_module(backend/matrix_model).
:- use_module(backend/constraints).
:- use_module(backend/csp_solver).
:- use_module(backend/probability_module).
:- use_module(backend/timetable_generator).

:- assertz(user:teacher(t1, 'Dr. Alice', [s1,s2], 20, [slot1,slot2,slot3,slot4,slot5,slot6])).
:- assertz(user:teacher(t2, 'Prof. Bob', [s3,s4], 18, [slot1,slot2,slot3,slot4,slot5,slot6])).
:- assertz(user:teacher(t3, 'Dr. Carol', [s5,s6], 20, [slot1,slot2,slot3,slot4,slot5,slot6])).
:- assertz(user:teacher(t4, 'Mr. David', [s7], 16, [slot1,slot2,slot3,slot4,slot5,slot6])).
:- assertz(user:teacher(t5, 'Ms. Emma', [s1,s3,s5], 22, [slot1,slot2,slot3,slot4,slot5,slot6])).
:- assertz(user:subject(s1, 'Data Structures', 3, theory, 1)).
:- assertz(user:subject(s2, 'Algorithms', 3, theory, 1)).
:- assertz(user:subject(s3, 'Database Systems', 3, theory, 1)).
:- assertz(user:subject(s4, 'Operating Systems', 3, theory, 1)).
:- assertz(user:subject(s5, 'Computer Networks', 3, theory, 1)).
:- assertz(user:subject(s6, 'Software Engineering', 3, theory, 1)).
:- assertz(user:subject(s7, 'Database Lab', 2, lab, 2)).
:- assertz(user:room(r1, 'Room 101', 50, classroom)).
:- assertz(user:room(r2, 'Room 102', 45, classroom)).
:- assertz(user:room(r3, 'Room 103', 40, classroom)).
:- assertz(user:room(r4, 'Lab A', 30, lab)).
:- assertz(user:timeslot(slot1, monday, 1, '09:00', 1)).
:- assertz(user:timeslot(slot2, monday, 2, '10:00', 1)).
:- assertz(user:timeslot(slot3, monday, 3, '11:00', 1)).
:- assertz(user:timeslot(slot4, tuesday, 1, '09:00', 1)).
:- assertz(user:timeslot(slot5, tuesday, 2, '10:00', 1)).
:- assertz(user:timeslot(slot6, tuesday, 3, '11:00', 1)).
:- assertz(user:class(c1, 'CS-A', [s1,s2,s3,s7])).
:- assertz(user:class(c2, 'CS-B', [s4,s5,s6])).

:- (generate_timetable(T) ->
    (get_all_assignments(T, A), length(A, N), format("SUCCESS! ~w assignments~n", [N]))
   ;
    format("FAILED~n")
   ), halt.
