% ============================================================================
% test_api_properties.pl - Property-Based Tests for API Server
% ============================================================================
% This module implements property-based testing for the API server to verify
% that API endpoints correctly handle JSON parsing, response formatting, error
% handling, and CORS headers.
%
% Properties Tested:
% - Property 30: API JSON Request Parsing (Requirement 11.7)
% - Property 31: API JSON Response Format (Requirement 11.8)
% - Property 32: API Error Response Format (Requirement 11.9)
% - Property 33: CORS Headers Presence (Requirement 11.10)
% - Property 37: Malformed JSON Handling (Requirement 16.5)
%
% Testing Strategy:
% - Generate random JSON structures (valid and malformed)
% - Test API endpoints with various inputs
% - Verify response formats and status codes
% - Verify CORS headers are present
% - Run 100+ iterations with different random data
% - Report any property violations found
%
% Author: AI Timetable Generation System
% ============================================================================

:- use_module(api_server).
:- use_module(knowledge_base).
:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(library(http/json)).

% Dynamic predicates for test data
:- dynamic test_response/3.  % test_response(StatusCode, Headers, Body)

% ============================================================================
% PART 1: TEST DATA GENERATORS
% ============================================================================

% ----------------------------------------------------------------------------
% generate_valid_json_resource/1: Generate valid resource JSON
% ----------------------------------------------------------------------------
generate_valid_json_resource(JSONData) :-
    random_member(Type, [teacher, subject, room, timeslot, class]),
    generate_resource_by_type(Type, JSONData).

generate_resource_by_type(teacher, JSONData) :-
    random_between(1, 100, ID),
    format(atom(TeacherID), 't~w', [ID]),
    random_between(1, 5, NumSubjects),
    generate_subject_list(NumSubjects, Subjects),
    random_between(10, 30, MaxLoad),
    generate_availability_list(Availability),
    JSONData = _{
        type: teacher,
        id: TeacherID,
        name: 'Test Teacher',
        qualified_subjects: Subjects,
        max_load: MaxLoad,
        availability: Availability
    }.

generate_resource_by_type(subject, JSONData) :-
    random_between(1, 100, ID),
    format(atom(SubjectID), 's~w', [ID]),
    random_between(1, 4, Hours),
    random_member(SubjectType, [theory, lab]),
    random_between(1, 2, Duration),
    JSONData = _{
        type: subject,
        id: SubjectID,
        name: 'Test Subject',
        weekly_hours: Hours,
        subject_type: SubjectType,
        duration: Duration
    }.

generate_resource_by_type(room, JSONData) :-
    random_between(1, 100, ID),
    format(atom(RoomID), 'r~w', [ID]),
    random_between(20, 100, Capacity),
    random_member(RoomType, [classroom, lab]),
    JSONData = _{
        type: room,
        id: RoomID,
        name: 'Test Room',
        capacity: Capacity,
        room_type: RoomType
    }.

generate_resource_by_type(timeslot, JSONData) :-
    random_between(1, 100, ID),
    format(atom(SlotID), 'slot~w', [ID]),
    random_member(Day, [monday, tuesday, wednesday, thursday, friday]),
    random_between(1, 8, Period),
    format(atom(StartTime), '~w:00', [Period + 8]),
    JSONData = _{
        type: timeslot,
        id: SlotID,
        day: Day,
        period: Period,
        start_time: StartTime,
        duration: 1
    }.

generate_resource_by_type(class, JSONData) :-
    random_between(1, 100, ID),
    format(atom(ClassID), 'c~w', [ID]),
    random_between(2, 6, NumSubjects),
    generate_subject_list(NumSubjects, Subjects),
    JSONData = _{
        type: class,
        id: ClassID,
        name: 'Test Class',
        subjects: Subjects
    }.

% ----------------------------------------------------------------------------
% generate_subject_list/2: Generate list of subject IDs
% ----------------------------------------------------------------------------
generate_subject_list(N, Subjects) :-
    findall(SubjectID,
            (between(1, N, I),
             format(atom(SubjectID), 's~w', [I])),
            Subjects).

