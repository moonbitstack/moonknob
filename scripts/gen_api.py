"""Write docs/api.html from the package's interface file and the `///` notes in
its sources, so the reference follows the code rather than a second copy of it.

Every public item in `src/pkg.generated.mbti` has to come out on the page: the
script collects the anchors the interface file requires, renders the page from
that same list, and refuses to write it if one is missing. A function that takes
type parameters is an item like any other — the interface file spells it
`pub fn[V : Eq] Merge::pick`, and an entry that only looked for `pub fn name`
would drop it without a word.

Usage: python scripts/gen_api.py
"""

import html
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MBTI = ROOT / "src" / "pkg.generated.mbti"
TEMPLATE = ROOT / "docs" / "api.template.html"
OUT = ROOT / "docs" / "api.html"

DECL = re.compile(r"^pub fn\s*(?:\[[^\]]*\]\s*)?([A-Za-z_]\w*)(?:::(\w+))?\s*\(")
TYPE_DECL = re.compile(r"^(pub(?:\([a-z]+\))?\s+)?(struct|enum)\s+([A-Z]\w*)")
NAME = re.compile(r"^([A-Za-z_]\w*)")
DERIVED = ("equal", "not_equal", "compare", "hash", "hash_combine", "to_string", "output", "to_repr")


def read(path):
    return path.read_text(encoding="utf-8").splitlines()


def sources():
    """Every source file but the tests, in name order, so a run is repeatable."""
    return [
        read(path)
        for path in sorted((ROOT / "src").glob("*.mbt"))
        if not path.name.endswith(("_test.mbt", "_wbtest.mbt"))
    ]


def named(line):
    """`pub fn[T] OnClash::settle(` reads as `OnClash::settle`; `pub fn f` as `f`."""
    found = DECL.match(line)
    return f"{found.group(1)}::{found.group(2)}" if found.group(2) else found.group(1)


def take_signature(lines, start):
    """The declaration from `pub fn` to its body: the parameters as the source
    names them, which the interface file does not keep."""
    taken = []
    for line in lines[start:]:
        taken.append(line.rstrip())
        text = "\n".join(taken)
        if text.count("(") == text.count(")") and text.rstrip().endswith("{"):
            return text.rstrip()[:-1].rstrip()
    return "\n".join(taken)


def notes():
    """The `///` notes by item, and the signature of every `pub fn` as written.

    A note belongs to the declaration under it. Inside a type it belongs to a
    variant or a field, which the interface file names but does not explain. `#`
    attributes sit between the note and the declaration and are stepped over.
    """
    prose, signature = {}, {}
    for lines in sources():
        pending, owner = [], None
        index = 0
        while index < len(lines):
            line = lines[index]
            stripped = line.strip()
            if stripped == "///|":
                pending = []
            elif stripped.startswith("///"):
                # Keep the indentation of an example: four spaces after the
                # marker are what makes it a code block rather than a paragraph.
                body = line[line.index("///") + 3 :]
                pending.append(body[1:] if body.startswith(" ") else body)
                index += 1
                continue
            elif stripped.startswith("#"):
                pass
            elif owner and line.startswith("}"):
                owner = None
            elif owner:
                member = NAME.match(line.strip())
                if member and pending:
                    prose[f"{owner}.{member.group(1)}"] = "\n".join(pending)
            else:
                found = TYPE_DECL.match(line)
                if found:
                    owner = found.group(3)
                    if pending:
                        prose[owner] = "\n".join(pending)
                elif DECL.match(line):
                    if pending:
                        prose[named(line)] = "\n".join(pending)
                    signature[named(line)] = take_signature(lines, index)
                index += 1
                pending = []
                continue
            pending = []
            index += 1
    return prose, signature


def interface():
    """What the interface file lists, in its order: types with their members, and
    the functions, each under the type it belongs to."""
    items, derives, block = [], [], None
    for line in read(MBTI):
        if block is not None:
            if line.startswith("}"):
                items.append(block)
                block = None
            else:
                block["members"].append(line.strip())
            continue
        if line.startswith("#derive("):
            derives = [part.strip().replace("@debug.", "") for part in line[8:-1].split(",")]
            continue
        found = re.match(r"^pub(?:\((?:all|open)\))?\s+(struct|enum|suberror)\s+(\w+)(\[[^\]]*\])?", line)
        if found:
            block = {
                "kind": found.group(1),
                "name": found.group(2),
                "sig": line.rstrip(" {"),
                "members": [],
                "derives": derives,
            }
            derives = []
            if not line.rstrip().endswith("{"):
                items.append(block)
                block = None
            continue
        found = re.match(r"^type (\w+)$", line)
        if found:
            items.append({"kind": "type", "name": found.group(1), "sig": line, "members": [], "derives": []})
            continue
        found = DECL.match(line)
        if found:
            if found.group(2):
                items.append({"kind": "method", "owner": found.group(1), "name": named(line), "sig": line})
            else:
                items.append({"kind": "fn", "name": found.group(1), "sig": line})
    return items


def inline(text):
    return re.sub(r"`([^`]+)`", r"<code>\1</code>", html.escape(text, quote=False))


