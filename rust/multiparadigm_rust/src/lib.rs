mod solvers;

use pyo3::prelude::*;
use solvers::{solve_maze_bfs_rust, solve_sudoku_rust};

#[pyfunction]
fn solve_sudoku_py(grid: [u8; 81]) -> (Option<[u8; 81]>, Option<&'static str>) {
    match solve_sudoku_rust(grid) {
        Ok(s) => (Some(s), None),
        Err(e) => (None, Some(e)),
    }
}

#[pyfunction]
fn solve_maze_bfs_py(adj: Vec<Vec<i32>>, start: i32, goal: i32) -> (Option<Vec<i32>>, Option<&'static str>) {
    match solve_maze_bfs_rust(&adj, start, goal) {
        Ok(p) => (Some(p), None),
        Err(e) => (None, Some(e)),
    }
}

#[pymodule]
fn multiparadigm_rust(m: &Bound<'_, PyModule>) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(solve_sudoku_py, m)?)?;
    m.add_function(wrap_pyfunction!(solve_maze_bfs_py, m)?)?;
    Ok(())
}