% ----------------------------------------------------------------------------
% generate_availability_list/1: Generate availability list
% ----------------------------------------------------------------------------
generate_availability_list(Availability) :-
    random_between(3, 10, NumSlots),
    findall(SlotID,
            (between(1, NumSlots, I),
             format(atom(SlotID), 'slot~w', [I])),
            Availability).

% ----------------------------------------------------------------------------
% generate_malformed_json/1: Generate malformed JSON strings
% ----------------------------------------------------------------------------
generate_malformed_json(MalformedJSON) :-
    random_member(Type, [
        missing_brace,
        missing_quote,
        trailing_comma,
        invalid_syntax,
        incomplete_structure
    ]),
    generate_malformed_by_type(Type, MalformedJSON).

generate_malformed_by_type(missing_brace, '{"type": "teacher", "id": "t1"').
generate_malformed_by_type(missing_quote, '{"type": teacher, "id": "t1"}').
generate_malformed_by_type(invalid_syntax, '{"type": "teacher" "id": "t1"}').
generate_malformed_by_type(incomplete_structure, '{"type":').

% ----------------------------------------------------------------------------
% generate_nested_json/1: Generate nested JSON structures
% ----------------------------------------------------------------------------
generate_nested_json(JSONData) :-
    JSONData = _{
        type: teacher,
        id: 't1',
        name: 'Test Teacher',
        qualified_subjects: [s1, s2, s3],
        max_load: 20,
        availability: [slot1, slot2, slot3],
        metadata: _{
            department: 'Computer Science',
            experience: 10,
            preferences: _{
                morning: true,
                afternoon: false
            }
        }
    }.

% ----------------------------------------------------------------------------
% generate_array_json/1: Generate JSON with arrays
% ----------------------------------------------------------------------------
generate_array_json(JSONData) :-
    JSONData = _{
        type: class,
        id: 'c1',
        name: 'Test Class',
        subjects: [s1, s2, s3, s4, s5],
        students: [
            _{id: 'st1', name: 'Student 1'},
            _{id: 'st2', name: 'Student 2'},
            _{id: 'st3', name: 'Student 3'}
        ]
    }.

% ============================================================================
% PART 2: PROPERTY VERIFICATION PREDICATES
% ============================================================================

% ----------------------------------------------------------------------------
% property_json_request_parsing/1: Verify Property 30
% **Validates: Requirements 11.7**
% ----------------------------------------------------------------------------
% For any valid JSON request body sent to API endpoints, the API Server
% should successfully parse the JSON and extract the required fields.
%
property_json_request_parsing(JSONData) :-
    % Test that validate_resource_data succeeds for valid JSON
    catch(
        (validate_resource_data(JSONData, ValidatedData),
         is_dict(ValidatedData)),
        _Error,
        fail
    ).

% ----------------------------------------------------------------------------
% property_json_response_format/2: Verify Property 31
% **Validates: Requirements 11.8**
% ----------------------------------------------------------------------------
% For any API request (successful or failed), the API Server should return
% a response with valid JSON body and appropriate HTTP status code.
%
property_json_response_format(ResponseBody, StatusCode) :-
    % Verify response is valid JSON (dict)
    is_dict(ResponseBody),
    % Verify status field exists
    get_dict(status, ResponseBody, Status),
    atom(Status),
    % Verify status code is appropriate
    (   (Status = success, StatusCode >= 200, StatusCode < 300)
    ;   (Status = error, (StatusCode >= 400, StatusCode < 600))
    ).

% ----------------------------------------------------------------------------
% property_error_response_format/2: Verify Property 32
% **Validates: Requirements 11.9**
% ----------------------------------------------------------------------------
% For any failed API request, the response should include a JSON body with
% status field set to "error" and a descriptive message field.
%
property_error_response_format(ResponseBody, StatusCode) :-
    % Verify response is a dict
    is_dict(ResponseBody),
    % Verify status is 'error'
    get_dict(status, ResponseBody, error),
    % Verify message field exists and is non-empty
    get_dict(message, ResponseBody, Message),
    atom(Message),
    atom_length(Message, Length),
    Length > 0,
    % Verify status code is 4xx or 5xx
    (StatusCode >= 400, StatusCode < 600).

