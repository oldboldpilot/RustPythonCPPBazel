pub fn solve_sudoku_rust(grid: [u8; 81]) -> Result<[u8; 81], &'static str> {
    if !grid.iter().all(|&v| v <= 9) {
        return Err("invalid_input");
    }
    if !basic_consistent(&grid) {
        return Err("invalid_input");
    }
    let mut board = grid;
    if !solve_backtrack(&mut board, 0) {
        return Err("unsolvable");
    }
    Ok(board)
}

pub fn solve_maze_bfs_rust(adj: &[Vec<i32>], start: i32, goal: i32) -> Result<Vec<i32>, &'static str> {
    let n = adj.len() as i32;
    if n == 0 || start < 0 || goal < 0 || start >= n || goal >= n {
        return Err("invalid_graph");
    }
    for row in adj {
        for &v in row {
            if v < 0 || v >= n {
                return Err("invalid_graph");
            }
        }
    }
    if start == goal {
        return Ok(vec![start]);
    }
    use std::collections::{HashMap, HashSet, VecDeque};
    let mut q = VecDeque::new();
    let mut parent = HashMap::new();
    let mut seen = HashSet::new();
    q.push_back(start);
    seen.insert(start);
    while let Some(u) = q.pop_front() {
        for &v in &adj[u as usize] {
            if seen.contains(&v) {
                continue;
            }
            seen.insert(v);
            parent.insert(v, u);
            if v == goal {
                let mut path = vec![v];
                let mut cur = v;
                while cur != start {
                    let p = *parent.get(&cur).ok_or("no_path")?;
                    path.push(p);
                    cur = p;
                }
                path.reverse();
                return Ok(path);
            }
            q.push_back(v);
        }
    }
    Err("no_path")
}

fn idx(r: usize, c: usize) -> usize {
    r * 9 + c
}

fn valid_placement(b: &[u8; 81], r: usize, c: usize, n: u8) -> bool {
    for i in 0..9 {
        if b[idx(r, i)] == n && i != c {
            return false;
        }
        if b[idx(i, c)] == n && i != r {
            return false;
        }
    }
    let br = (r / 3) * 3;
    let bc = (c / 3) * 3;
    for dr in 0..3 {
        for dc in 0..3 {
            let rr = br + dr;
            let cc = bc + dc;
            if rr == r && cc == c {
                continue;
            }
            if b[idx(rr, cc)] == n {
                return false;
            }
        }
    }
    true
}

fn basic_consistent(grid: &[u8; 81]) -> bool {
    for r in 0..9 {
        for c in 0..9 {
            let v = grid[idx(r, c)];
            if v == 0 {
                continue;
            }
            for i in 0..9 {
                if i != c && grid[idx(r, i)] == v {
                    return false;
                }
                if i != r && grid[idx(i, c)] == v {
                    return false;
                }
            }
            let br = (r / 3) * 3;
            let bc = (c / 3) * 3;
            for dr in 0..3 {
                for dc in 0..3 {
                    let rr = br + dr;
                    let cc = bc + dc;
                    if rr == r && cc == c {
                        continue;
                    }
                    if grid[idx(rr, cc)] == v {
                        return false;
                    }
                }
            }
        }
    }
    true
}

fn solve_backtrack(b: &mut [u8; 81], pos: usize) -> bool {
    if pos == 81 {
        return true;
    }
    let r = pos / 9;
    let c = pos % 9;
    if b[idx(r, c)] != 0 {
        return solve_backtrack(b, pos + 1);
    }
    for n in 1u8..=9 {
        if !valid_placement(b, r, c, n) {
            continue;
        }
        b[idx(r, c)] = n;
        if solve_backtrack(b, pos + 1) {
            return true;
        }
        b[idx(r, c)] = 0;
    }
    false
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn maze_line_path() {
        let adj = vec![vec![1], vec![0, 2], vec![1, 3], vec![2]];
        let p = solve_maze_bfs_rust(&adj, 0, 3).unwrap();
        assert_eq!(p, vec![0, 1, 2, 3]);
    }

    #[test]
    fn maze_no_path() {
        let adj = vec![vec![], vec![]];
        assert_eq!(solve_maze_bfs_rust(&adj, 0, 1), Err("no_path"));
    }

    #[test]
    fn maze_invalid_neighbor() {
        let adj = vec![vec![2], vec![0]];
        assert_eq!(solve_maze_bfs_rust(&adj, 0, 1), Err("invalid_graph"));
    }

    #[test]
    fn sudoku_invalid_digit() {
        let mut g = [0u8; 81];
        g[0] = 10;
        assert_eq!(solve_sudoku_rust(g), Err("invalid_input"));
    }

    #[test]
    fn sudoku_duplicate_clue() {
        let mut g = [0u8; 81];
        g[super::idx(0, 0)] = 1;
        g[super::idx(0, 1)] = 1;
        assert_eq!(solve_sudoku_rust(g), Err("invalid_input"));
    }

    fn completed_valid() -> [u8; 81] {
        [
            5, 3, 4, 6, 7, 8, 9, 1, 2, 6, 7, 2, 1, 9, 5, 3, 4, 8, 1, 9, 8, 3, 4, 2, 5, 6, 7, 8, 5, 9, 7, 6, 1, 4, 2, 3, 4, 2, 6, 8, 5, 3, 7, 9, 1, 7, 1, 3, 9, 2, 4, 8, 5, 6, 9, 6, 1, 5, 3, 7, 2, 8, 4, 2, 8, 7, 4, 1, 9, 6, 3, 5, 3, 4, 5, 2, 8, 6, 1, 7, 9,
        ]
    }

    #[test]
    fn sudoku_accepts_completed_grid() {
        let g = completed_valid();
        let solved = solve_sudoku_rust(g).expect("solvable");
        assert_eq!(solved, g);
    }

    #[test]
    fn sudoku_fills_single_blank() {
        let mut g = completed_valid();
        g[40] = 0;
        let solved = solve_sudoku_rust(g).expect("solvable");
        assert_eq!(solved[40], completed_valid()[40]);
        let mut row_sets = [0u16; 9];
        let mut col_sets = [0u16; 9];
        let mut box_sets = [0u16; 9];
        for r in 0..9 {
            for c in 0..9 {
                let v = solved[super::idx(r, c)];
                let bit = 1u16 << (v - 1);
                assert_eq!(row_sets[r] & bit, 0);
                row_sets[r] |= bit;
                assert_eq!(col_sets[c] & bit, 0);
                col_sets[c] |= bit;
                let b = (r / 3) * 3 + (c / 3);
                assert_eq!(box_sets[b] & bit, 0);
                box_sets[b] |= bit;
            }
        }
    }

    #[test]
    fn stress_maze_no_leak_pattern() {
        let adj = vec![vec![1], vec![0, 2], vec![1, 3], vec![2]];
        for _ in 0..10_000 {
            let _ = solve_maze_bfs_rust(&adj, 0, 3).unwrap();
        }
    }
}
