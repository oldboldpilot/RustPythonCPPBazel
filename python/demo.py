"""Smoke script for `bazel run //python:demo` — C++, Rust, and SWI-Prolog solvers side by side."""

from __future__ import annotations

import shutil
from typing import List, Optional, Sequence

from multiparadigm import (
    solve_maze_cpp,
    solve_maze_prolog,
    solve_maze_rust,
    solve_sudoku_cpp,
    solve_sudoku_prolog,
    solve_sudoku_rust,
)


def _completed_sudoku() -> List[int]:
    # Same verified grid as `python/tests/test_multiparadigm.py` (row-major).
    return [int(c) for c in "534678912672195348198342567859761423426853791713924856961537284287419635345286179"]


def _sudoku_one_blank() -> List[int]:
    g = _completed_sudoku()
    g[40] = 0
    return g


def _print_sudoku_line(label: str, sol: Optional[List[int]], err: Optional[str]) -> None:
    if sol is not None:
        print(f"  {label}: solved (filled cell 40 = {sol[40]})")
    else:
        print(f"  {label}: failed ({err!r})")


def _print_maze_line(label: str, path: Optional[List[int]], err: Optional[str]) -> None:
    if path is not None:
        print(f"  {label}: {path}")
    else:
        print(f"  {label}: failed ({err!r})")


def _run_prolog_sudoku(grid: Sequence[int]) -> None:
    label = "Prolog (SWI)"
    if not shutil.which("swipl"):
        print(f"  {label}: skipped (no `swipl` on PATH — install SWI-Prolog)")
        return
    try:
        sol, err = solve_sudoku_prolog(list(map(int, grid)))
    except FileNotFoundError:
        print(f"  {label}: skipped (`swipl` not executable)")
        return
    _print_sudoku_line(label, sol, err)


def _run_prolog_maze(adj: List[List[int]], start: int, goal: int) -> None:
    label = "Prolog (SWI)"
    if not shutil.which("swipl"):
        print(f"  {label}: skipped (no `swipl` on PATH — install SWI-Prolog)")
        return
    try:
        path, err = solve_maze_prolog(adj, start, goal)
    except FileNotFoundError:
        print(f"  {label}: skipped (`swipl` not executable)")
        return
    _print_maze_line(label, path, err)


def main() -> None:
    grid = _sudoku_one_blank()
    print("Sudoku (one blank; same puzzle for C++ / Rust / Prolog):")
    s_cpp, e_cpp = solve_sudoku_cpp(grid)
    _print_sudoku_line("C++", s_cpp, e_cpp)
    s_rs, e_rs = solve_sudoku_rust(grid)
    _print_sudoku_line("Rust", s_rs, e_rs)
    _run_prolog_sudoku(grid)

    adj: List[List[int]] = [[1], [0, 2], [1, 3], [2]]
    print("Maze BFS (line graph 0 → 3; same graph for C++ / Rust / Prolog):")
    _print_maze_line("C++", *solve_maze_cpp(adj, 0, 3))
    _print_maze_line("Rust", *solve_maze_rust(adj, 0, 3))
    _run_prolog_maze(adj, 0, 3)


if __name__ == "__main__":
    main()
