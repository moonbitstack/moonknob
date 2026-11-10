// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
test "no names is no clash, whatever the policy" {
  let called = Ref(false)
  let policies : Array[@moonknob.OnClash[Int32]] = [
    Ignore,
    Warn(_ => called.val = true),
    Panic,
    Handle(_ => {
      called.val = true
      0
    }),
  ]
  for clash in policies {
    assert_eq(clash.settle(1, 2, [], "site"), 2)
  }
  assert_false(called.val)
}

///|
test "ignore takes the merged value" {
  let clash : @moonknob.OnClash[Int32] = Ignore
  assert_eq(clash.settle(1, 2, ["n"], "site"), 2)
}

///|
test "warn takes the merged value and says which settings" {
  let said : Array[String] = []
  let clash : @moonknob.OnClash[Int32] = Warn(line => said.push(line))
  assert_eq(clash.settle(1, 2, ["leeway", "expiry"], "jwt.verify"), 2)
  assert_eq(said, [
    "jwt.verify: leeway, expiry given twice with different values",
  ])
}

///|
test "panic on a clash" {
  let clash : @moonknob.OnClash[Int32] = Panic
  ignore(clash.settle(1, 2, ["n"], "site"))
}

///|
test "handle sees the clash and decides" {
  let seen : Array[@moonknob.Clash[Int32]] = []
  let clash : @moonknob.OnClash[Int32] = Handle(c => {
    seen.push(c)
    c.base + c.merged
  })
  assert_eq(clash.settle(1, 2, ["n"], "site"), 3)
  assert_eq(seen, [{ names: ["n"], base: 1, merged: 2, }])
}

///|
test "handle keeps its own copy of the names" {
  let names = ["n"]
  let kept : Array[Array[String]] = []
  let clash : @moonknob.OnClash[Int32] = Handle(c => {
    kept.push(c.names)
    c.merged
  })
  ignore(clash.settle(1, 2, names, "site"))
  names.push("m")
  assert_eq(kept, [["n"]])
}
