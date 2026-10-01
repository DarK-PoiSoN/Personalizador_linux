#!/usr/bin/env bash

## Add this to your wm startup file.

# Si se lanza dos veces a la vez (por ejemplo al recargar bspwm varias veces
# seguidas) solo continua una: asi nunca quedan barras duplicadas encima
exec 9> "${XDG_RUNTIME_DIR:-/tmp}/polybar-launch.lock"
flock -n 9 || exit 0

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u "$(id -u)" -x polybar >/dev/null; do sleep 0.2; done

# Launch Polybar (una pareja de barras por monitor)
for monitor in $(polybar -m | cut -d ':' -f 1); do
	MONITOR=$monitor polybar -c ~/.config/polybar/config.ini top >/dev/null 2>&1 9>&- &
	MONITOR=$monitor polybar -c ~/.config/polybar/config.ini bottom >/dev/null 2>&1 9>&- &
done
