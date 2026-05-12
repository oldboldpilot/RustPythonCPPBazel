#include <array>
#include <cstdint>
#include <vector>

#include "mp_test.hpp"
#include "solvers.hpp"

namespace {

using multiparadigm::MazeError;
using multiparadigm::SudokuError;
using multiparadigm::solve_maze_bfs;
using multiparadigm::solve_sudoku;

std::array<std::uint8_t, 81> completed_valid() {
  return std::array<std::uint8_t, 81>{
      5, 3, 4, 6, 7, 8, 9, 1, 2, 6, 7, 2, 1, 9, 5, 3, 4, 8, 1, 9, 8, 3, 4, 2, 5, 6, 7, 8, 5, 9, 7, 6, 1, 4, 2, 3, 4, 2, 6, 8, 5, 3, 7, 9, 1, 7, 1, 3, 9, 2, 4, 8, 5, 6, 9, 6, 1, 5, 3, 7, 2, 8, 4, 2, 8, 7, 4, 1, 9, 6, 3, 5, 3, 4, 5, 2, 8, 6, 1, 7, 9,
  };
}

std::array<std::uint8_t, 81> one_blank_from_completed() {
  auto g = completed_valid();
  g[40] = 0;
  return g;
}

bool is_valid_sudoku_solution(const std::array<std::uint8_t, 81> &b) {
  for (std::size_t i = 0; i < 81; ++i) {
    const auto v = b[i];
    if (v < 1 || v > 9) {
      return false;
    }
  }
  for (int r = 0; r < 9; ++r) {
    std::array<bool, 9> seen{};
    for (int c = 0; c < 9; ++c) {
      const auto v = static_cast<std::size_t>(b[static_cast<std::size_t>(r * 9 + c)] - 1);
      if (seen[v]) {
        return false;
      }
      seen[v] = true;
    }
  }
  for (int c = 0; c < 9; ++c) {
    std::array<bool, 9> seen{};
    for (int r = 0; r < 9; ++r) {
      const auto v = static_cast<std::size_t>(b[static_cast<std::size_t>(r * 9 + c)] - 1);
      if (seen[v]) {
        return false;
      }
      seen[v] = true;
    }
  }
  for (int br = 0; br < 3; ++br) {
    for (int bc = 0; bc < 3; ++bc) {
      std::array<bool, 9> seen{};
      for (int dr = 0; dr < 3; ++dr) {
        for (int dc = 0; dc < 3; ++dc) {
          const int r = br * 3 + dr;
          const int c = bc * 3 + dc;
          const auto v = static_cast<std::size_t>(b[static_cast<std::size_t>(r * 9 + c)] - 1);
          if (seen[v]) {
            return false;
          }
          seen[v] = true;
        }
      }
    }
  }
  return true;
}

void test_sudoku_invalid_digit() {
  auto g = std::array<std::uint8_t, 81>{};
  g[0] = 11;
  const auto r = solve_sudoku(std::span<const std::uint8_t, 81>{g.data(), g.size()});
  MP_ASSERT_FALSE(r.has_value());
  MP_ASSERT_EQ(r.error(), SudokuError::InvalidInput);
}

void test_sudoku_duplicate_clue() {
  auto g = std::array<std::uint8_t, 81>{};
  g[0] = 1;
  g[1] = 1;
  const auto r = solve_sudoku(std::span<const std::uint8_t, 81>{g.data(), g.size()});
  MP_ASSERT_FALSE(r.has_value());
  MP_ASSERT_EQ(r.error(), SudokuError::InvalidInput);
}

void test_sudoku_accepts_completed_grid() {
  const auto g = completed_valid();
  const auto r = solve_sudoku(std::span<const std::uint8_t, 81>{g.data(), g.size()});
  MP_ASSERT_TRUE(r.has_value());
  MP_ASSERT_EQ(*r, g);
}

void test_sudoku_fills_single_blank() {
  const auto g = one_blank_from_completed();
  const auto r = solve_sudoku(std::span<const std::uint8_t, 81>{g.data(), g.size()});
  MP_ASSERT_TRUE(r.has_value());
  MP_ASSERT_TRUE(is_valid_sudoku_solution(*r));
  MP_ASSERT_EQ((*r)[40], completed_valid()[40]);
}

void test_maze_line_graph() {
  const std::vector<std::vector<int>> adj = {{1}, {0, 2}, {1, 3}, {2}};
  const auto r = solve_maze_bfs(adj, 0, 3);
  MP_ASSERT_TRUE(r.has_value());
  MP_ASSERT_EQ(*r, (std::vector<int>{0, 1, 2, 3}));
}

void test_maze_start_equals_goal() {
  const std::vector<std::vector<int>> adj = {{0}};
  const auto r = solve_maze_bfs(adj, 0, 0);
  MP_ASSERT_TRUE(r.has_value());
  MP_ASSERT_EQ(*r, (std::vector<int>{0}));
}

void test_maze_no_path() {
  const std::vector<std::vector<int>> adj = {{}, {}};
  const auto r = solve_maze_bfs(adj, 0, 1);
  MP_ASSERT_FALSE(r.has_value());
  MP_ASSERT_EQ(r.error(), MazeError::NoPath);
}

void test_maze_invalid_neighbor() {
  const std::vector<std::vector<int>> adj = {{2}, {0}};
  const auto r = solve_maze_bfs(adj, 0, 1);
  MP_ASSERT_FALSE(r.has_value());
  MP_ASSERT_EQ(r.error(), MazeError::InvalidGraph);
}

void test_stress_maze_many_iterations() {
  const std::vector<std::vector<int>> adj = {{1}, {0, 2}, {1, 3}, {2}};
  for (int i = 0; i < 20'000; ++i) {
    const auto r = solve_maze_bfs(adj, 0, 3);
    MP_ASSERT_TRUE(r.has_value());
    MP_ASSERT_EQ(r->size(), std::size_t{4});
  }
}

} // namespace

int main() {
  test_sudoku_invalid_digit();
  test_sudoku_duplicate_clue();
  test_sudoku_accepts_completed_grid();
  test_sudoku_fills_single_blank();
  test_maze_line_graph();
  test_maze_start_equals_goal();
  test_maze_no_path();
  test_maze_invalid_neighbor();
  test_stress_maze_many_iterations();
  return multiparadigm_mp_test::ctx().failures != 0 ? 1 : 0;
}
