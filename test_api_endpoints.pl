% test_api_endpoints.pl - Test HTTP endpoint registration

:- use_module(library(http/http_dispatch)).
:- use_module(backend/api_server).

test_endpoints :-
    writeln('==========================================='),
    writeln('HTTP Endpoint Registration Tests'),
    writeln('==========================================='),
    writeln(''),
    
    writeln('Checking registered HTTP handlers:'),
    findall(Path-Pred, http_current_handler(Path, Pred), Handlers),
    length(Handlers, NumHandlers),
    format('Found ~w registered handlers:~n~n', [NumHandlers]),
    
    forall(member(Path-Pred, Handlers),
           format('  ~w -> ~w~n', [Path, Pred])),
    
    writeln(''),
    writeln('==========================================='),
    
    % Check specific API endpoints
    writeln('Verifying API endpoints:'),
    check_endpoint('/api/resources', 'POST /api/resources'),
    check_endpoint('/api/generate', 'POST /api/generate'),
    check_endpoint('/api/timetable', 'GET /api/timetable'),
    check_endpoint('/api/reliability', 'GET /api/reliability'),
    check_endpoint('/api/explain', 'POST /api/explain'),
    check_endpoint('/api/conflicts', 'GET /api/conflicts'),
    check_endpoint('/api/repair', 'POST /api/repair'),
    check_endpoint('/api/analytics', 'GET /api/analytics'),
    check_endpoint('/api/export', 'GET /api/export'),
    
    writeln(''),
    writeln('==========================================='),
    writeln('Endpoint registration test completed'),
    writeln('===========================================').

check_endpoint(Path, Description) :-
    (   http_current_handler(Path, _)
    ->  format('  ✓ ~w registered~n', [Description])
    ;   format('  ✗ ~w NOT registered~n', [Description])
    ).

:- initialization(test_endpoints, main).
