#!/bin/bash

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$REPO_DIR/src"

ROOT_UID=0
DEST_DIR=

# For tweaks
opacity=
panel=
window='-round'
round='-round'
blur=
outline=
titlebutton=
icon='-debian'

# Destination directory
if [[ "$UID" -eq "$ROOT_UID" ]]; then
  DEST_DIR="/usr/share/themes"
elif [[ -n "$XDG_DATA_HOME" ]]; then
  DEST_DIR="$XDG_DATA_HOME/themes"
elif [[ -d "$HOME/.themes" ]]; then
  DEST_DIR="$HOME/.themes"
elif [[ -d "$HOME/.local/share/themes" ]]; then
  DEST_DIR="$HOME/.local/share/themes"
else
  DEST_DIR="$HOME/.themes"
fi

SASSC_OPT="-M -t expanded"

THEME_NAME=Adellian_Fluent
THEME_VARIANTS=('' '-red' '-orange' '-yellow' '-green' '-cyan' '-blue' '-purple' '-white' '-black')
COLOR_VARIANTS=('' '-Light' '-Dark')
SIZE_VARIANTS=('-compact')

usage() {
cat << EOF
Usage: $0 [OPTION]...

OPTIONS:
  -d, --dest DIR          Specify destination directory (Default: $DEST_DIR)

  -n, --name NAME         Specify theme name (Default: $THEME_NAME)

  -t, --theme VARIANT     Specify theme color variant(s) [pink|red|orange|yellow|green|cyan|blue|purple|white|black|all] (Default: pink)

  -c, --color VARIANT     Specify color variant(s) [standard|light|dark] (Default: All variants)s)

  -l, --libadwaita        Install link to gtk4 config for theming libadwaita

  -r, --remove
  -u, --uninstall         Uninstall/remove themes or link for libadwaita

  -h, --help              Show help
EOF
}

install() {
  local dest="$1"
  local name="$2"
  local theme="$3"
  local color="$4"
  local size="$5"
  local icon="$6"

  [[ "$color" == '-Dark' ]] && local ELSE_DARK="$color"
  [[ "$color" == '-Light' ]] && local ELSE_LIGHT="$color"
  [[ "$color" == '-Dark' ]] || [[ "$color" == '' ]] && local ACTIVITIES_ASSETS_SUFFIX="-Dark"

  local THEME_DIR="$dest/$name$theme$color"

  [[ -d "$THEME_DIR" ]] && rm -rf "${THEME_DIR:?}"

  theme_tweaks && install_theme_color

  echo "Installing '$THEME_DIR'..."

  mkdir -p                                                                      "$THEME_DIR"
  cp -r "$REPO_DIR/COPYING"                                                     "$THEME_DIR"

  echo "[Desktop Entry]" >>                                                     "$THEME_DIR/index.theme"
  echo "Type=X-GNOME-Metatheme" >>                                              "$THEME_DIR/index.theme"
  echo "Name=$name$round$theme$color$size" >>                                   "$THEME_DIR/index.theme"
  echo "Comment=An Materia Gtk+ theme based on Elegant Design" >>               "$THEME_DIR/index.theme"
  echo "Encoding=UTF-8" >>                                                      "$THEME_DIR/index.theme"
  echo "" >>                                                                    "$THEME_DIR/index.theme"
  echo "[X-GNOME-Metatheme]" >>                                                 "$THEME_DIR/index.theme"
  echo "GtkTheme=$name$round$theme$color$size" >>                               "$THEME_DIR/index.theme"
  echo "IconTheme=$name${ELSE_DARK:-}" >>                                       "$THEME_DIR/index.theme"
  echo "CursorTheme=$name${ELSE_DARK:-}" >>                                     "$THEME_DIR/index.theme"
  echo "ButtonLayout=close,minimize,maximize:menu" >>                           "$THEME_DIR/index.theme"

  mkdir -p                                                                      "$THEME_DIR/gtk-2.0"
  cp -r "$SRC_DIR/gtk-2.0/common/"{apps.rc,hacks.rc,main.rc}                    "$THEME_DIR/gtk-2.0"
  cp -r "$SRC_DIR/gtk-2.0/assets-folder/assets$theme${ELSE_DARK:-}"             "$THEME_DIR/gtk-2.0/assets"
  cp -r "$SRC_DIR/gtk-2.0/gtkrc$theme${ELSE_DARK:-}"                            "$THEME_DIR/gtk-2.0/gtkrc"

  mkdir -p                                                                      "$THEME_DIR/gtk-3.0"
  cp -r "$SRC_DIR/gtk/assets$theme"                                             "$THEME_DIR/gtk-3.0/assets"
  cp -r "$SRC_DIR/gtk/scalable"                                                 "$THEME_DIR/gtk-3.0/assets"
  cp -r "$SRC_DIR/gtk/thumbnail$theme${ELSE_DARK:-}.png"                        "$THEME_DIR/gtk-3.0/thumbnail.png"

  if [[ "$tweaks" == 'true' ]]; then
    sassc $SASSC_OPT "$SRC_DIR/gtk/3.0/gtk$color$size.scss"                     "$THEME_DIR/gtk-3.0/gtk.css"
    sassc $SASSC_OPT "$SRC_DIR/gtk/3.0/gtk-Dark$size.scss"                      "$THEME_DIR/gtk-3.0/gtk-dark.css"
  else
    cp -r "$SRC_DIR/gtk/3.0/gtk$theme$color$size.css"                           "$THEME_DIR/gtk-3.0/gtk.css"
    cp -r "$SRC_DIR/gtk/3.0/gtk$theme-Dark$size.css"                            "$THEME_DIR/gtk-3.0/gtk-dark.css"
  fi

  mkdir -p                                                                      "$THEME_DIR/gtk-4.0"
  cp -r "$SRC_DIR/gtk/assets$theme"                                             "$THEME_DIR/gtk-4.0/assets"
  cp -r "$SRC_DIR/gtk/scalable"                                                 "$THEME_DIR/gtk-4.0/assets"

  if [[ "$tweaks" == 'true' ]]; then
    sassc $SASSC_OPT "$SRC_DIR/gtk/4.0/gtk$color$size.scss"                     "$THEME_DIR/gtk-4.0/gtk.css"
    sassc $SASSC_OPT "$SRC_DIR/gtk/4.0/gtk-Dark$size.scss"                      "$THEME_DIR/gtk-4.0/gtk-dark.css"
  else
    cp -r "$SRC_DIR/gtk/4.0/gtk$color$size.css"                                 "$THEME_DIR/gtk-4.0/gtk.css"
    cp -r "$SRC_DIR/gtk/4.0/gtk-Dark$size.css"                                  "$THEME_DIR/gtk-4.0/gtk-dark.css"
  fi

  mkdir -p                                                                      "$THEME_DIR/xfwm4"


  cp -r "$SRC_DIR/xfwm4/assets$color/"*.png                                   "$THEME_DIR/xfwm4"
  cp -r "$SRC_DIR/xfwm4/themerc${ELSE_LIGHT:-}"                               "$THEME_DIR/xfwm4/themerc"
}

