#include <array>
#include <expected>
#include <nanobind/nanobind.h>
#include <nanobind/stl/tuple.h>
#include <nanobind/stl/vector.h>
#include <span>
#include <stdexcept>
#include <string_view>
#include "solvers.hpp"

namespace nb = nanobind;

namespace {

template <class T, class E, class OnOk, class OnErr>
[[nodiscard]] auto match_expected(std::expected<T, E> &&ex, OnOk &&on_ok, OnErr &&on_err) {
  if (ex) {
    return std::forward<OnOk>(on_ok)(*ex);
  }
  return std::forward<OnErr>(on_err)(ex.error());
}

[[nodiscard]] nb::tuple sudoku_result_to_tuple(
    std::expected<std::array<std::uint8_t, 81>, multiparadigm::SudokuError> &&result) {
  return match_expected(
      std::move(result),
      [](const std::array<std::uint8_t, 81> &solved) {
        nb::list out{};
        for (const auto v : solved) {
          out.append(static_cast<int>(v));
        }
        return nb::make_tuple(std::move(out), nb::none());
      },
      [](multiparadigm::SudokuError err) {
        const auto sv = multiparadigm::to_string(err);
        return nb::make_tuple(nb::none(), nb::str(sv.data(), sv.size()));
      });
}

[[nodiscard]] nb::tuple maze_result_to_tuple(std::expected<std::vector<int>, multiparadigm::MazeError> &&result) {
  return match_expected(
      std::move(result),
      [](const std::vector<int> &path) {
        nb::list out{};
        for (const int v : path) {
          out.append(v);
        }
        return nb::make_tuple(std::move(out), nb::none());
      },
      [](multiparadigm::MazeError err) {
        const auto sv = multiparadigm::to_string(err);
        return nb::make_tuple(nb::none(), nb::str(sv.data(), sv.size()));
      });
}

} // namespace

NB_MODULE(multiparadigm_cpp, m) {
  m.doc() = "C++23 Sudoku + maze solvers (std::expected, railway-style binding).";

  m.def(
      "solve_sudoku",
      [](nb::object grid_obj) {
        const auto grid = nb::cast<std::vector<int>>(grid_obj);
        return sudoku_result_to_tuple(multiparadigm::solve_sudoku_from_int_clues(
            std::span<const int>{grid.data(), grid.size()}));
      },
      nb::arg("grid"));

  m.def(
      "solve_maze_bfs",
      [](const std::vector<std::vector<int>> &adj, int start, int goal) {
        return maze_result_to_tuple(
            multiparadigm::solve_maze_bfs(std::span<const std::vector<int>>{adj.data(), adj.size()}, start, goal));
      },
      nb::arg("adj"), nb::arg("start"), nb::arg("goal"));
}
