// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// What the page's plate shows for one turn of the dial, as a JSON object:
/// `value` is what the function ends up with, `origin` says which side it came
/// from, and `line` is the warning when there is one.
///
/// `wins` is 0 for `Base` and 1 for `Extra`; `clash` is 0 for `Ignore`, 1 for
/// `Warn`, 2 for `Panic` and 3 for `Handle`, which answers with the record.
/// `Panic` aborts, so `resolve` never returns an answer for it: the page reads
/// the abort's message from the exception instead.
pub fn resolve(
  base : Int32,
  given : Int32,
  wins : Int32,
  clash : Int32,
) -> String {
  let merge = @moonknob.Merge::new(if wins == 0 { Base } else { Extra })
  let merged = merge.pick("timeout", base, Some(given))
  let names = merge.names().to_owned()
  let said : Array[String] = []
  let policy : @moonknob.OnClash[Int32] = match clash {
    0 => Ignore
    1 => Warn(line => said.push(line))
    3 => Handle(sides => sides.base)
    _ => Panic
  }
  let value = merge.settle(
    policy, base, merged, "connect: options and arguments",
  )
  let origin = if names.is_empty() {
    "both sides agree"
  } else {
    match clash {
      3 => "the caller"
      _ => if wins == 0 { "the record" } else { "this call" }
    }
  }
  let json : Json = {
    "value": Json(value),
    "origin": Json(origin),
    "names": Json(names.iter().map(name => Json(name)).collect()),
    "line": if said.is_empty() {
      Json::null()
    } else {
      Json(said[0])
    },
  }
  json.stringify()
}