def prose(text):
    """A note as the page shows it: paragraphs, an indented example, a fence."""
    if not text:
        return ""
    out, block, code, fenced = [], [], [], False

    def flush():
        nonlocal block
        if not block:
            return
        if all(not line.strip() or line.startswith("    ") for line in block):
            out.append(f'<pre class="code">{html.escape(dedented(chr(10).join(block)).strip(chr(10)), quote=False)}</pre>')
        else:
            out.append(f"<p>{inline(' '.join(line.strip() for line in block))}</p>")
        block = []

    for line in text.split("\n"):
        if line.strip().startswith("```"):
            if fenced:
                out.append(f'<pre class="code">{html.escape(chr(10).join(code).strip(chr(10)), quote=False)}</pre>')
                code, fenced = [], False
            else:
                flush()
                fenced = True
            continue
        if fenced:
            code.append(line)
            continue
        if not line.strip():
            flush()
            continue
        block.append(line)
    flush()
    return "".join(out)


def dedented(text):
    return "\n".join(line[4:] if line.startswith("    ") else line for line in text.split("\n"))


def signature(text):
    return f'<pre class="sig">{html.escape(text.strip(), quote=False)}</pre>'


def anchor(name):
    return name.replace("::", "-").replace(".", "-")


def render(items, prose_of, signature_of):
    """The page's body and its itinerary, and every anchor the interface file
    obliges it to carry."""
    anchors, nav, body = [], [], []
    types = sorted((item for item in items if item["kind"] in ("struct", "enum", "suberror", "type")), key=lambda i: i["name"].lower())
    functions = sorted((item for item in items if item["kind"] == "fn"), key=lambda i: i["name"])
    methods = {}
    for item in items:
        if item["kind"] == "method":
            methods.setdefault(item["owner"], []).append(item)

    for entry in types:
        name = entry["name"]
        anchors.append(name)
        nav.append(f'      <li><a href="#{anchor(name)}">{name}</a></li>')
        body.append(f'    <section class="entry" id="{anchor(name)}">')
        body.append(f'      <h3><span class="kind">{entry["kind"]}</span>{name}</h3>')
        body.append(f'      <div class="prose">{prose(prose_of.get(name, ""))}</div>')
        head = f'#derive({", ".join(entry["derives"])})\n' if entry["derives"] else ""
        text = head + entry["sig"]
        if entry["members"]:
            text += " {\n" + "\n".join(f"  {member}" for member in entry["members"]) + "\n}"
        body.append(signature(text))
        if entry["members"]:
            rows = []
            for member in entry["members"]:
                key = NAME.match(member).group(1)
                anchors.append(f"{name}.{key}")
                rows.append(
                    f'          <tr id="{anchor(f"{name}.{key}")}">'
                    f"<th>{html.escape(member, quote=False)}</th>"
                    f"<td>{inline(prose_of.get(f'{name}.{key}', ''))}</td></tr>"
                )
            body.append('      <table class="members">')
            body.append("        <tbody>")
            body.extend(rows)
            body.append("        </tbody>")
            body.append("      </table>")
        own, derived = [], []
        for method in methods.get(name, []):
            (derived if method["name"].split("::")[-1] in DERIVED else own).append(method)
        for method in own:
            anchors.append(method["name"])
            body.append(f'      <div class="member" id="{anchor(method["name"])}">')
            body.append(f'        <h4><span class="kind">fn</span>{html.escape(method["name"], quote=False)}</h4>')
            body.append(f"        {signature(signature_of.get(method['name'], method['sig']))}")
            body.append(f'        <div class="prose">{prose(prose_of.get(method["name"], ""))}</div>')
            body.append("      </div>")
        if derived:
            body.append('      <p class="traits-label">From the derive</p>')
            body.append('      <ul class="traits">')
            for method in derived:
                anchors.append(method["name"])
                text = signature_of.get(method["name"], method["sig"]).replace("\n", " ")
                body.append(
                    f'        <li id="{anchor(method["name"])}"><code>{html.escape(text, quote=False)}</code></li>'
                )
            body.append("      </ul>")
        body.append("    </section>")

    if functions:
        nav.append('      <li><a href="#functions">Functions</a></li>')
        body.append('    <section class="entry" id="functions">')
        body.append('      <h3><span class="kind">fn</span>Functions</h3>')
        for item in functions:
            anchors.append(item["name"])
            body.append(f'      <div class="member" id="{anchor(item["name"])}">')
            body.append(f'        <h4>{html.escape(item["name"], quote=False)}</h4>')
            body.append(f"        {signature(signature_of.get(item['name'], item['sig']))}")
            body.append(f'        <div class="prose">{prose(prose_of.get(item["name"], ""))}</div>')
            body.append("      </div>")
        body.append("    </section>")
    return anchors, nav, body


def main():
    prose_of, signature_of = notes()
    anchors, nav, body = render(interface(), prose_of, signature_of)
    page = TEMPLATE.read_text(encoding="utf-8")
    page = page.replace("<!-- nav -->", "\n".join(nav))
    page = page.replace("<!-- body -->", "\n".join(body))
    missing = [name for name in anchors if f'id="{anchor(name)}"' not in page]
    if missing:
        sys.exit("not on the page: " + ", ".join(missing))
    OUT.write_text(page, encoding="utf-8", newline="\n")
    print(f"{OUT.relative_to(ROOT).as_posix()}: {len(anchors)} public items")
    return 0


if __name__ == "__main__":
    sys.exit(main())
