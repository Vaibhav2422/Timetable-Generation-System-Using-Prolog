% matrix_model.pl
% Matrix-based timetable representation module
% Demonstrates Linear Algebra concepts through 2D matrix operations
%
% Matrix Structure:
% - Timetable is a list of lists: [[Cell11, Cell12, ...], [Cell21, Cell22, ...], ...]
% - Each row represents a room
% - Each column represents a time slot
% - Cell format: cell(RoomID, SlotID, Assignment)
% - Assignment format: assigned(ClassID, SubjectID, TeacherID) or empty
%
% Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7

:- module(matrix_model, [
    create_empty_timetable/3,
    create_matrix/3,
    create_row/2,
    get_cell/4,
    set_cell/5,
    replace_nth/4,
    scan_row/3,
    scan_column/3,
    get_all_assignments/2,
    is_complete/1
]).

%% create_empty_timetable(+Rooms, +Slots, -Matrix)
%  Creates an empty timetable matrix with dimensions matching rooms × time slots
%  @param Rooms List of room identifiers
%  @param Slots List of time slot identifiers
%  @param Matrix Output matrix structure
%  Requirements: 2.1, 2.2, 2.4
create_empty_timetable(Rooms, Slots, Matrix) :-
    length(Rooms, NumRooms),
    length(Slots, NumSlots),
    create_matrix(NumRooms, NumSlots, Matrix).

%% create_matrix(+Rows, +Cols, -Matrix)
%  Helper predicate to recursively create a matrix with given dimensions
%  @param Rows Number of rows (rooms)
%  @param Cols Number of columns (time slots)
%  @param Matrix Output matrix structure
%  Requirements: 2.2, 2.4
create_matrix(0, _, []) :- !.
create_matrix(Rows, Cols, [Row|Rest]) :-
    Rows > 0,
    create_row(Cols, Row),
    Rows1 is Rows - 1,
    create_matrix(Rows1, Cols, Rest).

%% create_row(+Cols, -Row)
%  Helper predicate to create a single row with empty cells
%  @param Cols Number of columns in the row
%  @param Row Output row structure (list of empty cells)
%  Requirements: 2.2, 2.4
create_row(0, []) :- !.
create_row(Cols, [empty|Rest]) :-
    Cols > 0,
    Cols1 is Cols - 1,
    create_row(Cols1, Rest).

%% get_cell(+Matrix, +RoomIdx, +SlotIdx, -Cell)
%  Access a cell by row (room) and column (time slot) index
%  Uses 0-based indexing
%  @param Matrix The timetable matrix
%  @param RoomIdx Row index (0-based)
%  @param SlotIdx Column index (0-based)
%  @param Cell Output cell value
%  Requirements: 2.3, 2.4
get_cell(Matrix, RoomIdx, SlotIdx, Cell) :-
    nth0(RoomIdx, Matrix, Row),
    nth0(SlotIdx, Row, Cell).

%% set_cell(+Matrix, +RoomIdx, +SlotIdx, +NewValue, -UpdatedMatrix)
%  Update a cell value at the specified position
%  Preserves matrix structure and dimensions
%  @param Matrix The original timetable matrix
%  @param RoomIdx Row index (0-based)
%  @param SlotIdx Column index (0-based)
%  @param NewValue New value to set in the cell
%  @param UpdatedMatrix Output matrix with updated cell
%  Requirements: 2.3, 2.4, 2.7
set_cell(Matrix, RoomIdx, SlotIdx, NewValue, UpdatedMatrix) :-
    nth0(RoomIdx, Matrix, Row),
    replace_nth(SlotIdx, Row, NewValue, NewRow),
    replace_nth(RoomIdx, Matrix, NewRow, UpdatedMatrix).

%% replace_nth(+Index, +List, +NewValue, -NewList)
%  Helper predicate to replace the nth element in a list
%  Uses 0-based indexing
%  @param Index Position to replace (0-based)
%  @param List Original list
%  @param NewValue New value to insert
%  @param NewList Output list with replaced element
%  Requirements: 2.3, 2.7
replace_nth(0, [_|T], X, [X|T]) :- !.
replace_nth(N, [H|T], X, [H|R]) :-
    N > 0,
    N1 is N - 1,
    replace_nth(N1, T, X, R).

%% scan_row(+Matrix, +RoomIdx, -Assignments)
%  Get all assignments in a specific room (row scan)
%  Used for detecting room conflicts
%  @param Matrix The timetable matrix
%  @param RoomIdx Row index (0-based)
%  @param Assignments List of all non-empty assignments in the row
%  Requirements: 2.5
scan_row(Matrix, RoomIdx, Assignments) :-
    nth0(RoomIdx, Matrix, Row),
    findall(A, (member(Cell, Row), Cell \= empty, Cell = A), Assignments).

%% scan_column(+Matrix, +SlotIdx, -Assignments)
%  Get all assignments in a specific time slot (column scan)
%  Used for detecting time slot conflicts
%  @param Matrix The timetable matrix
%  @param SlotIdx Column index (0-based)
%  @param Assignments List of all non-empty assignments in the column
%  Requirements: 2.6
scan_column(Matrix, SlotIdx, Assignments) :-
    findall(A, (member(Row, Matrix), nth0(SlotIdx, Row, Cell), Cell \= empty, Cell = A), Assignments).

%% get_all_assignments(+Matrix, -Assignments)
%  Flatten the matrix and extract all non-empty assignments
%  @param Matrix The timetable matrix
%  @param Assignments List of all assignments in the matrix
%  Requirements: 2.5, 2.6
get_all_assignments(Matrix, Assignments) :-
    flatten(Matrix, Cells),
    findall(A, (member(Cell, Cells), Cell \= empty, Cell = A), Assignments).

%% is_complete(+Matrix)
%  Check if the matrix has no empty cells (all slots assigned)
%  @param Matrix The timetable matrix
%  Requirements: 2.5, 2.6
is_complete(Matrix) :-
    flatten(Matrix, Cells),
    \+ member(empty, Cells).
