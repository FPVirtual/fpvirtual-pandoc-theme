#!/bin/bash
#
# Build the customized FPVirtual template (fpvirtual.latex) from the
# multi-file Eisvogel template plus the FPVirtual customization.
#
# Usage: ./build-fpvirtual.sh

set -euo pipefail

mkdir -p dist
cp template-multi-file/eisvogel.latex dist/eisvogel.latex

for partial in fonts font-settings common document-metadata eisvogel-added \
               eisvogel-title-page after-header-includes hypersetup passoptions; do
  sed -e "/\\\$${partial}\.latex()\\\$/ {" \
      -e "r template-multi-file/${partial}.latex" \
      -e 'd' -e '}' \
      -i dist/eisvogel.latex
done

cp dist/eisvogel.latex fpvirtual.latex

# FPVirtual brand colors (from docs/Plantilla_genérica_con_portada.dotx)
sed -e 's|\\definecolor{default-linkcolor}{HTML}{A50000}|\\definecolor{default-linkcolor}{HTML}{F3970D}|' \
    -e 's|\\definecolor{default-filecolor}{HTML}{A50000}|\\definecolor{default-filecolor}{HTML}{F3970D}|' \
    -e 's|\\definecolor{default-citecolor}{HTML}{4077C0}|\\definecolor{default-citecolor}{HTML}{C77800}|' \
    -e 's|\\definecolor{default-urlcolor}{HTML}{4077C0}|\\definecolor{default-urlcolor}{HTML}{C77800}|' \
    -e 's|\\usepackage\[default\]{sourcesans}|\\usepackage[scaled=0.95]{helvet}\n  \\renewcommand{\\familydefault}{\\sfdefault}|' \
    -e 's|\\usepackage{sourcecodepro}||' \
    -e 's|\\ihead\*{[$]if(header-left)[$][$]header-left[$][$]else[$][$]title[$][$]endif[$]}|\\ihead*{$if(header-left)$$header-left$$endif$}|' \
    -e 's|\\ohead\*{[$]if(header-right)[$][$]header-right[$][$]else[$][$]date[$][$]endif[$]}|\\ohead*{$if(header-right)$$header-right$$endif$}|' \
    -e 's|\\ifoot\*{[$]if(footer-left)[$][$]footer-left[$][$]else[$][$]for(author)[$][$]author[$][$]sep[$][,] [$]endfor[$][$]endif[$]}|\\ifoot*{$if(footer-left)$$footer-left$$endif$}|' \
    -e 's|^\\tableofcontents$|{\\hypersetup{allcolors=black}\\setkomafont{section}{\\color{black}}\\tableofcontents}|' \
    -e 's|\\usepackage\[margin=2.5cm,includehead=true,includefoot=true,centering\]{geometry}|\\usepackage[top=1.9cm,bottom=1.25cm,left=2.5cm,right=2.5cm,includehead=true,includefoot=true]{geometry}|' \
    -e 's|\\usepackage\[margin=2.5cm,includehead=true,includefoot=true,centering,|@GEOMETRY@|' \
    -i fpvirtual.latex
sed -e 's|@GEOMETRY@|\\usepackage[top=1.9cm,bottom=1.25cm,left=2.5cm,right=2.5cm,includehead=true,includefoot=true,|' \
    -i fpvirtual.latex

# Replace the Eisvogel title page with the FPVirtual cover page (dotx design)
python3 - <<'PYEOF'
import re

path = "fpvirtual.latex"
src = open(path, encoding="utf-8").read()

portada = open("fpvirtual/portada.latex", encoding="utf-8").read()
pattern = re.compile(
    r"\$if\(titlepage\)\$\n\\begin\{titlepage\}.*?"
    r"\\end\{titlepage\}\n\\restoregeometry\n\\pagenumbering\{arabic\}\n\$endif\$\n",
    re.S)
src, n = pattern.subn(lambda _m: portada, src)
if n != 1:
    raise SystemExit(f"titlepage block replacement failed (n={n})")

# The FPVirtual cover uses TikZ, which Eisvogel loads only when
# titlepage-background is set, so load it unconditionally.
src, n = re.subn(
    r"\$if\(titlepage-background\)\$\n\\usepackage\{tikz\}\n\$endif\$\n",
    r"\\usepackage{tikz}\n",
    src)
if n != 1:
    raise SystemExit(f"tikz load replacement failed (n={n})")

# License line on the abstract page (front matter), right after the abstract.
# The license text comes from the YAML variable `license` and defaults to
# Creative Commons BY 3.0 when the variable is not set.
abstract_block = (
    "$if(abstract)$\n"
    "\\begin{abstract}\n"
    "$abstract$\n"
    "\\end{abstract}\n"
    "$endif$\n")
start = src.find(abstract_block)
if start == -1:
    raise SystemExit("abstract block not found")
license_block = (
    "$if(license)$\n"
    "\\begin{center}\n"
    "{\\small\\sffamily\\color{fpv-darkgray}$license$}\n"
    "\\end{center}\n"
    "$else$\n"
    "\\begin{center}\n"
    "{\\small\\sffamily\\color{fpv-darkgray}Este documento se distribuye bajo licencia Creative Commons Atribución 3.0 (CC BY 3.0)}\n"
    "\\end{center}\n"
    "$endif$\n")
insert_at = start + len(abstract_block)
src = src[:insert_at] + license_block + src[insert_at:]

# The table of contents starts on a fresh page (after the abstract page).
old_toc_open = "$if(toc)$\n$if(toc-title)$\n\\renewcommand*\\contentsname{$toc-title$}"
new_toc_open = "$if(toc)$\n\\newpage\n$if(toc-title)$\n\\renewcommand*\\contentsname{$toc-title$}"
if src.count(old_toc_open) != 1:
    raise SystemExit("toc opening block not found")
src = src.replace(old_toc_open, new_toc_open)

open(path, "w", encoding="utf-8").write(src)
PYEOF

# Inject the customization right before \begin{document}
sed -e '/\\begin{document}/ {' \
    -e 'r fpvirtual/customization.latex' \
    -e '}' \
    -i fpvirtual.latex

echo "Built fpvirtual.latex"
