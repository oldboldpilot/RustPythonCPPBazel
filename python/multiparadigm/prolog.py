"""SWI-Prolog backends (requires `swipl` on `PATH`)."""

from __future__ import annotations

import os
import subprocess
import tempfile
from pathlib import Path
from typing import List, Optional, Tuple

_PROLOG_DIR = Path(__file__).resolve().parents[2] / "prolog"


def _run_swipl(pl_body: str) -> Tuple[int, str]:
    with tempfile.NamedTemporaryFile("w", suffix=".pl", delete=False) as f:
        f.write(pl_body)
        tmp = f.name
    try:
        proc = subprocess.run(
            ["swipl", "-q", "-s", tmp, "-g", "run", "-t", "halt"],
            capture_output=True,
            text=True,
            check=False,
        )
        return proc.returncode, (proc.stdout or "") + (proc.stderr or "")
    finally:
        os.unlink(tmp)


def _parse_int_list(line: str) -> Optional[List[int]]:
    inner = line.strip()
    if not inner.startswith("[") or not inner.endswith("]"):
        return None
    parts = [p.strip() for p in inner[1:-1].split(",") if p.strip()]
    try:
        return [int(p) for p in parts]
    except ValueError:
        return None


def solve_sudoku(grid: List[int]) -> Tuple[Optional[List[int]], Optional[str]]:
    if len(grid) != 81:
        raise ValueError("Sudoku grid must have length 81")
    sudoku_pl = _PROLOG_DIR / "sudoku.pl"
    if not sudoku_pl.is_file():
        return None, f"missing_prolog_file:{sudoku_pl}"
    grid_lit = "[" + ",".join(str(int(x)) for x in grid) + "]"
    body = (
        f":- use_module('{sudoku_pl.as_posix()}').\n"
        "run :-\n"
        f"  Grid = {grid_lit},\n"
        "  ( swipl_solve_sudoku(Grid, Sol)\n"
        "  -> write_term(Sol, [quoted(true)]), nl\n"
        "  ; write('UNSAT'), nl\n"
        "  ).\n"
    )
    code, out = _run_swipl(body)
    if code != 0:
        return None, "swipl_failed"
    lines = [ln for ln in out.splitlines() if ln.strip()]
    if not lines:
        return None, "empty_output"
    last = lines[-1].strip()
    if last == "UNSAT":
        return None, "unsolvable_or_invalid"
    parsed = _parse_int_list(last)
    if parsed is None or len(parsed) != 81:
        return None, "parse_error"
    return parsed, None


def solve_maze(adj: List[List[int]], start: int, goal: int) -> Tuple[Optional[List[int]], Optional[str]]:
    maze_pl = _PROLOG_DIR / "maze.pl"
    if not maze_pl.is_file():
        return None, f"missing_prolog_file:{maze_pl}"
    adj_lit = "[" + ",".join("[" + ",".join(str(int(x)) for x in row) + "]" for row in adj) + "]"
    body = (
        f":- use_module('{maze_pl.as_posix()}').\n"
        "run :-\n"
        f"  Adj = {adj_lit},\n"
        f"  ( swipl_solve_maze(Adj, {int(start)}, {int(goal)}, Path)\n"
        "  -> write_term(Path, [quoted(true)]), nl\n"
        "  ; write('UNSAT'), nl\n"
        "  ).\n"
    )
    code, out = _run_swipl(body)
    if code != 0:
        return None, "swipl_failed"
    lines = [ln for ln in out.splitlines() if ln.strip()]
    if not lines:
        return None, "empty_output"
    last = lines[-1].strip()
    if last == "UNSAT":
        return None, "no_path_or_invalid"
    parsed = _parse_int_list(last)
    if parsed is None:
        return None, "parse_error"
    return parsed, None