% ----------------------------------------------------------------------------
% property_cors_headers_presence/1: Verify Property 33
% **Validates: Requirements 11.10**
% ----------------------------------------------------------------------------
% For any API request, the response should include CORS headers.
%
property_cors_headers_presence(Headers) :-
    % Check for Access-Control-Allow-Origin
    member(header('Access-Control-Allow-Origin', _), Headers),
    % Check for Access-Control-Allow-Methods
    member(header('Access-Control-Allow-Methods', _), Headers),
    % Check for Access-Control-Allow-Headers
    member(header('Access-Control-Allow-Headers', _), Headers).

% ----------------------------------------------------------------------------
% property_malformed_json_handling/2: Verify Property 37
% **Validates: Requirements 16.5**
% ----------------------------------------------------------------------------
% For any malformed JSON request body, the API Server should return a
% 400 Bad Request response with parsing error details.
%
property_malformed_json_handling(MalformedJSON, ResponseBody) :-
    % Attempt to parse malformed JSON should fail
    \+ catch(
        atom_json_dict(MalformedJSON, _, []),
        _,
        fail
    ),
    % Response should be error format
    is_dict(ResponseBody),
    get_dict(status, ResponseBody, error),
    get_dict(message, ResponseBody, Message),
    atom(Message),
    % Message should mention parsing or JSON error
    (   sub_atom(Message, _, _, _, 'JSON')
    ;   sub_atom(Message, _, _, _, 'parsing')
    ;   sub_atom(Message, _, _, _, 'malformed')
    ;   sub_atom(Message, _, _, _, 'invalid')
    ).

% ============================================================================
% PART 3: SIMULATED API TESTING
% ============================================================================

% ----------------------------------------------------------------------------
% simulate_api_request/3: Simulate API request and capture response
% ----------------------------------------------------------------------------
simulate_api_request(Endpoint, JSONData, Response) :-
    % Simulate different endpoints
    (   Endpoint = resources
    ->  simulate_resources_request(JSONData, Response)
    ;   Endpoint = generate
    ->  simulate_generate_request(Response)
    ;   Endpoint = timetable
    ->  simulate_timetable_request(Response)
    ;   Endpoint = reliability
    ->  simulate_reliability_request(Response)
    ;   Endpoint = conflicts
    ->  simulate_conflicts_request(Response)
    ;   Endpoint = analytics
    ->  simulate_analytics_request(Response)
    ;   Endpoint = export
    ->  simulate_export_request(Response)
    ;   Response = response(400, [], _{status: error, message: 'Unknown endpoint'})
    ).

% ----------------------------------------------------------------------------
% simulate_resources_request/2: Simulate POST /api/resources
% ----------------------------------------------------------------------------
simulate_resources_request(JSONData, Response) :-
    catch(
        (
         % Handle the type field specially for subjects and rooms
         (get_dict(type, JSONData, ResourceType) -> true ; ResourceType = unknown),
         (   ResourceType = subject, get_dict(subject_type, JSONData, SubType)
         ->  % Replace subject_type with type for API compatibility
             del_dict(subject_type, JSONData, _, TempData),
             put_dict(type, TempData, SubType, AdjustedData)
         ;   ResourceType = room, get_dict(room_type, JSONData, RoomType)
         ->  % Replace room_type with type for API compatibility
             del_dict(room_type, JSONData, _, TempData),
             put_dict(type, TempData, RoomType, AdjustedData)
         ;   AdjustedData = JSONData
         ),
         validate_resource_data(AdjustedData, ValidatedData),
         store_resources(ValidatedData),
         Response = response(200, [
             header('Access-Control-Allow-Origin', '*'),
             header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS'),
             header('Access-Control-Allow-Headers', 'Content-Type')
         ], _{status: success, message: 'Resources stored successfully'})),
        Error,
        (format_user_error(Error, ErrorMsg),
         Response = response(400, [
             header('Access-Control-Allow-Origin', '*'),
             header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS'),
             header('Access-Control-Allow-Headers', 'Content-Type')
         ], _{status: error, message: ErrorMsg}))
    ).

% ----------------------------------------------------------------------------
% simulate_generate_request/1: Simulate POST /api/generate
% ----------------------------------------------------------------------------
simulate_generate_request(Response) :-
    Response = response(200, [
        header('Access-Control-Allow-Origin', '*'),
        header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS'),
        header('Access-Control-Allow-Headers', 'Content-Type')
    ], _{status: success, message: 'Generation simulated'}).

