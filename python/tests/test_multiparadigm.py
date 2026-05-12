"""Integration tests for native extensions and Python wrappers."""

from __future__ import annotations

import gc
import os
import sys
import unittest
from pathlib import Path

# Verified completed Sudoku (row-major); regression input for C++/Rust solvers.
_COMPLETED_VALID: list[int] = [int(c) for c in "534678912672195348198342567859761423426853791713924856961537284287419635345286179"]


class TestNativeSolvers(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        # Repo layout: python/tests/this_file.py -> python/ is parents[1]
        py_root = Path(__file__).resolve().parents[1]
        if str(py_root) not in sys.path:
            sys.path.insert(0, str(py_root))
        # Bazel runfiles: ensure the `python/` tree is first.
        for key in ("RUNFILES_DIR", "TEST_SRCDIR"):
            v = os.environ.get(key)
            if v:
                rf = Path(v) / "_main" / "python"
                if rf.is_dir():
                    p = str(rf)
                    if p not in sys.path:
                        sys.path.insert(0, p)
                    py_root = rf
                    break

        import multiparadigm as mp

        cls._mp = mp
        mp.load_native_extensions(py_root)

    def test_cpp_maze(self) -> None:
        adj = [[1], [0, 2], [1, 3], [2]]
        path, err = self._mp.solve_maze_cpp(adj, 0, 3)
        self.assertIsNone(err)
        self.assertEqual(path, [0, 1, 2, 3])

    def test_rust_maze(self) -> None:
        adj = [[1], [0, 2], [1, 3], [2]]
        path, err = self._mp.solve_maze_rust(adj, 0, 3)
        self.assertIsNone(err)
        self.assertEqual(path, [0, 1, 2, 3])

    def test_cpp_sudoku_completed(self) -> None:
        g = list(_COMPLETED_VALID)
        sol, err = self._mp.solve_sudoku_cpp(g)
        self.assertIsNone(err, msg=repr(err))
        self.assertIsNotNone(sol)
        assert sol is not None
        self.assertEqual(len(sol), 81)
        self.assertEqual(sol, g)

    def test_cpp_sudoku_one_blank(self) -> None:
        g = list(_COMPLETED_VALID)
        g[40] = 0
        sol, err = self._mp.solve_sudoku_cpp(g)
        self.assertIsNone(err, msg=repr(err))
        assert sol is not None
        self.assertEqual(sol[40], _COMPLETED_VALID[40])

    def test_rust_sudoku_completed(self) -> None:
        g = list(_COMPLETED_VALID)
        sol, err = self._mp.solve_sudoku_rust(g)
        self.assertIsNone(err, msg=repr(err))
        self.assertIsNotNone(sol)
        assert sol is not None
        self.assertEqual(len(sol), 81)
        self.assertEqual(sol, g)

    def test_rust_sudoku_one_blank(self) -> None:
        g = list(_COMPLETED_VALID)
        g[40] = 0
        sol, err = self._mp.solve_sudoku_rust(g)
        self.assertIsNone(err, msg=repr(err))
        assert sol is not None
        self.assertEqual(sol[40], _COMPLETED_VALID[40])

    def test_solve_stress_gc(self) -> None:
        adj = [[1], [0, 2], [1, 3], [2]]
        for _ in range(3_000):
            self._mp.solve_maze_cpp(adj, 0, 3)
            self._mp.solve_maze_rust(adj, 0, 3)
        gc.collect()


if __name__ == "__main__":
    unittest.main()
