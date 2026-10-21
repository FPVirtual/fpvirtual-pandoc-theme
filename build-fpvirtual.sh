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
    -i fpvirtual.latex

# Inject the customization right before \begin{document}
sed -e '/\\begin{document}/ {' \
    -e 'r fpvirtual/customization.latex' \
    -e '}' \
    -i fpvirtual.latex

echo "Built fpvirtual.latex"
