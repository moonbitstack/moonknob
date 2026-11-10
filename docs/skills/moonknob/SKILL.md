---
name: moonknob
description: Resolve a configuration record against per-call arguments the way every moonbitstack library does, with `wins` choosing the direction and `clash` choosing what happens when a setting is given twice with different values. Use when writing a function that takes a settings record plus overriding arguments, or when calling a moonbitstack library's `wins` and `clash` parameters.
---

# moonknob

Add it with `moon add moonbitstack/moonknob` and import `"moonbitstack/moonknob"`.
Most programs never import it themselves: the libraries that use it take `wins=`
and `clash=` arguments whose constructors resolve without a package prefix.

## The order

Library preset, then the record passed in, then the call's argument of the same
name. `wins=Base` makes the record beat the argument; `wins=Extra` is the usual
order.

## Writing a function that takes a record

```moonbit
struct Limits {
  depth : Int32
  name : String?
}

let limits : Limits = { depth: 64, name: None }

fn parse(
  limits~ : Limits = limits,
  depth? : Int32,
  name? : String,
  wins~ : @moonknob.Wins = Extra,
  clash~ : @moonknob.OnClash[Limits] = Ignore,
) -> Limits {
  let merge = @moonknob.Merge::new(wins)
  let merged = {
    depth: merge.pick("depth", limits.depth, depth),
    name: merge.pick("name", limits.name, name.map(value => Some(value))),
  }
  merge.settle(clash, limits, merged, "parse: limits and arguments")
}
```

For two maps, `merge.union(base, extra)` merges key by key and records the keys
both hold with different values.

## Being told about a clash

```moonbit
let lines : Array[String] = []
let got = parse(limits={ depth: 8, name: None }, depth=16, clash=Warn(line => lines.push(line)))
```

`Warn` passes one line to the function and keeps what `wins` chose; `Handle`
receives a `Clash[T]` with `names`, `base` and `merged` and returns the value to
use; `Panic` aborts.

## Rules that catch people out

- The same value given twice is not a clash: nothing is reported.
- `Panic` aborts rather than raising. A clash it reports is a mistake in the
  program, not in input data; a configuration loader merging files raises its
  own error instead.
- Each function documents its own defaults for `wins` and `clash`; they are not
  the same everywhere. A JWT signer, for instance, defaults to `wins=Base` and
  `clash=Panic` so that `extra` cannot rewrite the algorithm in the header.
