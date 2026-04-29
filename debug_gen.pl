:- use_module(backend/logging).
:- use_module(backend/knowledge_base).
:- use_module(backend/matrix_model).
:- use_module(backend/constraints).
:- use_module(backend/csp_solver).
:- use_module(backend/probability_module).
:- use_module(backend/timetable_generator).

:- assertz(teacher(t1, 'Dr. Alice', [s1,s2], 20, [slot1,slot2,slot3,slot4,slot5,slot6])).
:- assertz(teacher(t2, 'Prof. Bob', [s3,s4], 18, [slot1,slot2,slot3,slot4,slot5,slot6])).
:- assertz(teacher(t3, 'Dr. Carol', [s5,s6], 20, [slot1,slot2,slot3,slot4,slot5,slot6])).
:- assertz(teacher(t4, 'Mr. David', [s7], 16, [slot1,slot2,slot3,slot4,slot5,slot6])).
:- assertz(teacher(t5, 'Ms. Emma', [s1,s3,s5], 22, [slot1,slot2,slot3,slot4,slot5,slot6])).
:- assertz(subject(s1, 'Data Structures', 3, theory, 1)).
:- assertz(subject(s2, 'Algorithms', 3, theory, 1)).
:- assertz(subject(s3, 'Database Systems', 3, theory, 1)).
:- assertz(subject(s4, 'Operating Systems', 3, theory, 1)).
:- assertz(subject(s5, 'Computer Networks', 3, theory, 1)).
:- assertz(subject(s6, 'Software Engineering', 3, theory, 1)).
:- assertz(subject(s7, 'Database Lab', 2, lab, 2)).
:- assertz(room(r1, 'Room 101', 50, classroom)).
:- assertz(room(r2, 'Room 102', 45, classroom)).
:- assertz(room(r3, 'Room 103', 40, classroom)).
:- assertz(room(r4, 'Lab A', 30, lab)).
:- assertz(timeslot(slot1, monday, 1, '09:00', 1)).
:- assertz(timeslot(slot2, monday, 2, '10:00', 1)).
:- assertz(timeslot(slot3, monday, 3, '11:00', 1)).
:- assertz(timeslot(slot4, tuesday, 1, '09:00', 1)).
:- assertz(timeslot(slot5, tuesday, 2, '10:00', 1)).
:- assertz(timeslot(slot6, tuesday, 3, '11:00', 1)).
:- assertz(class(c1, 'CS-A', [s1,s2,s3,s7])).
:- assertz(class(c2, 'CS-B', [s4,s5,s6])).

:- (retrieve_resources(T,S,R,Sl,C) -> 
    (length(T,NT), length(S,NS), length(R,NR), length(Sl,NSl), length(C,NC),
     format("Teachers:~w Subjects:~w Rooms:~w Slots:~w Classes:~w~n",[NT,NS,NR,NSl,NC]),
     create_sessions(C,S,Sessions), length(Sessions,NSess),
     format("Sessions: ~w~n",[NSess]),
     create_empty_timetable(R,Sl,Matrix),
     format("Matrix created~n"),
     (solve_csp(Sessions,Matrix,Timetable) ->
         format("CSP solved!~n")
     ;
         format("CSP FAILED~n")
     ))
   ;
     format("retrieve_resources FAILED~n")
   ), halt.
