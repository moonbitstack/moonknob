// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
test "the two sides are told apart" {
  assert_eq(@moonknob.Wins::Base, @moonknob.Wins::Base)
  assert_eq(@moonknob.Wins::Extra, @moonknob.Wins::Extra)
  assert_true(@moonknob.Wins::Base != @moonknob.Wins::Extra)
}

///|
test "a side reads back by its name" {
  debug_inspect(@moonknob.Wins::Base, content="Base")
  debug_inspect(@moonknob.Wins::Extra, content="Extra")
}
