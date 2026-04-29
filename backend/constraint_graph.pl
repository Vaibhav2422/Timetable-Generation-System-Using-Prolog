%% ============================================================================
%% constraint_graph.pl - Constraint Graph Visualization Module
%% ============================================================================
%% This module generates a graph structure representing the constraint
%% relationships between scheduling resources (teachers, subjects, rooms,
%% timeslots). The graph can be exported as JSON for visualization libraries
%% such as vis.js or D3.js.
%%
%% Graph Structure:
%%   Nodes: teachers, subjects, rooms, timeslots (colour-coded by type)
%%   Edges: qualification links, room requirements, availability links
%%   Metrics: node degree, clustering coefficient, avg degree
%%
%% Requirements: Feature 16 (Constraint Graph Visualization)
%%
%% Author: AI Timetable Generation System
%% ============================================================================

:- module(constraint_graph, [
    generate_constraint_graph/1,
    add_resource_nodes/2,
    add_constraint_edges/2,
    calculate_graph_metrics/2,
    export_graph_json/2
]).

:- use_module(knowledge_base, [
    get_all_teachers/1,
    get_all_subjects/1,
    get_all_rooms/1,
    get_all_timeslots/1,
    qualified/2,
    suitable_room/2
]).
:- use_module(logging, [log_info/1, log_error/1]).

%% ============================================================================
%% generate_constraint_graph/1
%% Main entry point – builds the complete graph structure.
%%
%% @param Graph  Output dict: _{nodes: Nodes, edges: Edges, metrics: Metrics}
%% ============================================================================
generate_constraint_graph(Graph) :-
    log_info('Generating constraint graph'),
    add_resource_nodes([], Nodes),
    add_constraint_edges(Nodes, Edges),
    calculate_graph_metrics(Nodes, Edges, Metrics),
    Graph = _{nodes: Nodes, edges: Edges, metrics: Metrics},
    log_info('Constraint graph generated successfully').

%% ============================================================================
%% add_resource_nodes/2
%% Collect all resource nodes (teachers, subjects, rooms, timeslots).
%%
%% @param _Acc   Accumulator (pass [] initially)
%% @param Nodes  Output list of node dicts
%% ============================================================================
add_resource_nodes(_Acc, Nodes) :-
    collect_teacher_nodes(TeacherNodes),
    collect_subject_nodes(SubjectNodes),
    collect_room_nodes(RoomNodes),
    collect_timeslot_nodes(TimeslotNodes),
    append([TeacherNodes, SubjectNodes, RoomNodes, TimeslotNodes], Nodes).

%% collect_teacher_nodes(-Nodes)
collect_teacher_nodes(Nodes) :-
    get_all_teachers(Teachers),
    findall(Node,
            (member(teacher(TID, TName, _, _, _), Teachers),
             atom_concat('teacher_', TID, NodeID),
             Node = _{id: NodeID, label: TName, type: teacher, group: teacher}),
            Nodes).

%% collect_subject_nodes(-Nodes)
collect_subject_nodes(Nodes) :-
    get_all_subjects(Subjects),
    findall(Node,
            (member(subject(SID, SName, _, SType, _), Subjects),
             atom_concat('subject_', SID, NodeID),
             format(atom(Label), '~w (~w)', [SName, SType]),
             Node = _{id: NodeID, label: Label, type: subject, group: subject}),
            Nodes).

%% collect_room_nodes(-Nodes)
collect_room_nodes(Nodes) :-
    get_all_rooms(Rooms),
    findall(Node,
            (member(room(RID, RName, Cap, RType), Rooms),
             atom_concat('room_', RID, NodeID),
             format(atom(Label), '~w (~w, cap:~w)', [RName, RType, Cap]),
             Node = _{id: NodeID, label: Label, type: room, group: room}),
            Nodes).

%% collect_timeslot_nodes(-Nodes)
collect_timeslot_nodes(Nodes) :-
    get_all_timeslots(Slots),
    findall(Node,
            (member(timeslot(TSID, Day, Period, StartTime, _), Slots),
             atom_concat('timeslot_', TSID, NodeID),
             format(atom(Label), '~w P~w ~w', [Day, Period, StartTime]),
             Node = _{id: NodeID, label: Label, type: timeslot, group: timeslot}),
            Nodes).

%% ============================================================================
%% add_constraint_edges/2
%% Build edges representing constraint relationships between nodes.
%%
%% Edge types:
%%   qualification  – teacher → subject  (teacher qualifies for subject)
%%   room_requirement – subject → room   (subject requires room type)
%%   availability   – teacher → timeslot (teacher available at slot)
%%
%% @param Nodes  List of node dicts (used to validate node existence)
%% @param Edges  Output list of edge dicts
%% ============================================================================
add_constraint_edges(Nodes, Edges) :-
    collect_node_ids(Nodes, NodeIDs),
    collect_qualification_edges(NodeIDs, QualEdges),
    collect_room_requirement_edges(NodeIDs, RoomEdges),
    collect_availability_edges(NodeIDs, AvailEdges),
    append([QualEdges, RoomEdges, AvailEdges], Edges).

