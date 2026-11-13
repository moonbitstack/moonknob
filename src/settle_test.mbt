// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
test "one line, however many settings disagreed" {
  let said : Array[String] = []
  let clash : @moonknob.OnClash[Int32] = Warn(line => said.push(line))
  ignore(clash.settle(1, 2, ["depth", "retries", "timeout"], "open"))
  assert_eq(said.length(), 1)
  assert_eq(
    said[0],
    "open: depth, retries, timeout given twice with different values",
  )
}

///|
test "the site is used as given, colon and all" {
  let said : Array[String] = []
  let clash : @moonknob.OnClash[Int32] = Warn(line => said.push(line))
  ignore(clash.settle(1, 2, ["depth"], "jwt.sign: policy and arguments"))
  assert_eq(said, [
    "jwt.sign: policy and arguments: depth given twice with different values",
  ])
}

///|
test "handle may answer with neither side" {
  let clash : @moonknob.OnClash[Int32] = Handle(_ => 0)
  assert_eq(clash.settle(1, 2, ["depth"], "open"), 0)
}

///|
test "merge and the policy settle alike" {
  let keep_merged : @moonknob.OnClash[Int32] = Handle(c => c.merged)
  for wins in [@moonknob.Wins::Base, @moonknob.Wins::Extra] {
    let merge = @moonknob.Merge::new(wins)
    let merged = merge.pick("depth", 64, Some(8))
    let via_merge = merge.settle(keep_merged, 64, merged, "open")
    let via_policy = keep_merged.settle(
      64,
      merged,
      merge.names().to_owned(),
      "open",
    )
    assert_eq(via_merge, via_policy)
  }
}
