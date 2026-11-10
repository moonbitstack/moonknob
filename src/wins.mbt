// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// Which side wins when a setting is given twice: once in what a function
/// starts from, once in what the caller lays over it.
///
/// A function that takes a configuration record usually takes flat arguments
/// beside it, one per setting a caller changes often, and the more specific of
/// the two is applied last: library preset, then the record, then this call's
/// arguments. That is `Extra`. `Base` turns it round for a function whose
/// starting point is an authority rather than a default, such as the header a
/// signature is about to be made under.
#derive(Eq, Debug)
pub(all) enum Wins {
  /// What the function starts from: the record, or what it computes itself.
  Base
  /// What is laid over it: this call's arguments, or the caller's `extra`.
  Extra
}

///|
pub extend Wins with Eq::{equal, not_equal}

///|
pub extend Wins with Debug::{to_repr}
