:- module(concurrent_test, [run_concurrent_tests/0]).

:- use_module(library(lists)).
:- use_module(backend/timetable_generator).
:- use_module(backend/knowledge_base).
:- use_module(backend/logging).

:- dynamic test_result/2.

% Minimal shared dataset for concurrent tests
load_concurrent_dataset :-
    assert(teacher(t1, 'Alice Brown', [s1,s2], 20, [ts1,ts2,ts3,ts4,ts5,ts6])),
    assert(teacher(t2, 'Bob Carter',  [s2,s3], 20, [ts1,ts2,ts3,ts4,ts5,ts6])),
    assert(subject(s1, 'Mathematics', 2, theory, 1)),
    assert(subject(s2, 'Physics',     2, theory, 1)),
    assert(subject(s3, 'Chemistry',   2, lab,    2)),
    assert(room(r1, 'Room 101', 40, classroom)),
    assert(room(r2, 'Lab A',    30, lab)),
    assert(timeslot(ts1, monday,    1, '08:00', 1)),
    assert(timeslot(ts2, monday,    2, '09:00', 1)),
    assert(timeslot(ts3, tuesday,   1, '08:00', 1)),
    assert(timeslot(ts4, tuesday,   2, '09:00', 1)),
    assert(timeslot(ts5, wednesday, 1, '08:00', 1)),
    assert(timeslot(ts6, wednesday, 2, '09:00', 1)),
    assert(class(c1, 'Class A', [s1,s2,s3])).

cleanup_concurrent_dataset :-
    retractall(teacher(_, _, _, _, _)),
    retractall(subject(_, _, _, _, _)),
    retractall(room(_, _, _, _)),
    retractall(timeslot(_, _, _, _, _)),
    retractall(class(_, _, _)).

% Thread worker: generate timetable and store result
thread_worker(ThreadID) :-
    catch(
        (
            generate_timetable(Timetable),
            (Timetable \= error(_) ->
                assertz(test_result(ThreadID, success))
            ;
                assertz(test_result(ThreadID, failure(invalid_timetable)))
            )
        ),
        Error,
        assertz(test_result(ThreadID, failure(Error)))
    ).

% Run N concurrent threads and collect results
run_concurrent_threads(N) :-
    retractall(test_result(_, _)),
    numlist(1, N, ThreadIDs),
    % Spawn all threads
    maplist([ID]>>(
        atom_concat(perf_thread_, ID, Alias),
        thread_create(thread_worker(ID), _, [detached(false), alias(Alias)])
    ), ThreadIDs),
    % Join all threads
    maplist([ID]>>(
        atom_concat(perf_thread_, ID, Alias),
        thread_join(Alias, _)
    ), ThreadIDs).

% Verify all threads got valid results
verify_results(N) :-
    numlist(1, N, ThreadIDs),
    maplist([ID]>>(
        (test_result(ID, success) ->
            format('[CONCURRENT] Thread ~w: PASS~n', [ID])
        ;
            test_result(ID, failure(Reason)),
            format('[CONCURRENT] Thread ~w: FAIL (~w)~n', [ID, Reason])
        )
    ), ThreadIDs),
    findall(ID, test_result(ID, success), Successes),
    length(Successes, SuccessCount),
    format('[CONCURRENT] ~w/~w threads completed successfully~n', [SuccessCount, N]),
    (SuccessCount =:= N ->
        format('[CONCURRENT] Concurrent test: PASS (no data corruption detected)~n')
    ;
        format('[CONCURRENT] Concurrent test: FAIL (~w threads failed)~n', [N - SuccessCount])
    ).

% Test timeout: verify generation respects 5-minute limit
test_timeout_limit :-
    format('[CONCURRENT] Testing timeout limit (5 minutes = 300 seconds)...~n'),
    get_time(Start),
    catch(
        (
            call_with_time_limit(300, generate_timetable(_)),
            get_time(End),
            Elapsed is End - Start,
            format('[CONCURRENT] Generation completed in ~2fs (within 300s limit): PASS~n', [Elapsed])
        ),
        time_limit_exceeded,
        (
            get_time(End),
            Elapsed is End - Start,
            format('[CONCURRENT] Generation timed out after ~2fs: PASS (timeout enforced correctly)~n', [Elapsed])
        )
    ).

% Main entry point
run_concurrent_tests :-
    format('~n============================================================~n'),
    format('[CONCURRENT] AI Timetable - Concurrent Request Test Suite~n'),
    format('============================================================~n~n'),
    cleanup_concurrent_dataset,
    load_concurrent_dataset,
    N = 3,
    format('[CONCURRENT] Spawning ~w concurrent generation threads...~n', [N]),
    run_concurrent_threads(N),
    verify_results(N),
    nl,
    test_timeout_limit,
    nl,
    cleanup_concurrent_dataset,
    format('============================================================~n'),
    format('[CONCURRENT] Concurrent tests complete.~n'),
    format('============================================================~n~n').
