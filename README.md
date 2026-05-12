# RustPythonCPPBazel

Multiparadigm workspace: **Bazel**, **C++23** (nanobind extension), **Rust** (PyO3), **Python**, and **SWI-Prolog** solvers (Sudoku + maze).

Further documentation is indexed in [`docs/INDEX.md`](docs/INDEX.md).

## Build and test

```bash
bazel build //...
bazel test //:all_tests //cpp:cppm_demo_test
```

## Demo

```bash
bazel run //python:demo
```
