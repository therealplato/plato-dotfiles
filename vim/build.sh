#!/bin/sh
set -e
FORCE=0
V=./vimfiles-osx
VRC=./.vimrc
if [ -z ${OS+x} ]; then
    echo -e "Env OS not set, assuming osx"
    OS="osx"
fi

while test $# -gt 0; do
  case "$1" in
    -f|--f|--force)
	  FORCE=1
	  break
      ;;
    *)
      break
      ;;
  esac	
done


echo "\" Generated by plato-dotfiles/build-windows.sh" > $VRC
echo "\" sensible.vim:" >> $VRC
cat $V/sensible.vim >> $VRC
echo "\" plugins.vimrc:" >> $VRC
cat $V/plugins.vimrc >> $VRC
echo "\" config.vimrc:" >> $VRC
cat $V/config.vimrc >> $VRC
echo "\" binds.vimrc:" >> $VRC
cat $V/binds.vimrc >> $VRC
echo "\" visual.vimrc:" >> $VRC
cat $V/visual.vimrc >> $VRC

echo "generated $(wc -l $VRC | grep -Eo ^[0-9]+) lines of vimrc"

if [ $FORCE -eq 1 ]; then
  if [ $OS -eq "windows" ]; then
    cp -vi $VRC $HOME/_vimrc
  else
    cp -vi $VRC $HOME/.vimrc
  fi
fi