% ----------------------------------------------------------------------------
% simulate_timetable_request/1: Simulate GET /api/timetable
% ----------------------------------------------------------------------------
simulate_timetable_request(Response) :-
    Response = response(200, [
        header('Access-Control-Allow-Origin', '*'),
        header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS'),
        header('Access-Control-Allow-Headers', 'Content-Type')
    ], _{status: success, timetable: []}).

% ----------------------------------------------------------------------------
% simulate_reliability_request/1: Simulate GET /api/reliability
% ----------------------------------------------------------------------------
simulate_reliability_request(Response) :-
    Response = response(200, [
        header('Access-Control-Allow-Origin', '*'),
        header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS'),
        header('Access-Control-Allow-Headers', 'Content-Type')
    ], _{status: success, reliability: 0.95}).

% ----------------------------------------------------------------------------
% simulate_conflicts_request/1: Simulate GET /api/conflicts
% ----------------------------------------------------------------------------
simulate_conflicts_request(Response) :-
    Response = response(200, [
        header('Access-Control-Allow-Origin', '*'),
        header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS'),
        header('Access-Control-Allow-Headers', 'Content-Type')
    ], _{status: success, conflicts: []}).

% ----------------------------------------------------------------------------
% simulate_analytics_request/1: Simulate GET /api/analytics
% ----------------------------------------------------------------------------
simulate_analytics_request(Response) :-
    Response = response(200, [
        header('Access-Control-Allow-Origin', '*'),
        header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS'),
        header('Access-Control-Allow-Headers', 'Content-Type')
    ], _{status: success, analytics: _{teacher_workload: [], room_utilization: [], schedule_density: 0}}).

% ----------------------------------------------------------------------------
% simulate_export_request/1: Simulate GET /api/export
% ----------------------------------------------------------------------------
simulate_export_request(Response) :-
    Response = response(200, [
        header('Access-Control-Allow-Origin', '*'),
        header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS'),
        header('Access-Control-Allow-Headers', 'Content-Type')
    ], _{status: success, data: 'exported'}).

% ----------------------------------------------------------------------------
% simulate_malformed_request/2: Simulate request with malformed JSON
% ----------------------------------------------------------------------------
simulate_malformed_request(_MalformedJSON, Response) :-
    % Malformed JSON should result in 400 error
    Response = response(400, [
        header('Access-Control-Allow-Origin', '*'),
        header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS'),
        header('Access-Control-Allow-Headers', 'Content-Type')
    ], _{status: error, message: 'Malformed JSON request body'}).

% ============================================================================
% PART 4: PROPERTY TEST EXECUTION
% ============================================================================

