:- module(swipl_maze, [swipl_solve_maze/4]).

:- use_module(library(assoc)).

%% swipl_solve_maze(+Adjacency, +Start, +Goal, -Path)
%% Adjacency: list of length N; I-th element is neighbors of node I (integers).
swipl_solve_maze(Adj, Start, Goal, Path) :-
    length(Adj, N),
    integer(Start), integer(Goal),
    Start >= 0, Start < N,
    Goal >= 0, Goal < N,
    empty_assoc(M0),
    put_assoc(Start, M0, nil, M1),
    bfs(Adj, [Start], Goal, M1, ParentMap),
    build_path(Goal, ParentMap, Rev),
    reverse(Rev, Path).

bfs(_, [Goal|_], Goal, Map, Map) :- !.
bfs(Adj, [U|Rest], Goal, Map0, Map) :-
    nth0(U, Adj, Nbs),
    expand_neighbors(Nbs, U, Map0, Map1, NewNodes),
    append(Rest, NewNodes, Queue),
    bfs(Adj, Queue, Goal, Map1, Map).

expand_neighbors([], _, M, M, []).
expand_neighbors([V|Vs], U, M0, M, NewNodes) :-
    (   get_assoc(V, M0, _)
    ->  expand_neighbors(Vs, U, M0, M, NewNodes)
    ;   put_assoc(V, M0, U, M1),
        expand_neighbors(Vs, U, M1, M, Tail),
        NewNodes = [V|Tail]
    ).

build_path(Node, Map, [Node|Rest]) :-
    get_assoc(Node, Map, P),
    (   P = nil
    ->  Rest = []
    ;   build_path(P, Map, Rest)
    ).
