#!/bin/bash
#
# Regenera docs/guia-de-usuario.pdf a partir de docs/pre/guia-de-usuario.md
# usando la plantilla FPVirtual. Tras compilar, ajusta automáticamente el
# tamaño de las imágenes que sobresalen vía tools/fix-image-sizes.sh
# (desactívalo con FPV_NO_FIX=1).
#
# Usage: ./build-guia.sh

set -euo pipefail

# Rebuild the template only if it doesn't exist or its sources are newer
if [[ ! -f fpvirtual.latex ]] || [[ template-multi-file/eisvogel.latex -nt fpvirtual.latex ]] || [[ fpvirtual/customization.latex -nt fpvirtual.latex ]] || [[ fpvirtual/portada.latex -nt fpvirtual.latex ]]; then
  ./build-fpvirtual.sh
fi

# Fix oversized images (the fixer rebuilds via this same script, so pass
# FPV_NO_FIX=1 to avoid recursion).
if [[ "${FPV_NO_FIX:-}" != "1" ]]; then
  exec tools/fix-image-sizes.sh -b "env FPV_NO_FIX=1 ./build-guia.sh"
fi

pandoc docs/pre/guia-de-usuario.md \
  -o docs/guia-de-usuario.pdf \
  --template=fpvirtual.latex \
  --resource-path=docs/pre \
  --filter pandoc-latex-environment \
  --toc

echo "Generated docs/guia-de-usuario.pdf"
