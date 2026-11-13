// Read union cases as JSON on stdin and answer them with the JavaScript object
// semantics every browser and Node share: `{...base, ...extra}` for "the second
// side wins", and the first side filled only where the second has nothing for
// "the first side wins". Used as the second opinion of gen_union_vectors.py; the
// maps arrive and leave as ordered pairs, and the keys are never integer-like,
// so object key order is insertion order.
//
// Usage: node union_oracle.mjs < cases.json > answers.json

let text = "";
for await (const chunk of process.stdin) text += chunk;
const cases = JSON.parse(text);

const answers = cases.map(({ base, extra }) => {
  const fromBase = Object.fromEntries(base);
  const fromExtra = Object.fromEntries(extra);
  const names = [];
  for (const [key, value] of extra) {
    if (key in fromBase && fromBase[key] !== value) names.push(key);
  }
  const extraWins = Object.entries({ ...fromBase, ...fromExtra });
  const baseWins = { ...fromBase };
  for (const [key, value] of extra) if (!(key in baseWins)) baseWins[key] = value;
  return { extra_wins: extraWins, base_wins: Object.entries(baseWins), names };
});

process.stdout.write(JSON.stringify(answers));
