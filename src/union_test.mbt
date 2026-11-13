// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
test "a key only one side holds is taken as it stands" {
  let merge = @moonknob.Merge::new(Extra)
  let out = merge.union({ "alg": "none" }, { "kid": "k1" })
  assert_eq(out.to_array(), [("alg", "none"), ("kid", "k1")])
  assert_eq(merge.names().length(), 0)
}

///|
test "two empty maps make an empty map" {
  let merge = @moonknob.Merge::new(Extra)
  let base : Map[String, Int32] = Map([])
  let out = merge.union(base, Map([]))
  assert_eq(out.length(), 0)
  assert_eq(merge.names().length(), 0)
}

///|
test "a union leaves the maps it was given alone" {
  let merge = @moonknob.Merge::new(Extra)
  let base = { "typ": "JWT" }
  let extra = { "typ": "JOSE", "kid": "k1" }
  ignore(merge.union(base, extra))
  assert_eq(base.to_array(), [("typ", "JWT")])
  assert_eq(extra.to_array(), [("typ", "JOSE"), ("kid", "k1")])
}

///|
test "two unions on one merge name what disagreed in the order they were seen" {
  let merge = @moonknob.Merge::new(Extra)
  ignore(merge.union({ "a": 1 }, { "a": 2 }))
  ignore(merge.union({ "b": 1, "c": 1 }, { "c": 2, "b": 2 }))
  assert_eq(merge.names().to_owned(), ["a", "c", "b"])
}
