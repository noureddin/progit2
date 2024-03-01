#!/bin/bash

get='wget -q --show-progress'

[[ ! -e fontawesome-webfont.woff2 ]] && $get https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/fonts/fontawesome-webfont.woff2
[[ ! -e font-awesome.min.css      ]] && $get https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css

UNI_ASC=9,20-7e,a0
UNI_ALL=9,20-7e,a0,ab,bb,60c,61b,61f,621-63a,640-652,660-66a,67e

convert_font() {
  input="$1"
  range="$2"
  pyftsubset "$input" --output-file="${input%.*}".woff2 --layout-features=* --flavor=woff2 --unicodes=$range
  pyftsubset "$input" --output-file="${input%.*}".woff  --layout-features=* --flavor=woff  --unicodes=$range --with-zopfli
}

if [[ ! -e Amiri-Regular.woff2 ]]; then
  tmp="$(mktemp -d)"; cd "$tmp"
  $get https://github.com/aliftype/amiri/releases/download/1.000/Amiri-1.000.zip
  unzip -q Amiri-1.000.zip
  convert_font Amiri-1.000/Amiri-Regular.ttf $UNI_ALL
  cd - >/dev/null
  cp "$tmp"/Amiri-1.000/Amiri-Regular.woff* .
  rm -rf "$tmp"
fi

get_and_convert() { $get "$1/$2" -O "$2" && convert_font "$2" "$3" && rm -f "$2"; }

GF=https://github.com/googlefonts
NOTO=$GF/noto-fonts/raw/main/hinted/ttf

[[ ! -e NotoSans-Regular.woff2      ]] && get_and_convert "$NOTO/NotoSans" NotoSans-Regular.ttf $UNI_ASC
[[ ! -e NotoKufiArabic-Medium.woff2 ]] && get_and_convert "$NOTO/NotoKufiArabic" NotoKufiArabic-Medium.ttf $UNI_ALL
[[ ! -e Tajawal-Bold.woff2          ]] && get_and_convert "$GF/tajawal/raw/main/fonts/ttf" Tajawal-Bold.ttf $UNI_ALL

if [[ ! -e SourceCodePro-Regular.ttf.woff2 ]] ||
   [[ ! -e SourceCodePro-Bold.ttf.woff2 ]]
then
  tmp="$(mktemp -d)"; cd "$tmp"
  $get 'https://github.com/adobe-fonts/source-code-pro/releases/download/2.042R-u%2F1.062R-i%2F1.026R-vf/WOFF2-source-code-pro-2.042R-u_1.062R-i_1.026Rvf.zip'
  unzip -q WOFF2-source-code-pro-*.zip
  cd - >/dev/null
  cp "$tmp"/WOFF2/TTF/SourceCodePro-{Regular,Bold}.ttf.woff2 .
  rm -rf "$tmp"
fi

# todo: kawkab mono
