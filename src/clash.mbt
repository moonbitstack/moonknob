// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// Settings given twice with different values, as `Handle` receives them.
#derive(Eq, Debug)
pub(all) struct Clash[T] {
  /// The settings that disagreed, in the order the function takes them.
  names : Array[String]
  /// What the function started from.
  base : T
  /// The two laid together the way `wins` says.
  merged : T
}

///|
pub extend Clash with Eq::{equal, not_equal}

///|
pub extend Clash with Debug::{to_repr}

///|
/// What to do when a setting is given twice with different values.
///
/// The same value given twice is not a clash: there is only one answer, and
/// nothing is reported.
pub(all) enum OnClash[T] {
  /// Take what `wins` says and say nothing. What most libraries do.
  Ignore
  /// Take what `wins` says and pass one line about it to the function, a
  /// logger's `warn` for instance. The library itself prints nothing.
  Warn((String) -> Unit)
  /// Abort, for where two answers are a mistake in the program rather than a
  /// choice about configuration.
  Panic
  /// Pass the clash to the function and take what it returns.
  Handle((Clash[T]) -> T)
}

///|
/// What a function ends up with, given what it started from, the two laid
/// together, and the settings that disagreed. With no names there was no
/// clash, and `merged` comes back whatever `self` is.
///
/// `site` is the call and its two sources, for the warning and the abort:
/// `"jwt.verify: policy and arguments"`.
pub fn[T] OnClash::settle(
  self : OnClash[T],
  base : T,
  merged : T,
  names : Array[String],
  site : String,
) -> T {
  if names.is_empty() {
    return merged
  }
  match self {
    Ignore => merged
    Warn(warn) => {
      warn(message(site, names))
      merged
    }
    Panic => abort(message(site, names))
    Handle(decide) => decide({ names: names.copy(), base, merged, })
  }
}

///|
fn message(site : String, names : Array[String]) -> String {
  "\{site}: \{names.join(", ")} given twice with different values"
}