themes=()
colors=()
sizes=()
lcolors=()

while [[ "$#" -gt 0 ]]; do
  case "${1:-}" in
    -d|--dest)
      dest="$2"
      mkdir -p "$dest"
      shift 2
      ;;
    -n|--name)
      _name="$2"
      shift 2
      ;;
    -l|--libadwaita)
      libadwaita="true"
      shift
      ;;
    -u|--uninstall|-r|--remove)
      uninstall="true"
      shift
      ;;
    --tweaks)
      shift
      for tweaks in "$@"; do
        case "$tweaks" in
          solid)
            opacity="solid"
            shift
            ;;
          float)
            panel="float"
            echo -e "Install floating panel version ..."
            shift
            ;;
          round)
            window="round"
            echo -e "Install rounded windows version ..."
            shift
            ;;
          blur)
            blur="true"
            panel="compact"
            echo -e "Install blur version ..."
            shift
            ;;
          noborder)
            outline="false"
            echo -e "Install windows without outline version ..."
            shift
            ;;
          -*)
            break
            ;;
          *)
            echo "ERROR: Unrecognized tweaks variant '$1'."
            echo "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
      ;;
    -t|--theme)
      accent='true'
      shift
      for variant in "$@"; do
        case "$variant" in
          pink)
            themes+=("${THEME_VARIANTS[0]}")
            shift
            ;;
          red)
            themes+=("${THEME_VARIANTS[1]}")
            shift
            ;;
          orange)
            themes+=("${THEME_VARIANTS[2]}")
            shift
            ;;
          yellow)
            themes+=("${THEME_VARIANTS[3]}")
            shift
            ;;
          green)
            themes+=("${THEME_VARIANTS[4]}")
            shift
            ;;
          cyan)
            themes+=("${THEME_VARIANTS[5]}")
            shift
            ;;
          blue)
            themes+=("${THEME_VARIANTS[6]}")
            shift
            ;;
          purple)
            themes+=("${THEME_VARIANTS[7]}")
            shift
            ;;
          white)
            themes+=("${THEME_VARIANTS[8]}")
            shift
            ;;
          black)
            themes+=("${THEME_VARIANTS[9]}")
            shift
            ;;
          all)
            themes+=("${THEME_VARIANTS[@]}")
            shift
            ;;
          -*)
            break
            ;;
          *)
            echo "ERROR: Unrecognized theme variant '$1'."
            echo "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
      ;;
    -c|--color)
      shift
      for variant in "$@"; do
        case "$variant" in
          standard)
            colors+=("${COLOR_VARIANTS[0]}")
            lcolors+=("${COLOR_VARIANTS[0]}")
            shift
            ;;
          light)
            colors+=("${COLOR_VARIANTS[1]}")
            lcolors+=("${COLOR_VARIANTS[1]}")
            shift
            ;;
          dark)
            colors+=("${COLOR_VARIANTS[2]}")
            lcolors+=("${COLOR_VARIANTS[2]}")
            shift
            ;;
          -*|--*)
            break
            ;;
          *)
            echo "ERROR: Unrecognized color variant '$1'."
            echo "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
      ;;
    -s|--size)
      shift
      sizes+=("${SIZE_VARIANTS[1]}")
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unrecognized installation option '${1:-}'."
      echo "Try '$0 --help' for more information."
      exit 1
      ;;
  esac
