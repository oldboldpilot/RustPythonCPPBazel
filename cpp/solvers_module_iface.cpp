// Minimal C++23 module TU built by `bazel build //cpp:solvers_module_iface`.
// Solver implementations live in `solvers.hpp` for the nanobind extension; this
// target exists so the repo still exercises C++ modules under Bazel.
module;

export module multiparadigm.solvers_meta;

export namespace multiparadigm::meta {
[[nodiscard]] constexpr const char *toolchain_note() noexcept {
  return "cpp_modules_enabled";
}
} // namespace multiparadigm::meta