%% collect_node_ids(+Nodes, -IDs)
collect_node_ids(Nodes, IDs) :-
    findall(ID, (member(Node, Nodes), get_dict(id, Node, ID)), IDs).

%% collect_qualification_edges(+NodeIDs, -Edges)
%% teacher → subject edges for qualification constraints
collect_qualification_edges(NodeIDs, Edges) :-
    get_all_teachers(Teachers),
    get_all_subjects(Subjects),
    findall(Edge,
            (member(teacher(TID, _, _, _, _), Teachers),
             member(subject(SID, _, _, _, _), Subjects),
             qualified(TID, SID),
             atom_concat('teacher_', TID, FromID),
             atom_concat('subject_', SID, ToID),
             member(FromID, NodeIDs),
             member(ToID, NodeIDs),
             Edge = _{from: FromID, to: ToID,
                      label: qualifies, type: qualification}),
            Edges).

%% collect_room_requirement_edges(+NodeIDs, -Edges)
%% subject → room edges for room-type requirements
collect_room_requirement_edges(NodeIDs, Edges) :-
    get_all_subjects(Subjects),
    get_all_rooms(Rooms),
    findall(Edge,
            (member(subject(SID, _, _, _, _), Subjects),
             member(room(RID, _, _, _), Rooms),
             suitable_room(RID, SID),
             atom_concat('subject_', SID, FromID),
             atom_concat('room_', RID, ToID),
             member(FromID, NodeIDs),
             member(ToID, NodeIDs),
             Edge = _{from: FromID, to: ToID,
                      label: requires, type: room_requirement}),
            Edges).

%% collect_availability_edges(+NodeIDs, -Edges)
%% teacher → timeslot edges for availability constraints
collect_availability_edges(NodeIDs, Edges) :-
    get_all_teachers(Teachers),
    get_all_timeslots(Slots),
    findall(Edge,
            (member(teacher(TID, _, _, _, Avail), Teachers),
             member(timeslot(TSID, _, _, _, _), Slots),
             member(TSID, Avail),
             atom_concat('teacher_', TID, FromID),
             atom_concat('timeslot_', TSID, ToID),
             member(FromID, NodeIDs),
             member(ToID, NodeIDs),
             Edge = _{from: FromID, to: ToID,
                      label: available, type: availability}),
            Edges).

%% ============================================================================
%% calculate_graph_metrics/3
%% Compute summary metrics for the graph.
%%
%% Metrics computed:
%%   node_count  – total number of nodes
%%   edge_count  – total number of edges
%%   avg_degree  – average node degree (edges per node)
%%
%% @param Nodes    List of node dicts
%% @param Edges    List of edge dicts
%% @param Metrics  Output dict
%% ============================================================================
calculate_graph_metrics(Nodes, Edges, Metrics) :-
    length(Nodes, NodeCount),
    length(Edges, EdgeCount),
    (NodeCount > 0 ->
        AvgDegree is (EdgeCount * 2) / NodeCount
    ;
        AvgDegree is 0.0
    ),
    %% Per-node degree map
    compute_node_degrees(Nodes, Edges, DegreePairs),
    Metrics = _{
        node_count: NodeCount,
        edge_count: EdgeCount,
        avg_degree: AvgDegree,
        node_degrees: DegreePairs
    }.

%% Kept for backward compatibility (2-arg version used in tests / old callers)
calculate_graph_metrics(Graph, Metrics) :-
    get_dict(nodes, Graph, Nodes),
    get_dict(edges, Graph, Edges),
    calculate_graph_metrics(Nodes, Edges, Metrics).

%% compute_node_degrees(+Nodes, +Edges, -DegreePairs)
%% Returns a list of _{id: ID, degree: D} dicts.
compute_node_degrees(Nodes, Edges, DegreePairs) :-
    findall(_{id: NodeID, degree: Degree},
            (member(Node, Nodes),
             get_dict(id, Node, NodeID),
             count_node_degree(NodeID, Edges, Degree)),
            DegreePairs).

%% count_node_degree(+NodeID, +Edges, -Degree)
count_node_degree(NodeID, Edges, Degree) :-
    findall(1,
            (member(Edge, Edges),
             (get_dict(from, Edge, NodeID) ; get_dict(to, Edge, NodeID))),
            Matches),
    length(Matches, Degree).

%% ============================================================================
%% export_graph_json/2
%% Serialise the graph structure to a JSON-compatible Prolog dict.
%%
%% @param Graph      Input graph dict (nodes, edges, metrics)
%% @param JSONOutput Output JSON-compatible dict
%% ============================================================================
export_graph_json(Graph, JSONOutput) :-
    get_dict(nodes,   Graph, Nodes),
    get_dict(edges,   Graph, Edges),
    get_dict(metrics, Graph, Metrics),
    JSONOutput = _{
        nodes:   Nodes,
        edges:   Edges,
        metrics: Metrics
    }.

%% ============================================================================
%% End of constraint_graph.pl
%% ============================================================================
