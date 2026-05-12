"""Multiparadigm solvers: C++ (nanobind), SWI-Prolog, Rust (PyO3)."""

from __future__ import annotations

import importlib.util
from pathlib import Path
from typing import List, Optional, Sequence, Tuple

from multiparadigm import prolog as prolog_bridge

try:
    import multiparadigm_cpp as _cpp
except ImportError:  # pragma: no cover
    _cpp = None

try:
    import multiparadigm_rust as _rust
except ImportError:  # pragma: no cover
    _rust = None


def solve_sudoku_cpp(grid: Sequence[int]) -> Tuple[Optional[List[int]], Optional[str]]:
    if _cpp is None:
        raise RuntimeError("multiparadigm_cpp extension is not on PYTHONPATH")
    if len(grid) != 81:
        raise ValueError("Sudoku grid must have length 81")
    sol, err = _cpp.solve_sudoku([int(x) for x in grid])  # type: ignore[misc]
    if sol is None:
        return None, err
    return list(sol), err


def solve_maze_cpp(adj: Sequence[Sequence[int]], start: int, goal: int) -> Tuple[Optional[List[int]], Optional[str]]:
    if _cpp is None:
        raise RuntimeError("multiparadigm_cpp extension is not on PYTHONPATH")
    path, err = _cpp.solve_maze_bfs([list(map(int, row)) for row in adj], int(start), int(goal))  # type: ignore[misc]
    if path is None:
        return None, err
    return list(path), err


def solve_sudoku_rust(grid: Sequence[int]) -> Tuple[Optional[List[int]], Optional[str]]:
    if _rust is None:
        raise RuntimeError("multiparadigm_rust extension is not on PYTHONPATH")
    if len(grid) != 81:
        raise ValueError("Sudoku grid must have length 81")
    sol, err = _rust.solve_sudoku_py([int(x) for x in grid])  # type: ignore[attr-defined]
    if sol is None:
        return None, err
    return list(sol), err


def solve_maze_rust(adj: Sequence[Sequence[int]], start: int, goal: int) -> Tuple[Optional[List[int]], Optional[str]]:
    if _rust is None:
        raise RuntimeError("multiparadigm_rust extension is not on PYTHONPATH")
    path, err = _rust.solve_maze_bfs_py([list(map(int, row)) for row in adj], int(start), int(goal))  # type: ignore[attr-defined]
    if path is None:
        return None, err
    return list(path), err


def solve_sudoku_prolog(grid: Sequence[int]) -> Tuple[Optional[List[int]], Optional[str]]:
    return prolog_bridge.solve_sudoku(list(map(int, grid)))


def solve_maze_prolog(adj: Sequence[Sequence[int]], start: int, goal: int) -> Tuple[Optional[List[int]], Optional[str]]:
    return prolog_bridge.solve_maze([list(map(int, row)) for row in adj], int(start), int(goal))


def load_native_extensions(explicit_dir: Path | None = None) -> None:
    """Load `.so` files when they are not discoverable via normal imports."""
    global _cpp, _rust
    here = Path(__file__).resolve().parent
    roots = [explicit_dir] if explicit_dir is not None else [here.parent, here]
    for root in roots:
        if root is None:
            continue
        for fname, slot in (("multiparadigm_cpp.so", "_cpp"), ("multiparadigm_rust.so", "_rust")):
            path = root / fname
            if not path.is_file():
                continue
            name = fname.removesuffix(".so")
            spec = importlib.util.spec_from_file_location(name, path)
            if spec is None or spec.loader is None:
                continue
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            if slot == "_cpp":
                _cpp = module
            else:
                _rust = module
