#pragma once

// C++23 solver core: std::expected + span + ranges, composed railway-style
// (validate → and_then → solve). Kept as a header for nanobind / Bazel cc_*.

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <queue>
#include <ranges>
#include <span>
#include <string_view>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

namespace multiparadigm {

enum class SudokuError : std::uint8_t { InvalidInput, Unsolvable };

[[nodiscard]] constexpr inline std::string_view to_string(SudokuError e) noexcept {
  switch (e) {
  case SudokuError::InvalidInput:
    return "invalid_input";
  case SudokuError::Unsolvable:
    return "unsolvable";
  }
  return "unknown";
}

enum class MazeError : std::uint8_t { InvalidGraph, NoPath };

[[nodiscard]] constexpr inline std::string_view to_string(MazeError e) noexcept {
  switch (e) {
  case MazeError::InvalidGraph:
    return "invalid_graph";
  case MazeError::NoPath:
    return "no_path";
  }
  return "unknown";
}

namespace detail {

[[nodiscard]] constexpr bool in_range_cell(std::uint8_t v) noexcept {
  return v <= 9;
}

[[nodiscard]] constexpr std::size_t idx(int r, int c) noexcept {
  return static_cast<std::size_t>(r * 9 + c);
}

[[nodiscard]] inline bool valid_placement(std::span<const std::uint8_t, 81> b, int r,
                                          int c, std::uint8_t n) noexcept {
  for (int i = 0; i < 9; ++i) {
    if (b[idx(r, i)] == n && static_cast<int>(i) != c) {
      return false;
    }
    if (b[idx(i, c)] == n && i != r) {
      return false;
    }
  }
  const int br = r / 3 * 3;
  const int bc = c / 3 * 3;
  for (int dr = 0; dr < 3; ++dr) {
    for (int dc = 0; dc < 3; ++dc) {
      const int rr = br + dr;
      const int cc = bc + dc;
      if (rr == r && cc == c) {
        continue;
      }
      if (b[idx(rr, cc)] == n) {
        return false;
      }
    }
  }
  return true;
}

[[nodiscard]] inline bool solve_backtrack(std::array<std::uint8_t, 81> &b, int pos) noexcept {
  if (pos == 81) {
    return true;
  }
  const int r = pos / 9;
  const int c = pos % 9;
  if (b[idx(r, c)] != 0) {
    return solve_backtrack(b, pos + 1);
  }
  for (std::uint8_t n = 1; n <= 9; ++n) {
    if (!valid_placement(b, r, c, n)) {
      continue;
    }
    b[idx(r, c)] = n;
    if (solve_backtrack(b, pos + 1)) {
      return true;
    }
    b[idx(r, c)] = 0;
  }
  return false;
}

[[nodiscard]] inline bool basic_consistent(std::span<const std::uint8_t, 81> b) noexcept {
  for (int r = 0; r < 9; ++r) {
    for (int c = 0; c < 9; ++c) {
      const auto v = b[idx(r, c)];
      if (v == 0) {
        continue;
      }
      for (int i = 0; i < 9; ++i) {
        if (i != c && b[idx(r, i)] == v) {
          return false;
        }
        if (i != r && b[idx(i, c)] == v) {
          return false;
        }
      }
      const int br = r / 3 * 3;
      const int bc = c / 3 * 3;
      for (int dr = 0; dr < 3; ++dr) {
        for (int dc = 0; dc < 3; ++dc) {
          const int rr = br + dr;
          const int cc = bc + dc;
          if (rr == r && cc == c) {
            continue;
          }
          if (b[idx(rr, cc)] == v) {
            return false;
          }
        }
      }
    }
  }
  return true;
}

[[nodiscard]] inline std::expected<std::array<std::uint8_t, 81>, SudokuError>
validated_sudoku_board(std::span<const std::uint8_t, 81> grid) noexcept {
  if (!std::ranges::all_of(grid, in_range_cell)) {
    return std::unexpected(SudokuError::InvalidInput);
  }
  if (!basic_consistent(grid)) {
    return std::unexpected(SudokuError::InvalidInput);
  }
  auto board = std::array<std::uint8_t, 81>{};
  std::ranges::copy(grid, board.begin());
  return board;
}

[[nodiscard]] inline std::expected<std::array<std::uint8_t, 81>, SudokuError>
run_sudoku_backtrack(std::array<std::uint8_t, 81> board) noexcept {
  if (!detail::solve_backtrack(board, 0)) {
    return std::unexpected(SudokuError::Unsolvable);
  }
  return board;
}

[[nodiscard]] inline std::expected<void, MazeError>
validate_maze_graph(std::span<const std::vector<int>> adj, int start, int goal) noexcept {
  const int n = static_cast<int>(adj.size());
  if (n == 0 || start < 0 || goal < 0 || start >= n || goal >= n) {
    return std::unexpected(MazeError::InvalidGraph);
  }
  for (int i = 0; i < n; ++i) {
    for (int nb : adj[static_cast<std::size_t>(i)]) {
      if (nb < 0 || nb >= n) {
        return std::unexpected(MazeError::InvalidGraph);
      }
    }
  }
  return {};
}

[[nodiscard]] inline std::expected<std::vector<int>, MazeError>
bfs_shortest_path(std::span<const std::vector<int>> adj, int start, int goal) noexcept {
  if (start == goal) {
    return std::vector<int>{start};
  }
  std::queue<int> q;
  std::unordered_map<int, int> parent;
  std::unordered_set<int> seen;
  q.push(start);
  seen.insert(start);
  while (!q.empty()) {
    const int u = q.front();
    q.pop();
    for (int v : adj[static_cast<std::size_t>(u)]) {
      if (seen.contains(v)) {
        continue;
      }
      seen.insert(v);
      parent.emplace(v, u);
      if (v == goal) {
        std::vector<int> path;
        int cur = goal;
        path.push_back(cur);
        while (cur != start) {
          const auto it = parent.find(cur);
          if (it == parent.end()) {
            return std::unexpected(MazeError::NoPath);
          }
          cur = it->second;
          path.push_back(cur);
        }
        std::ranges::reverse(path);
        return path;
      }
      q.push(v);
    }
  }
  return std::unexpected(MazeError::NoPath);
}

} // namespace detail

[[nodiscard]] inline std::expected<std::array<std::uint8_t, 81>, SudokuError>
solve_sudoku(std::span<const std::uint8_t, 81> grid) noexcept {
  return detail::validated_sudoku_board(grid).and_then(detail::run_sudoku_backtrack);
}

[[nodiscard]] inline std::expected<std::array<std::uint8_t, 81>, SudokuError>
sudoku_cells_from_int_clues(std::span<const int> clues) noexcept {
  if (clues.size() != 81) {
    return std::unexpected(SudokuError::InvalidInput);
  }
  std::array<std::uint8_t, 81> cells{};
  for (std::size_t i = 0; i < 81; ++i) {
    const int v = clues[i];
    if (v < 0 || v > 9) {
      return std::unexpected(SudokuError::InvalidInput);
    }
    cells[i] = static_cast<std::uint8_t>(v);
  }
  return cells;
}

[[nodiscard]] inline std::expected<std::array<std::uint8_t, 81>, SudokuError>
solve_sudoku_from_int_clues(std::span<const int> clues) noexcept {
  return sudoku_cells_from_int_clues(clues).and_then([](std::array<std::uint8_t, 81> cells) noexcept {
    return solve_sudoku(std::span<const std::uint8_t, 81>{cells.data(), cells.size()});
  });
}

[[nodiscard]] inline std::expected<std::vector<int>, MazeError>
solve_maze_bfs(std::span<const std::vector<int>> adj, int start, int goal) noexcept {
  return detail::validate_maze_graph(adj, start, goal).and_then([&]() -> std::expected<std::vector<int>, MazeError> {
    return detail::bfs_shortest_path(adj, start, goal);
  });
}

} // namespace multiparadigm
