// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
#derive(Eq, Debug)
priv struct Limits {
  depth : Int32
  name : String?
}

///|
let limits : Limits = { depth: 64, name: None, }

///|
fn resolve(
  base : Limits,
  depth : Int32?,
  name : String?,
  wins : @moonknob.Wins,
  clash : @moonknob.OnClash[Limits],
) -> Limits {
  let merge = @moonknob.Merge::new(wins)
  let merged = {
    depth: merge.pick("depth", base.depth, depth),
    name: merge.pick("name", base.name, name.map(value => Some(value))),
  }
  merge.settle(clash, base, merged, "resolve: limits and arguments")
}

///|
test "a setting not given leaves the base" {
  let merge = @moonknob.Merge::new(Extra)
  assert_eq(merge.pick("depth", 64, None), 64)
  assert_eq(merge.names().length(), 0)
}

///|
test "the same value given twice is not a clash" {
  let merge = @moonknob.Merge::new(Extra)
  assert_eq(merge.pick("depth", 64, Some(64)), 64)
  assert_eq(merge.names().length(), 0)
}

///|
test "extra wins a clash" {
  let merge = @moonknob.Merge::new(Extra)
  assert_eq(merge.pick("depth", 64, Some(8)), 8)
  assert_eq(merge.names().to_owned(), ["depth"])
}

///|
test "base wins a clash when asked" {
  let merge = @moonknob.Merge::new(Base)
  assert_eq(merge.pick("depth", 64, Some(8)), 64)
  assert_eq(merge.names().to_owned(), ["depth"])
}

///|
test "a record and its flat mirror, both ways" {
  assert_eq(resolve(limits, Some(8), None, Extra, Ignore), {
    depth: 8,
    name: None,
  })
  assert_eq(resolve(limits, Some(8), Some("x"), Base, Ignore), limits)
  assert_eq(resolve(limits, None, None, Base, Panic), limits)
}

///|
test "the record, its update and the flat mirror agree" {
  let record = resolve({ depth: 8, name: None, }, None, None, Extra, Panic)
  let update = resolve({ ..limits, depth: 8, }, None, None, Extra, Panic)
  let flat = resolve(limits, Some(8), None, Extra, Ignore)
  assert_eq(record, update)
  assert_eq(record, flat)
}

///|
test "warn names the settings in the order the function takes them" {
  let said : Array[String] = []
  ignore(resolve(limits, Some(8), Some("x"), Extra, Warn(l => said.push(l))))
  assert_eq(said, [
    "resolve: limits and arguments: depth, name given twice with different values",
  ])
}

///|
test "panic when a record and an argument disagree" {
  ignore(resolve(limits, Some(8), None, Extra, Panic))
}

///|
test "handle gets the base and the merged record" {
  let got = resolve(limits, Some(8), None, Extra, Handle(c => c.base))
  assert_eq(got, limits)
}

///|
test "union keeps the order of base, then the new keys of extra" {
  let merge = @moonknob.Merge::new(Extra)
  let out = merge.union({ "alg": 1, "typ": 2 }, { "kid": 3, "typ": 4 })
  assert_eq(out.to_array(), [("alg", 1), ("typ", 4), ("kid", 3)])
  assert_eq(merge.names().to_owned(), ["typ"])
}

///|
test "union with base winning keeps base's values" {
  let merge = @moonknob.Merge::new(Base)
  let out = merge.union({ "alg": 1, "typ": 2 }, { "typ": 4, "kid": 3 })
  assert_eq(out.to_array(), [("alg", 1), ("typ", 2), ("kid", 3)])
  assert_eq(merge.names().to_owned(), ["typ"])
}

///|
test "union does not count a key both hold with the same value" {
  let merge = @moonknob.Merge::new(Base)
  let out = merge.union({ "typ": 2 }, { "typ": 2 })
  assert_eq(out.to_array(), [("typ", 2)])
  assert_eq(merge.names().length(), 0)
}