done

if [[ "${#themes[@]}" -eq 0 ]] ; then
  themes=("${THEME_VARIANTS[0]}")
fi

if [[ "${#colors[@]}" -eq 0 ]] ; then
  colors=("${COLOR_VARIANTS[@]}")
fi

if [[ "${#lcolors[@]}" -eq 0 ]] ; then
  lcolors=("${COLOR_VARIANTS[1]}")
fi

if [[ "${#sizes[@]}" -eq 0 ]] ; then
  sizes=("${SIZE_VARIANTS[@]}")
fi

#  Check command avalibility
function has_command() {
  command -v $1 > /dev/null
}

#  Install needed packages
install_package() {
  if [ ! "$(which sassc 2> /dev/null)" ]; then
    echo sassc needs to be installed to generate the css.
    apt-get install sassc # use debian experimental as intended or die or smth
  fi
}

tweaks_temp() {
  cp -rf ${SRC_DIR}/_sass/_tweaks.scss ${SRC_DIR}/_sass/_tweaks-temp.scss
  cp -rf ${SRC_DIR}/gnome-shell/sass/_tweaks.scss ${SRC_DIR}/gnome-shell/sass/_tweaks-temp.scss
}

install_float_panel() {
  sed -i "/\$panel_style:/s/compact/float/" ${SRC_DIR}/gnome-shell/sass/_tweaks-temp.scss
  sed -i "/\$panel_style:/s/compact/float/" ${SRC_DIR}/_sass/_tweaks-temp.scss
}

install_solid() {
  sed -i "/\$opacity:/s/default/solid/" ${SRC_DIR}/gnome-shell/sass/_tweaks-temp.scss
  sed -i "/\$opacity:/s/default/solid/" ${SRC_DIR}/_sass/_tweaks-temp.scss
  echo -e "Install solid version ..."
}

install_round() {
  sed -i "/\$window:/s/default/round/" ${SRC_DIR}/gnome-shell/sass/_tweaks-temp.scss
  sed -i "/\$window:/s/default/round/" ${SRC_DIR}/_sass/_tweaks-temp.scss
}

install_blur() {
  sed -i "/\$blur:/s/false/true/" ${SRC_DIR}/gnome-shell/sass/_tweaks-temp.scss
  sed -i "/\$blur:/s/false/true/" ${SRC_DIR}/_sass/_tweaks-temp.scss
}

install_noborder() {
  sed -i "/\$outline:/s/true/false/" ${SRC_DIR}/gnome-shell/sass/_tweaks-temp.scss
  sed -i "/\$outline:/s/true/false/" ${SRC_DIR}/_sass/_tweaks-temp.scss
}

activities_style() {
  sed -i "/\$activities:/s/default/icon/" ${SRC_DIR}/gnome-shell/sass/_tweaks-temp.scss
}

install_theme_color() {
  if [[ "$theme" != '' ]]; then
    case "$theme" in
      -pink)
        theme_color='pink'
        ;;
      -red)
        theme_color='red'
        ;;
      -orange)
        theme_color='orange'
        ;;
      -yellow)
        theme_color='yellow'
        ;;
      -green)
        theme_color='green'
        ;;
      -cyan)
        theme_color='cyan'
        ;;
      -blue)
        theme_color='blue'
        ;;
      -purple)
        theme_color='purple'
        ;;
      -white)
        theme_color='white'
        ;;
      -black)
        theme_color='black'
        ;;
    esac
    sed -i "/\$theme:/s/default/${theme_color}/" ${SRC_DIR}/gnome-shell/sass/_tweaks-temp.scss
    sed -i "/\$theme:/s/default/${theme_color}/" ${SRC_DIR}/_sass/_tweaks-temp.scss
  fi
}

