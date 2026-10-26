#!/bin/bash
#
# Fix oversized images that push a figure to the next page and leave the page
# where the image was referenced with more than a given percentage of free
# space (default 50%).
#
# The script compiles the document, finds such pages, and shrinks the
# offending image(s) in the markdown source (adding/updating the pandoc
# `{width=NN%}` attribute) until the figure fits or the width floor is
# reached. Changes are kept in the markdown; an .orig-fpvirtual backup is made
# once.
#
# Usage: tools/fix-image-sizes.sh [options]
#   -m, --md FILE        markdown source (default: docs/pre/guia-de-usuario.md)
#   -p, --pdf FILE       output PDF (default: docs/guia-de-usuario.pdf)
#   -b, --build CMD      build command (default: ./build-guia.sh)
#   -t, --threshold N    free-space percentage that triggers a shrink (50)
#       --factor F       width multiplier per iteration (0.85)
#       --min-width N    never shrink below this percentage (40)
#       --max-iter N     maximum shrink/rebuild iterations (12)

set -euo pipefail

MD="docs/pre/guia-de-usuario.md"
PDF="docs/guia-de-usuario.pdf"
BUILD="./build-guia.sh"
THRESHOLD=50
FACTOR=0.85
MIN_WIDTH=40
MAX_ITER=12

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--md) MD="$2"; shift 2;;
    -p|--pdf) PDF="$2"; shift 2;;
    -b|--build) BUILD="$2"; shift 2;;
    -t|--threshold) THRESHOLD="$2"; shift 2;;
    --factor) FACTOR="$2"; shift 2;;
    --min-width) MIN_WIDTH="$2"; shift 2;;
    --max-iter) MAX_ITER="$2"; shift 2;;
    -h|--help) grep '^#' "$0" | head -20; exit 0;;
    *) echo "unknown option: $1" >&2; exit 2;;
  esac
done

for tool in python3 pdfinfo pdftotext pdftohtml; do
  command -v "$tool" >/dev/null || { echo "missing required tool: $tool" >&2; exit 1; }
done

echo "Building with: $BUILD"
$BUILD

[ -f "$MD.orig-fpvirtual" ] || cp "$MD" "$MD.orig-fpvirtual"

# Analyze the PDF and print the 1-based markdown image index of the first
# figure that jumped to the next page leaving > THRESHOLD% free space behind,
# or print nothing if there is no such page.
analyze() {
  python3 - "$PDF" "$THRESHOLD" <<'PYEOF'
import re, subprocess, sys, tempfile, os
import xml.etree.ElementTree as ET

pdf, threshold = sys.argv[1], float(sys.argv[2]) / 100.0

tmp = tempfile.mkdtemp(prefix="fiximg-")
try:
    subprocess.run(["pdftohtml", "-xml", os.path.abspath(pdf),
                    os.path.join(tmp, "doc")],
                   capture_output=True, check=True, cwd=tmp)
    root = ET.parse(os.path.join(tmp, "doc.xml")).getroot()
finally:
    import shutil; shutil.rmtree(tmp, ignore_errors=True)

pages = []
for pg in root.iter("page"):
    h = float(pg.get("height"))
    bottoms = [(float(t.get("top")) + float(t.get("height"))) / h
               for t in pg.iter("text")]
    text_bottom = max((b for b in bottoms if b <= 0.93), default=0.0)
    imgs = [(float(i.get("top")) / h, float(i.get("height")) / h)
            for i in pg.iter("image")]
    pages.append((int(pg.get("number")), text_bottom, imgs))

def page_text(p):
    return subprocess.run(["pdftotext", "-f", str(p), "-l", str(p), pdf, "-"],
                          capture_output=True, text=True).stdout

# Header logos are small (< 15% page height) and the page background fills
# the page (>= 95%): neither counts as a figure.
def figures(imgs):
    return [(top, ih) for top, ih in imgs if 0.15 <= ih < 0.95 and top > 0.06]

for idx in range(len(pages) - 1):
    n, text_bottom, imgs = pages[idx]
    bottoms = [text_bottom] + [top + ih for top, ih in figures(imgs)]
    free = 1.0 - max(bottoms)
    if free <= threshold:
        continue
    n2, _, imgs2 = pages[idx + 1]
    figs = figures(imgs2)
    if not figs or min(top for top, _ in figs) > 0.30:
        continue
    m = re.search(r"(?:Figura|Figure)\s+(\d+)", page_text(n2))
    if m:
        print(m.group(1))
        break
PYEOF
}

# Shrink the Nth markdown image by FACTOR (or set {width=NN%} if it has no
# explicit width). Exit 0 on success, 3 if the width floor was already hit.
shrink() {
  python3 - "$MD" "$1" "$FACTOR" "$MIN_WIDTH" <<'PYEOF'
import re, sys
md, fig, factor, minw = sys.argv[1], int(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4])
src = open(md, encoding="utf-8").read()
pat = re.compile(r"!\[([^\]]*)\]\(([^)]+)\)(\{[^}]*\})?")
matches = list(pat.finditer(src))
if not (1 <= fig <= len(matches)):
    sys.exit("figure index out of range: %d" % fig)
m = matches[fig - 1]
attrs = m.group(3)
wm = re.search(r"width=([\d.]+)%", attrs) if attrs else None
if wm:
    new = round(float(wm.group(1)) * factor, 1)
else:
    new = round(100 * factor)
new = max(new, minw)
if wm and float(wm.group(1)) <= minw:
    print("figure %d already at width floor %g%%" % (fig, minw))
    sys.exit(3)
newattrs = ("{%s}" % attrs[1:-1]) if attrs else "{}"
if wm:
    a = attrs[1:-1]
    pos = a.find(wm.group(0))
    a = a[:pos] + "width=%s%%" % new + a[pos + len(wm.group(0)):]
    newattrs = "{%s}" % a
else:
    inner = attrs[1:-1] if attrs else ""
    sep = ", " if inner else ""
    newattrs = "{%s%swidth=%s%%}" % (inner, sep, new)
replacement = "![%s](%s)%s" % (m.group(1), m.group(2), newattrs)
src = src[:m.start()] + replacement + src[m.end():]
open(md, "w", encoding="utf-8").write(src)
print("figure %d (%s) -> width=%s%%" % (fig, m.group(2), new))
PYEOF
}

for i in $(seq 1 "$MAX_ITER"); do
  fig=$(analyze || true)
  if [ -z "$fig" ]; then
    echo "OK: no page with more than ${THRESHOLD}% free space before a figure."
    exit 0
  fi
  echo "iteration $i: shrinking image #$fig"
  if ! shrink "$fig"; then
    echo "width floor reached, stopping."
    exit 0
  fi
  $BUILD
done

echo "maximum iterations ($MAX_ITER) reached, stopping."
