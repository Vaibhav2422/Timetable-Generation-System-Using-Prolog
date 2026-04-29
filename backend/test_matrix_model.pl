% test_matrix_model.pl
% Unit tests for matrix_model.pl module
% Tests all predicates for correctness

:- use_module(matrix_model).

% Test helper to print test results
test(Name, Goal) :-
    write('Testing: '), write(Name), write('... '),
    (   call(Goal)
    ->  writeln('PASSED')
    ;   writeln('FAILED'), fail
    ).

% Run all tests
run_tests :-
    writeln('=== Matrix Model Tests ==='),
    writeln(''),
    test_create_empty_timetable,
    test_create_matrix,
    test_create_row,
    test_get_cell,
    test_set_cell,
    test_replace_nth,
    test_scan_row,
    test_scan_column,
    test_get_all_assignments,
    test_is_complete,
    writeln(''),
    writeln('=== All Tests Passed ===').

% Test 4.1: Create matrix structure operations
test_create_empty_timetable :-
    writeln('--- Subtask 4.1: Matrix Structure Operations ---'),
    test('create_empty_timetable with 3 rooms and 5 slots', (
        create_empty_timetable([r1, r2, r3], [s1, s2, s3, s4, s5], Matrix1),
        length(Matrix1, 3),
        Matrix1 = [Row1a, Row2a, Row3a],
        length(Row1a, 5),
        length(Row2a, 5),
        length(Row3a, 5)
    )),
    test('create_empty_timetable with 2 rooms and 3 slots', (
        create_empty_timetable([r1, r2], [s1, s2, s3], Matrix2),
        length(Matrix2, 2),
        Matrix2 = [Row1b, Row2b],
        length(Row1b, 3),
        length(Row2b, 3)
    )),
    test('create_empty_timetable with 1 room and 1 slot', (
        create_empty_timetable([r1], [s1], Matrix3),
        Matrix3 = [[empty]]
    )).

test_create_matrix :-
    test('create_matrix 3x4', (
        create_matrix(3, 4, Matrix1),
        length(Matrix1, 3),
        Matrix1 = [Row1a, Row2a, Row3a],
        length(Row1a, 4),
        length(Row2a, 4),
        length(Row3a, 4)
    )),
    test('create_matrix 0x5 (empty)', (
        create_matrix(0, 5, Matrix2),
        Matrix2 = []
    )),
    test('create_matrix 2x0 (empty rows)', (
        create_matrix(2, 0, Matrix3),
        Matrix3 = [[], []]
    )).

test_create_row :-
    test('create_row with 5 columns', (
        create_row(5, Row1),
        Row1 = [empty, empty, empty, empty, empty]
    )),
    test('create_row with 0 columns', (
        create_row(0, Row2),
        Row2 == []
    )),
    test('create_row with 1 column', (
        create_row(1, Row3),
        Row3 = [empty]
    )).

% Test 4.2: Matrix access and update operations
test_get_cell :-
    writeln('--- Subtask 4.2: Access and Update Operations ---'),
    create_matrix(3, 4, TestMatrix),
    test('get_cell at (0,0)', (
        get_cell(TestMatrix, 0, 0, Cell),
        Cell = empty
    )),
    test('get_cell at (1,2)', (
        get_cell(TestMatrix, 1, 2, Cell),
        Cell = empty
    )),
    test('get_cell at (2,3)', (
        get_cell(TestMatrix, 2, 3, Cell),
        Cell = empty
    )).

test_set_cell :-
    test('set_cell at (0,0)', (
        create_matrix(3, 4, Matrix1),
        set_cell(Matrix1, 0, 0, assigned(c1, sub1, t1), UpdatedMatrix1),
        get_cell(UpdatedMatrix1, 0, 0, Cell1),
        Cell1 = assigned(c1, sub1, t1)
    )),
    test('set_cell at (1,2)', (
        create_matrix(3, 4, Matrix2),
        set_cell(Matrix2, 1, 2, assigned(c2, sub2, t2), UpdatedMatrix2),
        get_cell(UpdatedMatrix2, 1, 2, Cell2),
        Cell2 = assigned(c2, sub2, t2)
    )),
    test('set_cell preserves other cells', (
        create_matrix(3, 4, Matrix3),
        set_cell(Matrix3, 0, 0, assigned(c1, sub1, t1), M1),
        set_cell(M1, 1, 1, assigned(c2, sub2, t2), M2),
        get_cell(M2, 0, 0, Cell3a),
        get_cell(M2, 1, 1, Cell3b),
        get_cell(M2, 2, 2, Cell3c),
        Cell3a = assigned(c1, sub1, t1),
        Cell3b = assigned(c2, sub2, t2),
        Cell3c = empty
    )),
    test('set_cell preserves matrix dimensions', (
        create_matrix(3, 4, Matrix4),
        set_cell(Matrix4, 1, 2, assigned(c1, sub1, t1), UpdatedMatrix4),
        length(Matrix4, Rows1),
        length(UpdatedMatrix4, Rows2),
        Rows1 = Rows2,
        nth0(0, Matrix4, Row1),
        nth0(0, UpdatedMatrix4, Row2),
        length(Row1, Cols1),
        length(Row2, Cols2),
        Cols1 = Cols2
    )).

