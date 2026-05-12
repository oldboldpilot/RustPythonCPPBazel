#pragma once

// Minimal C++ test harness — standard library only, no external test deps.

#include <cstdio>

namespace multiparadigm_mp_test {

struct Ctx {
  int failures = 0;

  void fail(const char *file, int line, const char *what) {
    std::fprintf(stderr, "%s:%d: %s\n", file, line, what);
    ++failures;
  }

  bool check(bool ok, const char *file, int line, const char *expr) {
    if (!ok) {
      fail(file, line, expr);
    }
    return ok;
  }
};

inline Ctx &ctx() {
  static Ctx c;
  return c;
}

template <class A, class B>
void assert_eq(A &&a, B &&b, const char *file, int line, const char *expr_a, const char *expr_b) {
  if (!(a == b)) {
    std::fprintf(stderr, "%s:%d: ASSERT_EQ failed (%s vs %s)\n", file, line, expr_a, expr_b);
    ++ctx().failures;
  }
}

} // namespace multiparadigm_mp_test

#define MP_ASSERT_TRUE(c) (void)::multiparadigm_mp_test::ctx().check(!!(c), __FILE__, __LINE__, "ASSERT_TRUE(" #c ")")

#define MP_ASSERT_FALSE(c) (void)::multiparadigm_mp_test::ctx().check(!(c), __FILE__, __LINE__, "ASSERT_FALSE(" #c ")")

#define MP_ASSERT_EQ(a, b) \
  ::multiparadigm_mp_test::assert_eq((a), (b), __FILE__, __LINE__, #a, #b)

#define MP_RETURN_IF_TESTS_FAILED() \
  do { \
    if (::multiparadigm_mp_test::ctx().failures != 0) { \
      return 1; \
    } \
  } while (0)
