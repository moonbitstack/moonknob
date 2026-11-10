// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// The settings of an imaginary client, as a library in the family writes them:
/// a record with a preset, and flat arguments that override it.
struct Options {
  timeout : Int32
  retries : Int32
}

///|
impl Show for Options with fn output(self, logger) {
  logger.write_string("timeout=\{self.timeout} retries=\{self.retries}")
}

///|
let options : Options = { timeout: 30, retries: 3, }

///|
fn connect(
  options~ : Options = options,
  timeout? : Int32,
  retries? : Int32,
  wins~ : @moonknob.Wins = Extra,
  clash~ : @moonknob.OnClash[Options] = Ignore,
) -> Options {
  let merge = @moonknob.Merge::new(wins)
  let merged = {
    timeout: merge.pick("timeout", options.timeout, timeout),
    retries: merge.pick("retries", options.retries, retries),
  }
  merge.settle(clash, options, merged, "connect: options and arguments")
}

///|
/// The whole surface in one run.
///
///     moon run src/examples/tour
#coverage.skip
fn main {
  let mine = { timeout: 5, retries: 1, }
  // The argument is more specific than the record, so it wins.
  println(connect(options=mine, timeout=10))
  // Unless the record is the authority.
  println(connect(options=mine, timeout=10, wins=Base))
  // Told rather than silent: one line to whatever the program logs with.
  let warn = line => println("warn: " + line)
  println(connect(options=mine, timeout=10, clash=Warn(warn)))
  // Or decided by the caller, who sees both sides and the names.
  let keep_retries = (c : @moonknob.Clash[Options]) => {
    ..c.merged,
    retries: c.base.retries,
  }
  println(
    connect(options=mine, timeout=10, retries=9, clash=Handle(keep_retries)),
  )
}