test_replace_nth :-
    test('replace_nth at index 0', (
        replace_nth(0, [a, b, c], x, Result1),
        Result1 = [x, b, c]
    )),
    test('replace_nth at index 2', (
        replace_nth(2, [a, b, c, d], x, Result2),
        Result2 = [a, b, x, d]
    )),
    test('replace_nth at last index', (
        replace_nth(3, [a, b, c, d], x, Result3),
        Result3 = [a, b, c, x]
    )).

% Test 4.3: Matrix scanning operations
test_scan_row :-
    writeln('--- Subtask 4.3: Scanning Operations ---'),
    test('scan_row with assignments', (
        create_matrix(3, 4, Matrix1),
        set_cell(Matrix1, 0, 0, assigned(c1, sub1, t1), M1),
        set_cell(M1, 0, 2, assigned(c2, sub2, t2), M2),
        scan_row(M2, 0, Assignments1),
        length(Assignments1, 2),
        member(assigned(c1, sub1, t1), Assignments1),
        member(assigned(c2, sub2, t2), Assignments1)
    )),
    test('scan_row with no assignments', (
        create_matrix(3, 4, Matrix2),
        set_cell(Matrix2, 0, 0, assigned(c1, sub1, t1), M3),
        scan_row(M3, 1, Assignments2),
        Assignments2 = []
    )),
    test('scan_row with single assignment', (
        create_matrix(3, 4, Matrix3),
        set_cell(Matrix3, 2, 1, assigned(c3, sub3, t3), M4),
        scan_row(M4, 2, Assignments3),
        Assignments3 = [assigned(c3, sub3, t3)]
    )).

test_scan_column :-
    test('scan_column with assignments', (
        create_matrix(3, 4, Matrix1),
        set_cell(Matrix1, 0, 1, assigned(c1, sub1, t1), M1),
        set_cell(M1, 2, 1, assigned(c2, sub2, t2), M2),
        scan_column(M2, 1, Assignments1),
        length(Assignments1, 2),
        member(assigned(c1, sub1, t1), Assignments1),
        member(assigned(c2, sub2, t2), Assignments1)
    )),
    test('scan_column with no assignments', (
        create_matrix(3, 4, Matrix2),
        set_cell(Matrix2, 0, 1, assigned(c1, sub1, t1), M3),
        scan_column(M3, 3, Assignments2),
        Assignments2 = []
    )),
    test('scan_column with single assignment', (
        create_matrix(3, 4, Matrix3),
        set_cell(Matrix3, 1, 0, assigned(c3, sub3, t3), M4),
        scan_column(M4, 0, Assignments3),
        Assignments3 = [assigned(c3, sub3, t3)]
    )).

test_get_all_assignments :-
    test('get_all_assignments with 3 assignments', (
        create_matrix(2, 3, Matrix1),
        set_cell(Matrix1, 0, 0, assigned(c1, sub1, t1), M1),
        set_cell(M1, 0, 2, assigned(c2, sub2, t2), M2),
        set_cell(M2, 1, 1, assigned(c3, sub3, t3), M3),
        get_all_assignments(M3, Assignments1),
        length(Assignments1, 3),
        member(assigned(c1, sub1, t1), Assignments1),
        member(assigned(c2, sub2, t2), Assignments1),
        member(assigned(c3, sub3, t3), Assignments1)
    )),
    test('get_all_assignments with empty matrix', (
        create_matrix(2, 3, Matrix2),
        get_all_assignments(Matrix2, Assignments2),
        Assignments2 = []
    )).

test_is_complete :-
    test('is_complete fails for empty matrix', (
        create_matrix(2, 2, Matrix1),
        \+ is_complete(Matrix1)
    )),
    test('is_complete fails for partially filled matrix', (
        create_matrix(2, 2, Matrix2),
        set_cell(Matrix2, 0, 0, assigned(c1, sub1, t1), M1),
        set_cell(M1, 0, 1, assigned(c2, sub2, t2), M2),
        \+ is_complete(M2)
    )),
    test('is_complete succeeds for fully filled matrix', (
        create_matrix(2, 2, Matrix3),
        set_cell(Matrix3, 0, 0, assigned(c1, sub1, t1), M3),
        set_cell(M3, 0, 1, assigned(c2, sub2, t2), M4),
        set_cell(M4, 1, 0, assigned(c3, sub3, t3), M5),
        set_cell(M5, 1, 1, assigned(c4, sub4, t4), M6),
        is_complete(M6)
    )).

% Entry point
:- initialization(run_tests, main).
