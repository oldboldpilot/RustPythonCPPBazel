:- module(swipl_sudoku, [swipl_solve_sudoku/2]).

:- use_module(library(clpfd)).

%% swipl_solve_sudoku(+Grid81, -Solution81) — row-major, 0 = blank, 1..9 = clue.
swipl_solve_sudoku(Grid, Solution) :-
    length(Grid, 81),
    rows9(Grid, RowsIn),
    maplist(map_row, RowsIn, Rows),
    sudoku(Rows),
    append(Rows, Solution).

rows9(G, [R1,R2,R3,R4,R5,R6,R7,R8,R9]) :-
    chunk9(G, R1, T1),
    chunk9(T1, R2, T2),
    chunk9(T2, R3, T3),
    chunk9(T3, R4, T4),
    chunk9(T4, R5, T5),
    chunk9(T5, R6, T6),
    chunk9(T6, R7, T7),
    chunk9(T7, R8, T8),
    chunk9(T8, R9, []).

chunk9(List, Row, Rest) :-
    length(Row, 9),
    append(Row, Rest, List).

map_row(RowIn, RowOut) :-
    maplist(cell, RowIn, RowOut).

cell(0, V) :- V in 1..9.
cell(N, N) :- N in 1..9.

sudoku(Rows) :-
    maplist(all_distinct, Rows),
    transpose(Rows, Cols),
    maplist(all_distinct, Cols),
    Rows = [R1,R2,R3,R4,R5,R6,R7,R8,R9],
    blocks(R1,R2,R3),
    blocks(R4,R5,R6),
    blocks(R7,R8,R9),
    maplist(labeling([ffc]), Rows).

blocks([], [], []).
blocks([A,B,C|As],[D,E,F|Bs],[G,H,I|Cs]) :-
    all_distinct([A,B,C,D,E,F,G,H,I]),
    blocks(As,Bs,Cs).
