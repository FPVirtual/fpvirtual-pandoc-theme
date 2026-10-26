---
title: "Ejemplo completo"
subtitle: "Uso de la plantilla FPVirtual con Markdown y Pandoc"
author: "FP Campus Digital"
date: "26 de octubre de 2026"
keywords: [Markdown, Pandoc, LaTeX, FPVirtual]
lang: es
mainfont: Carlito
sansfont: Carlito
toc-title: "Índice"
numbersections: true
titlepage: true
titlepage-logo: "../../fpvirtual/logo-cdfp.png"
page-background: "../../fpvirtual/portada-fondo.png"
page-background-opacity: "1"
colorlinks: true
header-left: ""
header-right: ""
footer-left: "FP Campus Digital"
footer-right: "\\thepage"
---

# Conversión de Markdown a PDF

Esta plantilla convierte un documento Markdown en un PDF con la imagen
corporativa de FPVirtual: portada, colores, tipografía y cabeceras. Todo el
contenido de este documento (incluido este párrafo) es Markdown normal.

## Con pandoc y LaTeX instalados

Si ya tienes [pandoc](https://pandoc.org/) y una distribución de LaTeX
(p. ej. TeX Live), la conversión es un solo comando:

``` bash
pandoc document.md -o document.pdf \
  --template=../../fpvirtual.latex \
  --pdf-engine=xelatex \
  --toc --syntax-highlighting idiomatic
```

El motor debe ser `xelatex` (o `lualatex`): la tipografía corporativa es
**Carlito** (la equivalente libre de Calibri) y solo los motores Unicode pueden
usarla. Las fuentes TTF se distribuyen en `fpvirtual/fonts/`; para que el
sistema las encuentre, cópialas a tu carpeta de fuentes y regenera la caché:

``` bash
mkdir -p ~/.local/share/fonts
cp fpvirtual/fonts/*.ttf ~/.local/share/fonts/
fc-cache -f
```

> Las rutas de `titlepage-logo` y `page-background` del YAML son relativas al
> directorio desde el que se ejecuta pandoc, no al archivo Markdown.

## Sin instalar nada: Docker

Si no quieres instalar pandoc ni LaTeX (varios GB), puedes usar la imagen
[pandoc/extra](https://hub.docker.com/r/pandoc/extra), que ya incluye pandoc,
TeX Live completo, fuentes y filtros. Únicamente necesitas Docker.

La idea es montar en el contenedor la carpeta que contiene tu Markdown, la
plantilla (`fpvirtual.latex`) y los recursos corporativos (la carpeta
`fpvirtual/` con el logo y el fondo). Colócalos junto a tu documento y lanza:

``` bash
docker run --rm \
       --volume "$(pwd):/data" \
       --volume "$PWD/fpvirtual/fonts:/usr/share/fonts/carlito:ro" \
       --env XDG_CACHE_HOME=/tmp/cache \
       --user "$(id -u):$(id -g)" \
       pandoc/extra document.md -o document.pdf \
       --template=fpvirtual.latex \
       --pdf-engine=xelatex \
       --toc --syntax-highlighting idiomatic
```

- `--volume "$(pwd):/data"` hace visible tu carpeta dentro del contenedor.
- El segundo `--volume` instala la fuente corporativa Carlito en el contenedor
  (la imagen no la incluye); así el PDF usa la misma tipografía que en local.
- `--env XDG_CACHE_HOME=/tmp/cache` evita los avisos de caché de fontconfig
  al ejecutar con un usuario sin directorio personal.
- `--user "$(id -u):$(id -g)"` evita que el PDF generado pertenezca a `root`.
- La primera ejecución descarga la imagen (~1 GB); las siguientes van rápido.

Para compilar este mismo ejemplo dentro del repositorio, sin copiar nada:

``` bash
docker run --rm \
       --volume "$PWD:/repo" \
       --volume "$PWD/fpvirtual/fonts:/usr/share/fonts/carlito:ro" \
       --env XDG_CACHE_HOME=/tmp/cache \
       --workdir /repo/examples/fpvirtual-completo \
       --user "$(id -u):$(id -g)" \
       pandoc/extra document.md -o document.pdf \
       --template=/repo/fpvirtual.latex \
       --pdf-engine=xelatex \
       --toc --syntax-highlighting idiomatic
```

## Alias para uso frecuente

Si lo usas a menudo, define un alias en tu `~/.bashrc` o `~/.zshrc`:

``` bash
alias pandock='docker run --rm -v "$(pwd):/data" -u "$(id -u):$(id -g)" pandoc/extra'
```

y la conversión queda reducida a:

``` bash
pandock document.md -o document.pdf --template=fpvirtual.latex \
  --pdf-engine=xelatex --toc --syntax-highlighting idiomatic
```

# Metadatos YAML

Todo lo que se ve en la portada y en las cabeceras se configura en el bloque
YAML del principio del documento. Las variables más habituales de esta
plantilla son:

| Variable | Descripción |
|------------|----------------------------------------------|
| `title`, `subtitle`, `author`, `date` | Datos de la portada. |
| `titlepage` | Activa la portada corporativa (`true`). |
| `titlepage-logo` | Ruta del logo de la portada. |
| `page-background` | Imagen de fondo del resto de páginas (línea corporativa). |
| `page-background-opacity` | Opacidad del fondo (por defecto `0.2`). |
| `toc-title` | Título del índice (p. ej. `Índice`). |
| `numbersections` | Numera las secciones (`true`). |
| `lang` | Idioma del documento (`es`). |
| `mainfont`, `sansfont` | Tipografía corporativa: `Carlito` (necesita `xelatex`). |
| `colorlinks` | Muestra los enlaces con color en vez de recuadros. |
| `header-left`, `header-right` | Texto de las cabeceras (vacío para ocultarlas). |
| `footer-left`, `footer-right` | Texto de los pies de página (`\thepage` = número de página). |

# Tipografía básica

Un párrafo normal se escribe tal cual, separándolo con una línea en blanco.
Dentro de un párrafo puedes usar **negrita**, *cursiva*, `código inline`,
~~tachado~~ y [enlaces a sitios web](https://pandoc.org). También hay notas al
pie[^nota] y referencias cruzadas a secciones, como la
[sección de tablas](#tablas).

[^nota]: Las notas al pie se definen así y LaTeX las coloca al pie de la
    página correspondiente.

# Listas

Listas desordenadas con distintos niveles:

- Primer nivel
  - Segundo nivel
    - Tercer nivel
- Otro elemento del primer nivel

Listas ordenadas:

1. Primer paso.
2. Segundo paso.
   1. Subpaso.
   2. Otro subpaso.
3. Tercer paso.

# Tablas

Las tablas en formato *pipe* se convierten a tablas profesionales de LaTeX:

| Versión    | Descripción   | Fecha      |
|------------|---------------|------------|
| 1.0.0      | 1ª edición    | 07/02/2025 |
| 1.1.0      | Revisión menor| 20/10/2026 |

: Tabla 1 — Historial de versiones del documento.

# Imágenes

Las imágenes se escalan automáticamente si son más anchas que la página:

![Logo de FP Campus Digital](../../fpvirtual/logo-cdfp.png)

![Icono del proyecto](../../icon.png)

# Bloques de código

Los bloques de código llevan resaltado de sintaxis. Se recomienda compilar con
`--syntax-highlighting idiomatic`, como hacen los comandos de la
[primera sección](#con-pandoc-y-latex-instalados).

``` bash
#!/bin/bash
# Convierte cualquier Markdown a PDF con la plantilla FPVirtual
pandoc "$1" -o "${1%.md}.pdf" \
  --template=fpvirtual.latex \
  --pdf-engine=xelatex --toc
```

``` python
def saluda(nombre: str) -> str:
    """Devuelve un saludo corporativo."""
    return f"Hola, {nombre}, desde FPVirtual"
```

``` yaml
---
title: "Otro documento"
lang: es
titlepage: true
---
```

# Citas

> La educación es el arma más poderosa que puedes usar para cambiar el mundo.
>
> — Nelson Mandela

# Matemáticas

Las expresiones matemáticas se escriben en sintaxis LaTeX, tanto en línea
($e^{i\pi} + 1 = 0$) como en bloque:

$$ \int_{-\infty}^{\infty} e^{-x^2} \, dx = \sqrt{\pi} $$

# Saltos de página y reglas horizontales

El comando `\newpage` inserta un salto de página:

\newpage

Tras el salto, el documento continúa en una página nueva. Una línea de tres
o más guiones produce una regla horizontal:

---

Y con esto concluye el recorrido por las posibilidades de la plantilla.
