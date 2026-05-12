# RustPythonCPPBazel

Multiparadigm workspace: **Bazel**, **C++23** (nanobind extension), **Rust** (PyO3), **Python**, and **SWI-Prolog** solvers (Sudoku + maze).

## Build and test

```bash
bazel build //...
bazel test //:all_tests //cpp:cppm_demo_test
```

## Demo

```bash
bazel run //python:demo
```
