#!/bin/bash
#
# Regenera docs/guia-de-usuario.pdf a partir de docs/pre/guia-de-usuario.md
# usando la plantilla FPVirtual.
#
# Usage: ./build-guia.sh

set -euo pipefail

# Rebuild the template only if it doesn't exist or its sources are newer
if [[ ! -f fpvirtual.latex ]] || [[ template-multi-file/eisvogel.latex -nt fpvirtual.latex ]] || [[ fpvirtual/customization.latex -nt fpvirtual.latex ]] || [[ fpvirtual/portada.latex -nt fpvirtual.latex ]]; then
  ./build-fpvirtual.sh
fi

pandoc docs/pre/guia-de-usuario.md \
  -o docs/guia-de-usuario.pdf \
  --template=fpvirtual.latex \
  --resource-path=docs/pre \
  --filter pandoc-latex-environment \
  --toc

echo "Generated docs/guia-de-usuario.pdf"
