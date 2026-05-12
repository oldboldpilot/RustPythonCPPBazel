# RustPythonCPPBazel

Multiparadigm workspace: **Bazel**, **C++23** (nanobind extension), **Rust** (PyO3), **Python**, and **SWI-Prolog** solvers (Sudoku + maze).

## Policies and C++ conventions

- **Commit / push / authorship:** see [`config/update_policy.txt`](config/update_policy.txt).
- **C++ direction (modules, `import std`, style):** see [`config/cpp_details.txt`](config/cpp_details.txt).

## Build and test

```bash
bazel build //...
bazel test //:all_tests //cpp:cppm_demo_test
```

## Demo

```bash
bazel run //python:demo
```
