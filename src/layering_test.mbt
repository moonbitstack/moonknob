// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
#derive(Eq, Debug)
priv struct Budget {
  depth : Int32
  retries : Int32
}

///|
let preset : Budget = { depth: 64, retries: 3, }

///|
fn lay_out(
  record : Budget,
  depth : Int32?,
  retries : Int32?,
  wins : @moonknob.Wins,
  clash : @moonknob.OnClash[Budget],
) -> Budget {
  let merge = @moonknob.Merge::new(wins)
  let merged = {
    depth: merge.pick("depth", record.depth, depth),
    retries: merge.pick("retries", record.retries, retries),
  }
  merge.settle(clash, record, merged, "lay_out: record and arguments")
}

///|
test "the preset is the floor, the record beats it, the argument beats both" {
  let record = { ..preset, retries: 9, }
  assert_eq(lay_out(record, None, None, Extra, Ignore), {
    depth: 64,
    retries: 9,
  })
  assert_eq(lay_out(record, Some(8), None, Extra, Ignore), {
    depth: 8,
    retries: 9,
  })
  assert_eq(lay_out(record, Some(8), Some(5), Extra, Ignore), {
    depth: 8,
    retries: 5,
  })
}

///|
test "a record that is the authority cannot be moved by the arguments" {
  let record = { ..preset, depth: 8, }
  let said : Array[String] = []
  let got = lay_out(record, Some(16), Some(5), Base, Warn(l => said.push(l)))
  assert_eq(got, record)
  assert_eq(said, [
    "lay_out: record and arguments: depth, retries given twice with different values",
  ])
}

///|
test "an argument that repeats the record is not a clash, either way" {
  for wins in [@moonknob.Wins::Base, @moonknob.Wins::Extra] {
    let record = { ..preset, depth: 8, }
    assert_eq(lay_out(record, Some(8), None, wins, Panic), record)
  }
}
