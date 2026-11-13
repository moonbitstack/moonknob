# moonknob

<p>
  <a href="https://moonbitstack.github.io/moonknob/"><b>Home</b></a> ·
  <a href="https://moonbitstack.github.io/moonknob/#use">Guide</a> ·
  <a href="https://moonbitstack.github.io/moonknob/api.html">API</a> ·
  <a href="https://mooncakes.io/docs/moonbitstack/moonknob">mooncakes</a>
</p>

Which of two settings wins, and what to do when they disagree. A function that
takes a settings record usually takes a few flat arguments beside it, one per
setting a caller changes often; this is the one place that decides which of the
two wins and what is said about it.

<!-- nocheck -->

```text
library preset   <   the record passed in   <   this call's argument
```

The more specific a setting, the later it applies. Two parameters change that,
and each function documents the default it chose:

- `wins` is `Extra` (the argument wins) or `Base` (the record wins). `Base` is for
  a function whose starting point is an authority, such as the header a signature
  is about to be made under.
- `clash` says what happens when a setting is given twice with different values.

| `clash` | what the call answers | what it says |
|:--|:--|:--|
| `Ignore` | what `wins` chose | nothing |
| `Warn(f)` | what `wins` chose | one line to `f` |
| `Panic` | nothing: the program stops | the message |
| `Handle(f)` | what `f` returns | `f` gets the names, the base and the merge |

The same value given twice is not a clash, and nothing is reported for it. With no
clash at all, `settle` answers `merged` whatever the policy is.

## A function that takes a record

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

`pick` takes one setting: its name, the record's value, and what the caller gave,
which is `None` when it gave nothing. `settle` applies the policy to the names
that were gathered; `site` names the call and its two sources in the warning and
in the abort.

## Calling it

```moonbit
let mine = { timeout: 5, retries: 1, }
let by_default = connect(options=mine, timeout=10)
let by_record = connect(options=mine, timeout=10, wins=Base)

assert_eq(by_default.timeout, 10)
assert_eq(by_record.timeout, 5)
```

Being told instead of guessing:

```moonbit
let said : Array[String] = []
let lines = connect(options=mine, timeout=10, clash=Warn(line => said.push(line)))
assert_eq(lines.timeout, 10)
assert_eq(said, ["connect: options and arguments: timeout given twice with different values"])
```

`Handle` gets a `Clash` — the names, the base and the merge — and answers with
what the program should use:

```moonbit
let keep_retries : @moonknob.OnClash[Options] = Handle(sides => sides.base)
assert_eq(connect(options=mine, timeout=10, clash=keep_retries).timeout, 5)
```

The library never prints: `Warn` takes a function, so the line goes wherever the
program writes.

## Two maps

```moonbit
let merge = @moonknob.Merge::new(Extra)
let heads = merge.union({ "alg": "none", "typ": "JWT" }, { "typ": "JOSE", "kid": "k1" })
assert_eq(heads.to_array(), [("alg", "none"), ("typ", "JOSE"), ("kid", "k1")])
```

Key by key under the same two knobs, with the keys of the first side in their
order and then the new ones of the second.

## Licence

Apache-2.0.
