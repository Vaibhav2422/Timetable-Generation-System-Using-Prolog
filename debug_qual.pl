:- use_module(backend/knowledge_base).
:- assertz(knowledge_base:teacher(t1, 'Alice', [s1], 20, [slot1])).
:- assertz(knowledge_base:subject(s1, 'Math', 3, theory, 1)).
:- assertz(knowledge_base:room(r1, 'Room 101', 50, classroom)).
:- (knowledge_base:teacher(T,_,_,_,_) -> format("teacher found: ~w~n",[T]) ; format("NO teacher~n")),
   (knowledge_base:qualified(T2,S2) -> format("qualified: ~w ~w~n",[T2,S2]) ; format("NO qualified~n")),
   (knowledge_base:suitable_room(R,Type) -> format("suitable: ~w ~w~n",[R,Type]) ; format("NO suitable~n")),
   halt.
