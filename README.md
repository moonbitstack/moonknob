# moonknob

Which of two settings wins, and what to do when they disagree. Every moonbitstack
library that takes a configuration record and flat arguments beside it resolves the
two through this module, so the rules below hold across the family.

## Configuration precedence

```
library preset  <  the record passed in  <  this call's argument of the same name
```

The more specific a setting, the later it applies: the order Axios, Terraform and
Spring Boot share. Two parameters change it, and both take a default chosen per
function, written in that function's documentation:

- `wins : Wins` is `Extra` (the argument wins) or `Base` (the record wins). `Base` is
  for a function whose starting point is an authority, such as the header a JWT
  signature is made under.
- `clash : OnClash[T]` says what happens when a setting is given twice with
  different values:

| Variant | Result | Says |
|:--:|:--:|:--:|
| `Ignore` | what `wins` chose | nothing |
| `Warn(f)` | what `wins` chose | one line to `f` |
| `Panic` | aborts | the message |
| `Handle(f)` | what `f` returns | `f` gets a `Clash[T]`: the names, the base, the merged value |

The same value given twice is not a clash, and `Warn` and `Handle` are not called
for it. The library never prints: `Warn` takes a function, so the line goes to
moonlog or wherever the program writes.

## Writing a function that takes a record

```moonbit
struct Options {
  timeout : Int32
  retries : Int32
}

let options : Options = { timeout: 30, retries: 3 }

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
```

`pick` takes one field: the name, the record's value, and the argument as the caller
gave it (`None` when it did not). `union` does the same for two maps, key by key,
with the keys of the first in their order and then the new ones of the second.
`settle` applies `clash` to what was gathered. A function that gathers names some
other way calls `OnClash::settle` with them.

## Calling one

```moonbit
let mine = { timeout: 5, retries: 1 }
let a = connect(options=mine, timeout=10)
let b = connect(options=mine, timeout=10, wins=Base)
let c = connect(options=mine, timeout=10, clash=Warn(line => println(line)))
let d = connect(
  options=mine,
  timeout=10,
  retries=9,
  clash=Handle(seen => { ..seen.merged, retries: seen.base.retries }),
)
```

`a` and `c` time out after 10; `b` keeps the record's 5, and `d` keeps the
record's retries while taking the argument's timeout. `c` printed
`connect: options and arguments: timeout given twice with different values`.

Run `moon run src/examples/tour` for the same in one go.

## Licence

Apache-2.0.
