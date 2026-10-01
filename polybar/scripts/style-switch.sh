#!/bin/bash

## Author : Aditya Shakya
## Github : adi1090x

SDIR="$HOME/.config/polybar/scripts"

MENU="$(rofi -sep "|" -dmenu -i -p 'Select' -theme-str 'window { location: north east; anchor: north east; x-offset: -270px; y-offset: 36px; width: 10%; } listview { lines: 4; }' <<< "> Feather|> Material|> Siji|> Typicons")"
            case "$MENU" in
				## Light Colors
				*Feather) $SDIR/style.sh -Feather ;;
				*Material) $SDIR/style.sh -Material ;;
				*Siji) $SDIR/style.sh -Siji ;;
				*Typicons) $SDIR/style.sh -Typicons ;;
            esac
