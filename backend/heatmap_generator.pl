%% ============================================================================
%% heatmap_generator.pl - Visual Heatmap Generation Module
%% ============================================================================
%% Generates heatmap data structures showing utilization intensity across
%% teachers, rooms, and time slots. Intensity values are normalised to [0.0, 1.0]
%% where 0.0 = unused and 1.0 = maximum utilization.
%%
%% Requirements: 21.1, 21.3, 22.1, 22.2
%% ============================================================================

:- module(heatmap_generator, [
    generate_heatmap/2,
    calculate_cell_intensity/3,
    teacher_heatmap/2,
    room_heatmap/2,
    timeslot_heatmap/2
]).

:- use_module(knowledge_base).
:- use_module(matrix_model).
:- use_module(logging).

:- multifile teacher/5, subject/5, room/4, timeslot/5, class/3.
:- dynamic   teacher/5, subject/5, room/4, timeslot/5, class/3.

%% ============================================================================
%% generate_heatmap/2 - Main entry point
%% ============================================================================
%% Format: generate_heatmap(+HeatmapType, -HeatmapData)
%%
%% Dispatches to the appropriate heatmap generator based on type.
%% HeatmapType is one of: teacher | room | timeslot
%%
%% @param HeatmapType  Atom identifying which heatmap to generate
%% @param HeatmapData  Dict: { type, cells: [{id, label, intensity}] }
%%
generate_heatmap(teacher, HeatmapData) :-
    !,
    teacher_heatmap(teacher, HeatmapData).

generate_heatmap(room, HeatmapData) :-
    !,
    room_heatmap(room, HeatmapData).

generate_heatmap(timeslot, HeatmapData) :-
    !,
    timeslot_heatmap(timeslot, HeatmapData).

generate_heatmap(Type, _) :-
    format(atom(Msg), 'Unknown heatmap type: ~w. Use teacher, room, or timeslot.', [Type]),
    throw(error(invalid_heatmap_type, Msg)).

%% ============================================================================
%% teacher_heatmap/2 - Teacher workload heatmap
%% ============================================================================
%% Format: teacher_heatmap(+_Type, -HeatmapData)
%%
%% Each cell represents a teacher. Intensity = sessions_assigned / max_load.
%% A teacher at full capacity scores 1.0.
%%
teacher_heatmap(_, HeatmapData) :-
    log_info('Generating teacher heatmap'),
    (current_timetable(Matrix) -> true ; Matrix = []),
    get_all_assignments(Matrix, Assignments),
    get_all_teachers(Teachers),
    (Teachers = [] ->
        Cells = []
    ;
        findall(Cell,
                (member(teacher(TID, TName, _, MaxLoad, _), Teachers),
                 calculate_teacher_intensity(TID, MaxLoad, Assignments, Intensity),
                 Cell = _{id: TID, label: TName, intensity: Intensity}),
                Cells)
    ),
    HeatmapData = _{type: teacher, cells: Cells}.

%% calculate_teacher_intensity(+TeacherID, +MaxLoad, +Assignments, -Intensity)
%% Intensity = assigned_sessions / max_load, capped at 1.0
calculate_teacher_intensity(TeacherID, MaxLoad, Assignments, Intensity) :-
    findall(1, member(assigned(_, _, _, TeacherID, _), Assignments), Hits),
    length(Hits, Count),
    (MaxLoad > 0 ->
        Raw is Count / MaxLoad,
        Intensity is min(1.0, Raw)
    ;
        Intensity = 0.0
    ).

%% ============================================================================
%% room_heatmap/2 - Room utilization heatmap
%% ============================================================================
%% Format: room_heatmap(+_Type, -HeatmapData)
%%
%% Each cell represents a room. Intensity = used_slots / total_slots.
%%
room_heatmap(_, HeatmapData) :-
    log_info('Generating room heatmap'),
    (current_timetable(Matrix) -> true ; Matrix = []),
    get_all_assignments(Matrix, Assignments),
    get_all_rooms(Rooms),
    get_all_timeslots(Slots),
    length(Slots, TotalSlots),
    (Rooms = [] ->
        Cells = []
    ;
        findall(Cell,
                (member(room(RID, RName, _, _), Rooms),
                 calculate_room_intensity(RID, TotalSlots, Assignments, Intensity),
                 Cell = _{id: RID, label: RName, intensity: Intensity}),
                Cells)
    ),
    HeatmapData = _{type: room, cells: Cells}.

%% calculate_room_intensity(+RoomID, +TotalSlots, +Assignments, -Intensity)
calculate_room_intensity(RoomID, TotalSlots, Assignments, Intensity) :-
    findall(1, member(assigned(RoomID, _, _, _, _), Assignments), Hits),
    length(Hits, Count),
    (TotalSlots > 0 ->
        Intensity is min(1.0, Count / TotalSlots)
    ;
        Intensity = 0.0
    ).

%% ============================================================================
%% timeslot_heatmap/2 - Time slot popularity heatmap
%% ============================================================================
%% Format: timeslot_heatmap(+_Type, -HeatmapData)
%%
%% Each cell represents a time slot. Intensity = rooms_used / total_rooms.
%%
timeslot_heatmap(_, HeatmapData) :-
    log_info('Generating timeslot heatmap'),
    (current_timetable(Matrix) -> true ; Matrix = []),
    get_all_assignments(Matrix, Assignments),
    get_all_timeslots(Slots),
    get_all_rooms(Rooms),
    length(Rooms, TotalRooms),
    (Slots = [] ->
        Cells = []
    ;
        findall(Cell,
                (member(timeslot(SID, Day, Period, StartTime, _), Slots),
                 calculate_slot_intensity(SID, TotalRooms, Assignments, Intensity),
                 format(atom(Label), '~w P~w (~w)', [Day, Period, StartTime]),
                 Cell = _{id: SID, label: Label, intensity: Intensity}),
                Cells)
    ),
    HeatmapData = _{type: timeslot, cells: Cells}.

%% calculate_slot_intensity(+SlotID, +TotalRooms, +Assignments, -Intensity)
calculate_slot_intensity(SlotID, TotalRooms, Assignments, Intensity) :-
    findall(1, member(assigned(_, _, _, _, SlotID), Assignments), Hits),
    length(Hits, Count),
    (TotalRooms > 0 ->
        Intensity is min(1.0, Count / TotalRooms)
    ;
        Intensity = 0.0
    ).

%% ============================================================================
%% calculate_cell_intensity/3 - Generic intensity calculator
%% ============================================================================
%% Format: calculate_cell_intensity(+Used, +Total, -Intensity)
%%
%% Normalises a usage count against a total capacity to produce [0.0, 1.0].
%%
%% @param Used      Number of used slots/sessions
%% @param Total     Maximum possible slots/sessions
%% @param Intensity Normalised intensity value in [0.0, 1.0]
%%
calculate_cell_intensity(_, 0, 0.0) :- !.
calculate_cell_intensity(Used, Total, Intensity) :-
    Total > 0,
    Raw is Used / Total,
    Intensity is min(1.0, max(0.0, Raw)).

%% ============================================================================
%% Dynamic timetable access
%% ============================================================================
:- dynamic current_timetable/1.

%% ============================================================================
%% End of heatmap_generator.pl
%% ============================================================================