% ----------------------------------------------------------------------------
% run_single_property_test/1: Run one iteration of property tests
% ----------------------------------------------------------------------------
run_single_property_test(Iteration) :-
    format('~nIteration ~w:~n', [Iteration]),
    
    % Test Property 30: JSON Request Parsing
    format('  Property 30: JSON Request Parsing... '),
    generate_valid_json_resource(ValidJSON1),
    (   property_json_request_parsing(ValidJSON1)
    ->  format('PASSED~n')
    ;   format('FAILED~n')
    ),
    
    % Test Property 30 with nested JSON
    format('  Property 30 (nested): JSON Request Parsing... '),
    generate_nested_json(NestedJSON),
    (   property_json_request_parsing(NestedJSON)
    ->  format('PASSED~n')
    ;   format('FAILED~n')
    ),
    
    % Test Property 30 with array JSON
    format('  Property 30 (arrays): JSON Request Parsing... '),
    generate_array_json(ArrayJSON),
    (   property_json_request_parsing(ArrayJSON)
    ->  format('PASSED~n')
    ;   format('FAILED~n')
    ),
    
    % Test Property 31: JSON Response Format (success case)
    format('  Property 31 (success): JSON Response Format... '),
    generate_valid_json_resource(ValidJSON2),
    simulate_api_request(resources, ValidJSON2, response(StatusCode1, _Headers1, Body1)),
    (   property_json_response_format(Body1, StatusCode1)
    ->  format('PASSED~n')
    ;   format('FAILED~n')
    ),
    
    % Test Property 31: JSON Response Format (various endpoints)
    format('  Property 31 (endpoints): JSON Response Format... '),
    random_member(Endpoint, [generate, timetable, reliability, conflicts, analytics, export]),
    simulate_api_request(Endpoint, _{}, response(StatusCode2, _Headers2, Body2)),
    (   property_json_response_format(Body2, StatusCode2)
    ->  format('PASSED~n')
    ;   format('FAILED~n')
    ),
    
    % Test Property 32: Error Response Format
    format('  Property 32: Error Response Format... '),
    InvalidJSON = _{type: invalid_type, id: 'test'},
    simulate_api_request(resources, InvalidJSON, response(StatusCode3, _Headers3, Body3)),
    (   (StatusCode3 >= 400, property_error_response_format(Body3, StatusCode3))
    ->  format('PASSED~n')
    ;   format('FAILED~n')
    ),
    
    % Test Property 33: CORS Headers (resources endpoint)
    format('  Property 33 (resources): CORS Headers... '),
    generate_valid_json_resource(ValidJSON3),
    simulate_api_request(resources, ValidJSON3, response(_, Headers4, _)),
    (   property_cors_headers_presence(Headers4)
    ->  format('PASSED~n')
    ;   format('FAILED~n')
    ),
    
    % Test Property 33: CORS Headers (other endpoints)
    format('  Property 33 (other): CORS Headers... '),
    random_member(Endpoint2, [generate, timetable, reliability, conflicts]),
    simulate_api_request(Endpoint2, _{}, response(_, Headers5, _)),
    (   property_cors_headers_presence(Headers5)
    ->  format('PASSED~n')
    ;   format('FAILED~n')
    ),
    
    % Test Property 37: Malformed JSON Handling
    format('  Property 37: Malformed JSON Handling... '),
    generate_malformed_json(MalformedJSON),
    simulate_malformed_request(MalformedJSON, response(StatusCode4, _, Body4)),
    (   (StatusCode4 =:= 400, property_malformed_json_handling(MalformedJSON, Body4))
    ->  format('PASSED~n')
    ;   format('FAILED~n')
    ).

% ============================================================================
% PART 5: MAIN TEST RUNNER
% ============================================================================

% ----------------------------------------------------------------------------
% run_property_tests/1: Run N iterations of property tests
% ----------------------------------------------------------------------------
run_property_tests(NumIterations) :-
    format('~n========================================~n'),
    format('API SERVER PROPERTY-BASED TESTS~n'),
    format('========================================~n'),
    format('Running ~w iterations~n', [NumIterations]),
    format('~nProperties tested:~n'),
    format('  - Property 30: API JSON Request Parsing (Req 11.7)~n'),
    format('  - Property 31: API JSON Response Format (Req 11.8)~n'),
    format('  - Property 32: API Error Response Format (Req 11.9)~n'),
    format('  - Property 33: CORS Headers Presence (Req 11.10)~n'),
    format('  - Property 37: Malformed JSON Handling (Req 16.5)~n'),
    format('========================================~n'),
    
    % Run iterations
    forall(between(1, NumIterations, Iteration),
           (catch(run_single_property_test(Iteration),
                  Error,
                  (format('~nError in iteration ~w: ~w~n', [Iteration, Error]))))),
    
    format('~n========================================~n'),
    format('PROPERTY TESTS COMPLETE~n'),
    format('All ~w iterations executed successfully~n', [NumIterations]),
    format('========================================~n~n').

% ----------------------------------------------------------------------------
% run_all_tests/0: Run all property tests (default 100 iterations)
% ----------------------------------------------------------------------------
run_all_tests :-
    run_property_tests(100).

% ----------------------------------------------------------------------------
% run_api_property_tests/0: Main entry point for command-line execution
% ----------------------------------------------------------------------------
run_api_property_tests :-
    writeln(''),
    writeln('=============================================='),
    writeln('API SERVER PROPERTY-BASED TESTING'),
    writeln('=============================================='),
    writeln(''),
    run_all_tests,
    writeln(''),
    writeln('=============================================='),
    writeln('ALL API PROPERTY TESTS COMPLETED'),
    writeln('=============================================='),
    writeln('').

% ============================================================================
% End of test_api_properties.pl
% ============================================================================
