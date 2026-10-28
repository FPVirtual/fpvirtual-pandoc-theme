# Imagen Docker para generar documentos PDF con la plantilla FPVirtual
# (fork de Eisvogel) sin instalar pandoc ni LaTeX.
#
# Construir:  docker build -t fpvirtual-pandoc .
# Usar:       docker run --rm --volume "$(pwd):/data" --user $(id -u):$(id -g) \
#               fpvirtual-pandoc documento.md -o documento.pdf \
#               --template=fpvirtual --pdf-engine=xelatex --toc

# Fase de construcción: compila la plantilla monolítica fpvirtual.latex a
# partir de las fuentes de template-multi-file/ (igual que build-fpvirtual.sh).
FROM alpine:3 AS builder
RUN apk add --no-cache bash python3
WORKDIR /src
COPY build-fpvirtual.sh ./
COPY template-multi-file/ template-multi-file/
COPY fpvirtual/ fpvirtual/
RUN ./build-fpvirtual.sh

# Imagen final: pandoc + LaTeX, basada en la misma imagen que recomienda
# Eisvogel (pandoc/extra), con la plantilla y los recursos corporativos
# de FPVirtual precargados.
FROM pandoc/extra:3.9.0.2-alpine

COPY --from=builder /src/fpvirtual.latex /usr/local/share/pandoc/templates/fpvirtual.latex

# Tipografía corporativa Carlito (necesaria para `mainfont: Carlito` con
# XeLaTeX/LuaLaTeX); la imagen pandoc/extra no la incluye.
COPY fpvirtual/fonts/*.ttf /usr/share/fonts/truetype/carlito/

# Logo y fondo corporativos, disponibles para LaTeX vía TEXINPUTS de modo
# que la portada por defecto funcione sin copiar imágenes al directorio
# de trabajo.
COPY fpvirtual/logo-cdfp.png /opt/fpvirtual/fpvirtual/
COPY fpvirtual/portada-fondo.png /opt/fpvirtual/fpvirtual/
ENV TEXINPUTS=/opt/fpvirtual/:

RUN fc-cache -f

# Métricas Type1 de Helvetica (phv), usadas por la ruta \usepackage{helvet}
# del pdflatex/lualatex cuando el documento no fija mainfont. No están en la
# imagen base pandoc/extra.
RUN tlmgr update --self && tlmgr install helvetic
