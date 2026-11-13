// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
test "union answers 48 pairs of maps the way both reference implementations do" {
  for case in union_cases() {
    let later = @moonknob.Merge::new(Extra)
    let merged = later.union(Map(case.base), Map(case.extra))
    assert_eq(merged.to_array(), case.extra_wins)
    assert_eq(later.names().to_owned(), case.names)
    let earlier = @moonknob.Merge::new(Base)
    let kept = earlier.union(Map(case.base), Map(case.extra))
    assert_eq(kept.to_array(), case.base_wins)
    assert_eq(earlier.names().to_owned(), case.names)
  }
}
