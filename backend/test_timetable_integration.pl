%% test_timetable_integration.pl
%% Simple integration test for timetable_generator module

:- use_module(timetable_generator).
:- use_module(knowledge_base).
:- use_module(matrix_model).

%% Load dataset
:- consult('../data/dataset.pl').

%% Test basic functionality
test_basic_integration :-
    writeln('Testing timetable_generator integration...'),
    
    % Test 1: Retrieve resources
    writeln('Test 1: Retrieving resources...'),
    retrieve_resources(Teachers, Subjects, Rooms, Slots, Classes),
    length(Teachers, NT),
    length(Subjects, NS),
    length(Rooms, NR),
    length(Slots, NSl),
    length(Classes, NC),
    format('  Found: ~w teachers, ~w subjects, ~w rooms, ~w slots, ~w classes~n', 
           [NT, NS, NR, NSl, NC]),
    (NT > 0, NS > 0, NR > 0, NSl > 0, NC > 0 -> 
        writeln('  ✓ Resource retrieval successful') 
    ; 
        writeln('  ✗ Resource retrieval failed')),
    
    % Test 2: Create sessions
    writeln('Test 2: Creating sessions...'),
    create_sessions(Classes, Subjects, Sessions),
    length(Sessions, SessionCount),
    format('  Created ~w sessions~n', [SessionCount]),
    (SessionCount > 0 -> 
        writeln('  ✓ Session creation successful') 
    ; 
        writeln('  ✗ Session creation failed')),
    
    % Test 3: Create empty timetable
    writeln('Test 3: Creating empty timetable matrix...'),
    create_empty_timetable(Rooms, Slots, EmptyMatrix),
    length(EmptyMatrix, MatrixRows),
    EmptyMatrix = [FirstRow|_],
    length(FirstRow, MatrixCols),
    format('  Matrix dimensions: ~w x ~w~n', [MatrixRows, MatrixCols]),
    (MatrixRows = NR, MatrixCols = NSl -> 
        writeln('  ✓ Matrix creation successful') 
    ; 
        writeln('  ✗ Matrix dimensions incorrect')),
    
    % Test 4: Format explanation
    writeln('Test 4: Testing explanation formatting...'),
    (   (teacher(T1, _, _, _, _) ; user:teacher(T1, _, _, _, _)),
        (subject(S1, _, _, _, _) ; user:subject(S1, _, _, _, _)),
        (room(R1, _, _, _) ; user:room(R1, _, _, _)),
        (class(C1, _, _) ; user:class(C1, _, _)),
        (timeslot(Slot1, _, _, _, _) ; user:timeslot(Slot1, _, _, _, _)),
        Assignment = assigned(R1, C1, S1, T1, Slot1),
        format_explanation(Assignment, Explanation),
        format('  Explanation: ~w~n', [Explanation]),
        atom(Explanation)
    ->  writeln('  ✓ Explanation formatting successful')
    ;   writeln('  ✗ Explanation formatting failed')
    ),
    
    % Test 5: Detect conflicts (empty matrix should have none)
    writeln('Test 5: Testing conflict detection...'),
    detect_conflicts(EmptyMatrix, Conflicts),
    length(Conflicts, ConflictCount),
    format('  Found ~w conflicts in empty matrix~n', [ConflictCount]),
    (ConflictCount = 0 -> 
        writeln('  ✓ Conflict detection successful') 
    ; 
        writeln('  ✗ Unexpected conflicts found')),
    
    % Test 6: Format timetable as JSON
    writeln('Test 6: Testing JSON formatting...'),
    format_timetable(EmptyMatrix, json, JSONOutput),
    (JSONOutput = json(_) -> 
        writeln('  ✓ JSON formatting successful') 
    ; 
        writeln('  ✗ JSON formatting failed')),
    
    % Test 7: Format timetable as text
    writeln('Test 7: Testing text formatting...'),
    format_timetable(EmptyMatrix, text, TextOutput),
    (atom(TextOutput) -> 
        writeln('  ✓ Text formatting successful') 
    ; 
        writeln('  ✗ Text formatting failed')),
    
    % Test 8: Format timetable as CSV
    writeln('Test 8: Testing CSV formatting...'),
    format_timetable(EmptyMatrix, csv, CSVOutput),
    (atom(CSVOutput) -> 
        writeln('  ✓ CSV formatting successful') 
    ; 
        writeln('  ✗ CSV formatting failed')),
    
    writeln(''),
    writeln('Integration test completed!').

%% Run the test
:- initialization(test_basic_integration, main).
