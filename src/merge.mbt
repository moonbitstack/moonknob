// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// Lays what a caller gave over what a function starts from, one setting at a
/// time, and keeps the names of those that disagreed for `settle`.
///
/// ```mbt check
/// test {
///   let merge = @moonknob.Merge::new(Extra)
///   let timeout = merge.pick("timeout", 30, Some(10))
///   assert_eq(timeout, 10)
///   assert_eq(merge.names().to_owned(), ["timeout"])
/// }
/// ```
struct Merge {
  wins : Wins
  names : Array[String]
}

///|
/// A merge that has recorded nothing yet and takes `wins` for every setting it
/// is handed from here on.
pub fn Merge::new(wins : Wins) -> Merge {
  { wins, names: [], }
}

///|
/// One setting. `given` is `None` when the caller did not give it, and then
/// `base` stands; a value equal to `base` stands without being a clash.
pub fn[V : Eq] Merge::pick(
  self : Merge,
  name : String,
  base : V,
  given : V?,
) -> V {
  match given {
    None => base
    Some(value) if value == base => base
    Some(value) => {
      self.names.push(name)
      match self.wins {
        Extra => value
        Base => base
      }
    }
  }
}

///|
/// Two maps as one: every key of both, in the order `base` then `extra` has
/// them, with `wins` deciding a key they both hold with different values.
pub fn[V : Eq] Merge::union(
  self : Merge,
  base : Map[String, V],
  extra : Map[String, V],
) -> Map[String, V] {
  let out = base.copy()
  for key, value in extra {
    match base.get(key) {
      None => out[key] = value
      Some(held) => out[key] = self.pick(key, held, Some(value))
    }
  }
  out
}

///|
/// The names of the settings that disagreed so far.
pub fn Merge::names(self : Merge) -> ArrayView[String] {
  self.names[:]
}

///|
/// `clash` applied to what was gathered: see [`OnClash::settle`].
pub fn[T] Merge::settle(
  self : Merge,
  clash : OnClash[T],
  base : T,
  merged : T,
  site : String,
) -> T {
  clash.settle(base, merged, self.names, site)
}