theme_tweaks() {
  if [[ "$panel" = "float" || "$opacity" == 'solid' || "$window" == 'round' || "$accent" == 'true' || "$blur" == 'true' || "$outline" == 'false' || "$activities" = "icon" ]]; then
    tweaks='true'
    install_package; tweaks_temp
  fi

  if [[ "$panel" = "float" ]] ; then
    install_float_panel
  fi

  if [[ "$opacity" = "solid" ]] ; then
    install_solid
  fi

  install_round

  if [[ "$blur" = "true" ]] ; then
    install_blur
  fi

  if [[ "$outline" = "false" ]] ; then
    install_noborder
  fi

  if [[ "$activities" = "icon" ]] ; then
    activities_style
  fi
}

uninstall() {
  local dest="${1}"
  local name="${2}"
  local theme="${3}"
  local color="${4}"
  local size="${5}"

  if [[ "$window" == 'round' ]]; then
    round='-round'
  else
    round=$window
  fi

  local THEME_DIR="$dest/$name$round$theme$color$size"

  if [[ -d "${THEME_DIR}" ]]; then
    echo -e "Uninstall ${THEME_DIR}... "
    rm -rf "${THEME_DIR}"
  fi
}

uninstall_link() {
  rm -rf "${HOME}/.config/gtk-4.0"/{assets,gtk.css,gtk-dark.css}
}

link_libadwaita() {
  local dest="$1"
  local name="$2"
  local theme="$3"
  local color="$4"
  local size="$5"

  if [[ "$window" == 'round' ]]; then
    round='-round'
  else
    round=$window
  fi

  local THEME_DIR="$dest/$name$round$theme$color$size"

  echo -e "\nLink '$THEME_DIR/gtk-4.0' to '${HOME}/.config/gtk-4.0' for libadwaita..."

  mkdir -p                                                                      "${HOME}/.config/gtk-4.0"
  ln -sf "${THEME_DIR}/gtk-4.0/assets"                                          "${HOME}/.config/gtk-4.0/assets"
  ln -sf "${THEME_DIR}/gtk-4.0/gtk.css"                                         "${HOME}/.config/gtk-4.0/gtk.css"
  ln -sf "${THEME_DIR}/gtk-4.0/gtk-dark.css"                                    "${HOME}/.config/gtk-4.0/gtk-dark.css"
}

clean() {
  local dest="$1"
  local name="$2"
  local round="$3"
  local theme="$4"
  local color="$5"
  local size="$6"

  local THEME_DIR="$dest/$name$round$theme$color$size"

  if [[ -d ${THEME_DIR} ]]; then
    rm -rf ${THEME_DIR}
    echo -e "Find: ${THEME_DIR} ! removing it ..."
  fi
}

clean_theme() {
  for round in '' '-round'; do
    for theme in "${THEME_VARIANTS[@]}"; do
      for color in '-light' '-dark'; do
        for size in "${SIZE_VARIANTS[@]}"; do
          clean "${dest:-$DEST_DIR}" "${name:-$THEME_NAME}" "$round" "$theme" "$color"
        done
      done
    done
  done

  if [[ "$DEST_DIR" == "$HOME/.themes" ]]; then
    local dest="$HOME/.local/share/themes"
  fi

  for theme in "${THEME_VARIANTS[@]}"; do
    for color in "${COLOR_VARIANTS[@]}"; do
      for size in "${SIZE_VARIANTS[@]}"; do
        uninstall "${dest}" "${name:-$THEME_NAME}" "$theme" "$color"
      done
    done
  done
}

uninstall_theme() {
  for theme in "${themes[@]}"; do
    for color in "${colors[@]}"; do
      for size in "${sizes[@]}"; do
        uninstall "${dest:-$DEST_DIR}" "${name:-$THEME_NAME}" "$theme" "$color"
      done
    done
  done
}

install_theme() {
  for theme in "${themes[@]}"; do
    for color in "${colors[@]}"; do
      for size in "${sizes[@]}"; do
        install "${dest:-$DEST_DIR}" "${name:-$THEME_NAME}" "$theme" "$color" "$size"
      done
    done
  done
}

link_theme() {
  for theme in "${themes[@]}"; do
    for color in "${lcolors[@]}"; do
      for size in "${sizes[0]}"; do
        link_libadwaita "${dest:-$DEST_DIR}" "${name:-$THEME_NAME}" "$theme" "$color"
      done
    done
  done
}

if [[ "$uninstall" == 'true' ]]; then
  if [[ "$libadwaita" == 'true' ]]; then
    echo -e "\nUninstall ${HOME}/.config/gtk-4.0 links ..."
    uninstall_link
  else
    echo && uninstall_theme && uninstall_link
  fi
else
   clean_theme && install_theme

   if [[ "$libadwaita" == 'true' ]]; then
     uninstall_link && link_theme
   fi
fi

echo
echo "Done."
