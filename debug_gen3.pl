:- use_module(backend/logging).
:- use_module(backend/knowledge_base).
:- use_module(backend/matrix_model).
:- use_module(backend/constraints).
:- use_module(backend/csp_solver).
:- use_module(backend/probability_module).
:- use_module(backend/timetable_generator).

:- assertz(user:teacher(t1, 'Dr. Alice', [s1], 20, [slot1])).
:- assertz(user:subject(s1, 'Data Structures', 3, theory, 1)).
:- assertz(user:room(r1, 'Room 101', 50, classroom)).
:- assertz(user:timeslot(slot1, monday, 1, '09:00', 1)).
:- assertz(user:class(c1, 'CS-A', [s1])).

:- get_all_rooms(R), format("Rooms: ~w~n", [R]),
   get_all_teachers(T), format("Teachers: ~w~n", [T]),
   get_all_subjects(S), format("Subjects: ~w~n", [S]),
   get_all_timeslots(Sl), format("Slots: ~w~n", [Sl]),
   get_all_classes(C), format("Classes: ~w~n", [C]),
   (validate_room_types(R) -> format("room_types OK~n") ; format("room_types FAILED~n")),
   (validate_subject_requirements(S) -> format("subject_req OK~n") ; format("subject_req FAILED~n")),
   halt.
