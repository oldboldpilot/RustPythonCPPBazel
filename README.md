# RustPythonCPPBazel

Multiparadigm workspace: **Bazel**, **C++23** (nanobind extension), **Rust** (PyO3), **Python**, and **SWI-Prolog** solvers (Sudoku + maze).

## Policies (local only)

Optional notes live under `config/` as **`update_policy.txt`** and **`cpp_details.txt`**. Those names are listed in **`config/.gitignore`** and are **not** tracked by Git—keep your own copies locally if you use them.

## Build and test

```bash
bazel build //...
bazel test //:all_tests //cpp:cppm_demo_test
```

## Demo

```bash
bazel run //python:demo
```
