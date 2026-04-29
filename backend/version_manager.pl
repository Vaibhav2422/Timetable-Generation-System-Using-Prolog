%% ============================================================================
%% version_manager.pl - Timetable Versioning System (Feature 20)
%% ============================================================================
%% Provides save/load/compare/rollback functionality for timetable versions.
%% Versions are stored as dynamic facts:
%%   timetable_version(VersionID, Timestamp, Metadata, Timetable)
%%
%% Requirements: 20.1-20.5 (version control aspects)
%% ============================================================================

:- module(version_manager, [
    save_version/2,
    load_version/2,
    list_versions/1,
    compare_versions/3,
    rollback_to_version/2,
    version_metadata/2
]).

:- use_module(library(lists)).

%% Dynamic storage for versions
%% timetable_version(VersionID, Timestamp, Metadata, Timetable)
:- dynamic timetable_version/4.

%% Counter for auto-incrementing version IDs
:- dynamic version_counter/1.
version_counter(0).

%% ============================================================================
%% save_version(+Timetable, -VersionID)
%% Save a timetable snapshot with an auto-generated version ID and timestamp.
%% Metadata is a dict with: timestamp, author, reason (defaults provided).
%% ============================================================================
save_version(Timetable, VersionID) :-
    save_version(Timetable, VersionID, _{author: 'system', reason: 'manual save'}).

save_version(Timetable, VersionID, ExtraMeta) :-
    %% Generate unique version ID
    next_version_id(VersionID),
    %% Get current timestamp
    get_time(Now),
    format_time(atom(Timestamp), '%Y-%m-%dT%H:%M:%S', Now),
    %% Build metadata dict
    (get_dict(author, ExtraMeta, Author) -> true ; Author = 'system'),
    (get_dict(reason, ExtraMeta, Reason) -> true ; Reason = 'manual save'),
    Metadata = _{
        version_id: VersionID,
        timestamp:  Timestamp,
        author:     Author,
        reason:     Reason
    },
    %% Persist
    assertz(timetable_version(VersionID, Timestamp, Metadata, Timetable)),
    format(atom(LogMsg), 'Version ~w saved at ~w', [VersionID, Timestamp]),
    (catch(use_module(logging), _, true) -> true ; true),
    (catch(log_info(LogMsg), _, format('[INFO] ~w~n', [LogMsg])) -> true ; true).

%% ============================================================================
%% load_version(+VersionID, -Timetable)
%% Retrieve the timetable stored under VersionID.
%% Fails if the version does not exist.
%% ============================================================================
load_version(VersionID, Timetable) :-
    timetable_version(VersionID, _, _, Timetable).

%% ============================================================================
%% list_versions(-Versions)
%% Return a list of all saved version metadata dicts, newest first.
%% ============================================================================
list_versions(Versions) :-
    findall(Meta, timetable_version(_, _, Meta, _), AllMeta),
    sort_versions_desc(AllMeta, Versions).

%% sort_versions_desc(+Metas, -Sorted)
%% Sort version metadata by version_id descending (newest first).
sort_versions_desc(Metas, Sorted) :-
    findall(VID-Meta,
            (member(Meta, Metas), get_dict(version_id, Meta, VID)),
            Pairs),
    sort(0, @>=, Pairs, SortedPairs),
    pairs_values(SortedPairs, Sorted).

%% ============================================================================
%% compare_versions(+VersionIDA, +VersionIDB, -Diff)
%% Produce a detailed diff between two saved versions.
%% Diff is a dict: { added, removed, unchanged, version_a, version_b }
%% ============================================================================
compare_versions(VersionIDA, VersionIDB, Diff) :-
    load_version(VersionIDA, TimetableA),
    load_version(VersionIDB, TimetableB),
    version_metadata(VersionIDA, MetaA),
    version_metadata(VersionIDB, MetaB),
    %% Collect assignments from each version
    collect_assignments(TimetableA, AssignmentsA),
    collect_assignments(TimetableB, AssignmentsB),
    %% Compute diff
    subtract(AssignmentsB, AssignmentsA, Added),
    subtract(AssignmentsA, AssignmentsB, Removed),
    intersection(AssignmentsA, AssignmentsB, Unchanged),
    length(Added, AddedCount),
    length(Removed, RemovedCount),
    length(Unchanged, UnchangedCount),
    Diff = _{
        version_a:       VersionIDA,
        version_b:       VersionIDB,
        meta_a:          MetaA,
        meta_b:          MetaB,
        added:           Added,
        removed:         Removed,
        unchanged:       Unchanged,
        added_count:     AddedCount,
        removed_count:   RemovedCount,
        unchanged_count: UnchangedCount
    }.

%% collect_assignments(+Timetable, -Assignments)
%% Flatten a timetable matrix into a list of assignment terms.
collect_assignments(Timetable, Assignments) :-
    (is_list(Timetable) ->
        flatten(Timetable, Cells),
        findall(A, (member(A, Cells), A \= empty, A \= []), Assignments)
    ;
        Assignments = []
    ).

%% ============================================================================
%% rollback_to_version(+VersionID, -Timetable)
%% Restore the current timetable to a previously saved version.
%% The restored timetable is returned and also stored as current_timetable/1
%% (if that dynamic fact is available in the calling context).
%% ============================================================================
rollback_to_version(VersionID, Timetable) :-
    (timetable_version(VersionID, _, _, Timetable) ->
        %% Update current_timetable if the predicate exists
        (catch(
            (retractall(current_timetable(_)),
             assertz(current_timetable(Timetable))),
            _,
            true
        )),
        format(atom(LogMsg), 'Rolled back to version ~w', [VersionID]),
        (catch(log_info(LogMsg), _, format('[INFO] ~w~n', [LogMsg])) -> true ; true)
    ;
        throw(error(version_not_found, VersionID))
    ).

%% ============================================================================
%% version_metadata(+VersionID, -Metadata)
%% Retrieve the metadata dict for a specific version.
%% ============================================================================
version_metadata(VersionID, Metadata) :-
    timetable_version(VersionID, _, Metadata, _).

%% ============================================================================
%% Internal helpers
%% ============================================================================

%% next_version_id(-VersionID)
%% Atomically increment the version counter and return the new ID.
next_version_id(VersionID) :-
    retract(version_counter(N)),
    N1 is N + 1,
    assertz(version_counter(N1)),
    atom_concat('v', N1, VersionID).
