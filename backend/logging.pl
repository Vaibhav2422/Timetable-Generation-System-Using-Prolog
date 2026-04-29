%% ============================================================================
%% logging.pl - Logging and Debugging Support Module
%% ============================================================================
%% Purpose: Provide structured logging with multiple log levels for debugging
%%          and monitoring the timetable generation process.
%%
%% Requirements: 23.1, 23.2, 23.3, 23.4, 23.5
%%
%% Features:
%% - Dynamic log level management (DEBUG, INFO, WARNING, ERROR)
%% - Timestamp generation for each log entry
%% - Log level filtering based on priority
%% - Special CSP search progress tracking
%% - Integration with other modules for comprehensive logging
%% ============================================================================

:- module(logging, [
    set_log_level/1,
    get_log_level/1,
    should_log/1,
    log_info/1,
    log_warning/1,
    log_error/1,
    log_debug/1,
    get_timestamp/1,
    log_search_node/1,
    log_assignment/4,
    log_backtrack/1,
    log_constraint_violation/2
]).

%% ============================================================================
%% Dynamic Predicates
%% ============================================================================

%% log_level/1 - Current log level setting
%% Default: info
:- dynamic log_level/1.
log_level(info).

%% ============================================================================
%% Log Level Management
%% ============================================================================

%% set_log_level(+Level)
%% Set the current log level
%% Level must be one of: debug, info, warning, error
%% Validates: Requirements 23.4, 23.5
set_log_level(Level) :-
    valid_log_level(Level),
    !,
    retractall(log_level(_)),
    assertz(log_level(Level)).

set_log_level(Level) :-
    format(user_error, '[LOGGING] ERROR: Invalid log level: ~w. Valid levels: debug, info, warning, error~n', [Level]),
    fail.

%% get_log_level(-Level)
%% Get the current log level
get_log_level(Level) :-
    log_level(Level).

%% valid_log_level(+Level)
%% Check if a log level is valid
valid_log_level(debug).
valid_log_level(info).
valid_log_level(warning).
valid_log_level(error).

%% level_priority(+Level, -Priority)
%% Map log levels to numeric priorities for comparison
%% Higher priority = more severe
level_priority(error, 3).
level_priority(warning, 2).
level_priority(info, 1).
level_priority(debug, 0).

%% should_log(+MessageLevel)
%% Determine if a message at MessageLevel should be logged
%% based on the current log level setting
%% Validates: Requirements 23.4
should_log(MessageLevel) :-
    log_level(CurrentLevel),
    level_priority(MessageLevel, MPriority),
    level_priority(CurrentLevel, CPriority),
    MPriority >= CPriority.

%% ============================================================================
%% Timestamp Generation
%% ============================================================================

%% get_timestamp(-Timestamp)
%% Get current timestamp in format: YYYY-MM-DD HH:MM:SS
get_timestamp(Timestamp) :-
    get_time(Time),
    format_time(atom(Timestamp), '%Y-%m-%d %H:%M:%S', Time).

%% ============================================================================
%% Core Logging Predicates
%% ============================================================================

%% log_info(+Message)
%% Log an informational message
%% Validates: Requirements 23.4
log_info(Message) :-
    should_log(info),
    !,
    get_timestamp(Timestamp),
    format(user_error, '[~w] INFO: ~w~n', [Timestamp, Message]).

log_info(_).  % Silently succeed if log level filters out the message

%% log_warning(+Message)
%% Log a warning message
%% Validates: Requirements 23.4
log_warning(Message) :-
    should_log(warning),
    !,
    get_timestamp(Timestamp),
    format(user_error, '[~w] WARNING: ~w~n', [Timestamp, Message]).

log_warning(_).

%% log_error(+Message)
%% Log an error message
%% Validates: Requirements 23.4
log_error(Message) :-
    should_log(error),
    !,
    get_timestamp(Timestamp),
    format(user_error, '[~w] ERROR: ~w~n', [Timestamp, Message]).

log_error(_).

%% log_debug(+Message)
%% Log a debug message
%% Validates: Requirements 23.4
log_debug(Message) :-
    should_log(debug),
    !,
    get_timestamp(Timestamp),
    format(user_error, '[~w] DEBUG: ~w~n', [Timestamp, Message]).

log_debug(_).

%% ============================================================================
%% CSP-Specific Logging
%% ============================================================================

%% log_search_node(+NodeCount)
%% Log CSP search progress every 1000 nodes
%% Validates: Requirements 23.1, 15.4
log_search_node(NodeCount) :-
    should_log(info),
    NodeCount > 0,
    0 is NodeCount mod 1000,
    !,
    get_timestamp(Timestamp),
    format(user_error, '[~w] SEARCH: Explored ~w nodes~n', [Timestamp, NodeCount]).

log_search_node(_).

%% log_assignment(+ClassID, +SubjectID, +TeacherID, +SlotID)
%% Log a variable assignment during CSP solving
%% Validates: Requirements 23.1
log_assignment(ClassID, SubjectID, TeacherID, SlotID) :-
    should_log(debug),
    !,
    get_timestamp(Timestamp),
    format(user_error, '[~w] ASSIGNMENT: Class=~w, Subject=~w, Teacher=~w, Slot=~w~n', 
           [Timestamp, ClassID, SubjectID, TeacherID, SlotID]).

log_assignment(_, _, _, _).

%% log_backtrack(+Reason)
%% Log a backtracking event during CSP solving
%% Validates: Requirements 23.2
log_backtrack(Reason) :-
    should_log(debug),
    !,
    get_timestamp(Timestamp),
    format(user_error, '[~w] BACKTRACK: ~w~n', [Timestamp, Reason]).

log_backtrack(_).

%% log_constraint_violation(+ConstraintType, +Details)
%% Log a constraint violation encountered during search
%% Validates: Requirements 23.3
log_constraint_violation(ConstraintType, Details) :-
    should_log(debug),
    !,
    get_timestamp(Timestamp),
    format(user_error, '[~w] CONSTRAINT_VIOLATION: ~w - ~w~n', [Timestamp, ConstraintType, Details]).

log_constraint_violation(_, _).

%% ============================================================================
%% Utility Predicates
%% ============================================================================

%% log_section(+SectionName)
%% Log a section header for better readability
log_section(SectionName) :-
    should_log(info),
    !,
    get_timestamp(Timestamp),
    format(user_error, '~n[~w] ========== ~w ==========~n', [Timestamp, SectionName]).

log_section(_).

%% log_list(+Label, +List)
%% Log a list with a label (useful for debugging)
log_list(Label, List) :-
    should_log(debug),
    !,
    get_timestamp(Timestamp),
    format(user_error, '[~w] ~w: ~w~n', [Timestamp, Label, List]).

log_list(_, _).

%% log_count(+Label, +Count)
%% Log a count with a label
log_count(Label, Count) :-
    should_log(info),
    !,
    get_timestamp(Timestamp),
    format(user_error, '[~w] ~w: ~w~n', [Timestamp, Label, Count]).

log_count(_, _).

%% ============================================================================
%% End of logging.pl
%% ============================================================================
