#!/bin/bash

# Autor: David Ojeda
#Personaliza tu sistema operativo // Tested Kali Linux || Parrot Security \\

#Colours
greenColor="\e[0;32m\033[1m"
endColor="\033[0m\e[0m"
redColor="\e[0;31m\033[1m"
blueColor="\e[0;34m\033[1m"
yellowColor="\e[0;33m\033[1m"
purpleColor="\e[0;35m\033[1m"
turquoiseColor="\e[0;36m\033[1m"
grayColor="\e[0;37m\033[1m"

trap ctrl_c INT

function ctrl_c() {
	tput cnorm
	echo -e "\n\n\t${redColor}[*] Saliendo....${endColor}"
	exit 1
}

# El programa necesita root: si no lo somos, se relanza con sudo
if [ "$(id -u)" != "0" ]
then
	if command -v sudo &> /dev/null
	then
		exec sudo bash "$0" "$@"
	fi
	echo -e "\n${redColor}[*] Ejecuta este programa como root${endColor}\n"
	exit 1
fi

rutaPrograma=$(dirname "$(readlink -f "$0")")

registro="/tmp/personalizador.log"
: > "$registro"

espacio=$(echo -e "\t")

prompt=$(echo -e "\t${redColor}root@$(hostname) #${endColor}  ${grayColor}$0 ${endColor}")

export DEBIAN_FRONTEND=noninteractive

dependenciasBspwm=(bspwm sxhkd rofi feh wmname psmisc iproute2 fontconfig x11-xserver-utils xclip git python3)

# Utilidades que mejoran el entorno pero sin las que tambien funciona
dependenciasOpcionales=(gnome-terminal caja i3lock wireless-tools papirus-icon-theme dbus-x11)

# Solo se usan si polybar no esta en los repositorios y hay que compilarla
dependenciasPolybar=(build-essential cmake cmake-data pkg-config python3-sphinx python3-packaging libuv1-dev libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev python3-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-xkb-dev libxcb-xrm-dev libxcb-cursor-dev libasound2-dev libpulse-dev libjsoncpp-dev libmpdclient-dev libcurl4-openssl-dev libnl-genl-3-dev)

dependenciasZsh=(zsh zsh-autosuggestions zsh-syntax-highlighting lsd bat fzf zoxide xclip scrub git)

fallos=()

#Funciones auxiliares

function estaInstalado(){
	dpkg-query -W -f='${Status}' "$1" 2> /dev/null | grep -q "install ok installed"
}

# instalar (paquete)... -> instala cada paquete e informa del resultado real
function instalar(){
	local paquete
	for paquete in "$@"
	do
		if estaInstalado "$paquete"
		then
			echo -e "\t$paquete ${blueColor}instalado${endColor}"
		elif apt-get -o DPkg::Lock::Timeout=120 install -y "$paquete" >> "$registro" 2>&1
		then
			echo -e "\t$paquete ${blueColor}instalado${endColor}"
		else
			echo -e "\t$paquete ${redColor}no se pudo instalar${endColor}"
			fallos+=("$paquete")
		fi
	done
}

function actualizarRepositorios(){
	tput civis
	echo -e "\n\t${purpleColor}[*] Actualizando repositorios....${endColor}\n"
	if ! apt-get -o DPkg::Lock::Timeout=120 update >> "$registro" 2>&1
	then
		echo -e "\t${yellowColor}[!] No se pudieron actualizar todos los repositorios, se continúa con los datos actuales${endColor}\n"
	fi
	tput cnorm
}

# esAfirmativo (respuesta) -> acepta yes, y, si, sí, s (en mayúsculas o minúsculas)
function esAfirmativo(){
	case "${1,,}" in
		yes|y|si|sí|s) return 0 ;;
		*) return 1 ;;
	esac
}

# pedirUsuario (mensaje) [permitirRoot] -> deja el resultado en $usuario y $homeUsuario
function pedirUsuario(){
	local porDefecto=""
	if [[ -n "$SUDO_USER" && "$SUDO_USER" != "root" ]]
	then
		porDefecto="$SUDO_USER"
	fi
	while true
	do
		if [[ -n "$porDefecto" ]]
		then
			echo -e "\n\t${grayColor}$1${endColor} ${blueColor}[$porDefecto]${endColor}"
		else
			echo -e "\n\t${grayColor}$1${endColor}"
		fi
		read -r -p "$espacio" usuario || exit 1
		usuario=${usuario:-$porDefecto}
		if [[ "$usuario" == "root" && "$2" != "permitirRoot" ]]
		then
			echo -e "\n\t${redColor}[*] El usuario no debe ser root, crea un usuario con adduser${endColor}"
		elif [[ -n "$usuario" ]] && id "$usuario" &> /dev/null
		then
			homeUsuario=$(getent passwd "$usuario" | cut -d: -f6)
			if [[ -d "$homeUsuario" ]]
			then
				return 0
			fi
			echo -e "\n\t${redColor}[*] El usuario ${endColor}${grayColor}$usuario${endColor}${redColor} no tiene directorio personal${endColor}"
		else
			echo -e "\n\t${redColor}[*] El usuario ${endColor}${grayColor}$usuario${endColor}${redColor} no existe${endColor}"
		fi
	done
}

# comoUsuario (usuario) (comando)... -> ejecuta el comando con ese usuario
function comoUsuario(){
	local quien="$1"
	shift
	if [[ "$quien" == "root" ]]
	then
		"$@"
	else
		runuser -u "$quien" -- "$@"
	fi
}

# copiarConfig (carpeta del repositorio) (usuario) (home) -> la deja en ~/.config
function copiarConfig(){
	mkdir -p "$3/.config"
	rm -rf "$3/.config/$1" 2> /dev/null
	cp -r "$rutaPrograma/$1" "$3/.config/"
	chown -hR "$2:$(id -gn "$2")" "$3/.config/$1"
	chown "$2:$(id -gn "$2")" "$3/.config"
}

# Copia solo las fuentes nuevas o distintas: tocar una fuente que ya está en uso
# deja sin letras a las terminales abiertas. Deja en $fuentesCambiadas si copió algo
function instalarFuentes(){
	local destino=/usr/local/share/fonts/fonts origen fuente relativa
	fuentesCambiadas=0
	for origen in "$rutaPrograma/fonts" "$rutaPrograma/polybar/fonts"
	do
		while IFS= read -r -d '' fuente
		do
			relativa=${fuente#"$origen"/}
			if ! cmp -s "$fuente" "$destino/$relativa"
			then
				mkdir -p "$(dirname "$destino/$relativa")"
				cp --remove-destination "$fuente" "$destino/$relativa"
				fuentesCambiadas=1
			fi
		done < <(find "$origen" -type f -print0)
	done
	if [[ "$fuentesCambiadas" == "1" ]]
	then
		chmod -R a+rX "$destino"
		fc-cache -f >> "$registro" 2>&1
	fi
}

# Pone una Nerd Font en gnome-terminal para que se vean los iconos de la shell
function configurarTerminal(){
	local quien="$1" bus perfil ruta lanzador actual
	command -v gsettings &> /dev/null || return 0
	bus="/run/user/$(id -u "$quien")/bus"
	if [[ -S "$bus" ]]
	then
		lanzador=(env "DBUS_SESSION_BUS_ADDRESS=unix:path=$bus")
	elif command -v dbus-run-session &> /dev/null
	then
		lanzador=(dbus-run-session --)
	else
		return 0
	fi
	perfil=$(comoUsuario "$quien" "${lanzador[@]}" gsettings get org.gnome.Terminal.ProfilesList default 2>> "$registro" | tr -d "'")
	[[ -z "$perfil" ]] && return 0
	ruta="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$perfil/"
	if [[ "$(comoUsuario "$quien" "${lanzador[@]}" gsettings get "$ruta" use-system-font 2>> "$registro")" == "true" ]]
	then
		comoUsuario "$quien" "${lanzador[@]}" gsettings set "$ruta" use-system-font false >> "$registro" 2>&1
		comoUsuario "$quien" "${lanzador[@]}" gsettings set "$ruta" font 'Hack Nerd Font Mono 11' >> "$registro" 2>&1
	elif [[ "$fuentesCambiadas" == "1" ]]
	then
		# El usuario ya eligió su fuente: se respeta, pero se vuelve a aplicar para
		# que las terminales abiertas carguen los ficheros de fuente nuevos
		actual=$(comoUsuario "$quien" "${lanzador[@]}" gsettings get "$ruta" font 2>> "$registro" | tr -d "'")
		[[ -z "$actual" ]] && return 0
		comoUsuario "$quien" "${lanzador[@]}" gsettings set "$ruta" font 'Monospace 11' >> "$registro" 2>&1
		sleep 2
		comoUsuario "$quien" "${lanzador[@]}" gsettings set "$ruta" font "$actual" >> "$registro" 2>&1
	fi
}

# Instala las herramientas de invitado segun el hipervisor: portapapeles
# compartido, arrastrar archivos, carpetas compartidas y ajuste de pantalla
function instalarHerramientasVM(){
	local quien="$1"
	case "$(systemd-detect-virt 2> /dev/null)" in
		vmware)
			echo -e "\n\t${grayColor}Máquina virtual ${purpleColor}VMware${endColor}${grayColor} detectada, instalando sus herramientas${endColor}\n"
			instalar open-vm-tools open-vm-tools-desktop
			systemctl enable --now open-vm-tools >> "$registro" 2>&1
			# Carpetas compartidas del anfitrion en /mnt/hgfs
			mkdir -p /mnt/hgfs
			if ! grep -q "vmhgfs-fuse" /etc/fstab
			then
				echo ".host:/ /mnt/hgfs fuse.vmhgfs-fuse defaults,allow_other,nofail 0 0" >> /etc/fstab
			fi
			mountpoint -q /mnt/hgfs || mount /mnt/hgfs >> "$registro" 2>&1
		;;
		oracle)
			echo -e "\n\t${grayColor}Máquina virtual ${purpleColor}VirtualBox${endColor}${grayColor} detectada, instalando sus herramientas${endColor}\n"
			instalar virtualbox-guest-utils virtualbox-guest-x11
			# Las carpetas compartidas solo las pueden leer los miembros de vboxsf
			getent group vboxsf &> /dev/null && usermod -aG vboxsf "$quien" >> "$registro" 2>&1
		;;
	esac
}

function compilarPolybar(){
	echo -e "\n\t${yellowColor}[!] polybar no está en los repositorios, se compilará desde el código fuente${endColor}\n"
	instalar "${dependenciasPolybar[@]}"
	rm -rf /opt/polybar &> /dev/null
	git clone --depth 1 --recursive https://github.com/polybar/polybar.git /opt/polybar >> "$registro" 2>&1 &&
	mkdir -p /opt/polybar/build &&
	cd /opt/polybar/build &&
	cmake .. >> "$registro" 2>&1 &&
	make -j"$(nproc)" >> "$registro" 2>&1 &&
	make install >> "$registro" 2>&1
	cd "$rutaPrograma" || exit 1
}

# configurarZsh (usuario) (estilo) -> estilo 1: powerlevel10k, estilo 2: parrot, estilo 3: minimal
function configurarZsh(){
	local quien="$1" estilo="$2" casa grupo
	casa=$(getent passwd "$quien" | cut -d: -f6)
	grupo=$(id -gn "$quien")

	if [[ -f "$casa/.zshrc" ]]
	then
		cp -f "$casa/.zshrc" "$casa/.zshrc.bak"
		chown "$quien:$grupo" "$casa/.zshrc.bak"
	fi

	if [[ "$estilo" == "2" ]]
	then
		if [[ ! -f "$casa/.oh-my-zsh/oh-my-zsh.sh" ]]
		then
			rm -rf "$casa/.oh-my-zsh" 2> /dev/null
			if ! comoUsuario "$quien" git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$casa/.oh-my-zsh" >> "$registro" 2>&1
			then
				echo -e "\n\t${redColor}[*] No se pudo descargar oh my zsh para $quien (¿hay conexión a internet?)${endColor}"
				fallos+=("oh-my-zsh ($quien)")
				return 1
			fi
		fi
		mkdir -p "$casa/.oh-my-zsh/custom/themes"
		cp "$rutaPrograma/zsh/parrot.zsh-theme" "$casa/.oh-my-zsh/custom/themes/parrot.zsh-theme"
		chown -hR "$quien:$grupo" "$casa/.oh-my-zsh/custom/themes"
		cp "$rutaPrograma/zsh/.zshrc-parrot" "$casa/.zshrc"
	elif [[ "$estilo" == "3" ]]
	then
		if [[ ! -f "$casa/.local/share/zinit/zinit.git/zinit.zsh" ]]
		then
			rm -rf "$casa/.local/share/zinit/zinit.git" 2> /dev/null
			comoUsuario "$quien" mkdir -p "$casa/.local/share/zinit"
			if ! comoUsuario "$quien" git clone --depth 1 https://github.com/zdharma-continuum/zinit.git "$casa/.local/share/zinit/zinit.git" >> "$registro" 2>&1
			then
				echo -e "\n\t${redColor}[*] No se pudo descargar zinit para $quien (¿hay conexión a internet?)${endColor}"
				fallos+=("zinit ($quien)")
				return 1
			fi
		fi
		cp "$rutaPrograma/zsh/.zshrc-minimal" "$casa/.zshrc"
		cp "$rutaPrograma/zsh/.p10k-minimal.zsh" "$casa/.p10k.zsh"
		chown "$quien:$grupo" "$casa/.zshrc" "$casa/.p10k.zsh"
		# Primera carga: zinit descarga aquí los plugins para que la shell abra ya lista
		echo -e "\n\t${grayColor}Descargando plugins de zsh para ${endColor}${purpleColor}$quien${endColor}${grayColor}....${endColor}"
		(cd "$casa" && comoUsuario "$quien" env "HOME=$casa" TERM=xterm-256color timeout 300 zsh -ic exit) >> "$registro" 2>&1 < /dev/null
		if [[ ! -d "$casa/.local/share/zinit/plugins/romkatv---powerlevel10k" ]]
		then
			echo -e "\n\t${yellowColor}[!] No se pudieron descargar todos los plugins de $quien; se descargarán al abrir la shell${endColor}"
		fi
	else
		if [[ ! -f "$casa/powerlevel10k/powerlevel10k.zsh-theme" ]]
		then
			rm -rf "$casa/powerlevel10k" 2> /dev/null
			if ! comoUsuario "$quien" git clone --depth 1 https://github.com/romkatv/powerlevel10k.git "$casa/powerlevel10k" >> "$registro" 2>&1
			then
				echo -e "\n\t${redColor}[*] No se pudo descargar powerlevel10k para $quien (¿hay conexión a internet?)${endColor}"
				fallos+=("powerlevel10k ($quien)")
				return 1
			fi
		fi
		cp "$rutaPrograma/zsh/.zshrc" "$casa/.zshrc"
		cp "$rutaPrograma/zsh/.p10k.zsh" "$casa/.p10k.zsh"
		chown "$quien:$grupo" "$casa/.p10k.zsh"
	fi
	chown "$quien:$grupo" "$casa/.zshrc"

	#CONFIGURAR TEMA LSD
	copiarConfig lsd "$quien" "$casa"

	if ! usermod -s "$(command -v zsh)" "$quien" >> "$registro" 2>&1
	then
		echo -e "\n\t${redColor}[*] No se pudo cambiar la shell de inicio de $quien${endColor}"
		fallos+=("shell de inicio ($quien)")
		return 1
	fi
	if [[ "$quien" != "root" ]]
	then
		configurarTerminal "$quien"
	fi
	echo -e "\n\t${greenColor}Shell zsh configurada en ${endColor}${grayColor}$quien${endColor} ${greenColor}✔${endColor}"
	return 0
}

function resumenFallos(){
	if [[ ${#fallos[@]} -gt 0 ]]
	then
		echo -e "\n\t${yellowColor}[!] No se pudo instalar: ${endColor}${grayColor}${fallos[*]}${endColor}"
		echo -e "\t${yellowColor}    Detalles en ${endColor}${grayColor}$registro${endColor}"
	fi
}

function preguntarReinicio(){
	tput cnorm
	echo -e "\n\t${greenColor}¿Desea reiniciar el equipo para guardar cambios?${endColor}${blueColor} (yes, no)${endColor}"
	read -r -p "$espacio" reiniciar
	if esAfirmativo "$reiniciar"
	then
		systemctl reboot
	else
		echo
	fi
}

function helpPanel(){
		clear
		echo -e "\n${blueColor}	▄▄▄▄▄            ▄▄▌      ·▄▄▄▄  ▄▄▄ ..▄▄ · ▪   ▄▄ •  ▐ ▄ ${endColor}"
		echo -e "${blueColor}	•██  ▪     ▪     ██•      ██▪ ██ ▀▄.▀·▐█ ▀. ██ ▐█ ▀ ▪•█▌▐█${endColor}"
		echo -e "${blueColor}	 ▐█.▪ ▄█▀▄  ▄█▀▄ ██▪      ▐█· ▐█▌▐▀▀▪▄▄▀▀▀█▄▐█·▄█ ▀█▄▐█▐▐▌${endColor}"
		echo -e "${blueColor}	 ▐█▌·▐█▌.▐▌▐█▌.▐▌▐█▌▐▌    ██. ██ ▐█▄▄▌▐█▄▪▐█▐█▌▐█▄▪▐███▐█▌${endColor}"
		echo -e "${blueColor}	 ▀▀▀  ▀█▄▀▪ ▀█▄▀▪.▀▀▀     ▀▀▀▀▀•  ▀▀▀  ▀▀▀▀ ▀▀▀·▀▀▀▀ ▀▀ █▪${endColor}  ${purpleColor}Diseñado por David Ojeda${endColor}\n\n"
		echo -e "\t${turquoiseColor}Instrucciones de uso:${endColor}\n"
		echo -e "\t\t${yellowColor}[*]${endColor} ${grayColor}$0 (opción)${endColor}\n"
		echo -e "\t\t    ${purpleColor}1)${endColor}  ${grayColor}Configurar entorno de escritorio${endColor}"
		echo -e "\t\t    ${purpleColor}2)${endColor}  ${grayColor}Cambiar fondo de pantalla${endColor}"
		echo -e "\t\t    ${purpleColor}3)${endColor}  ${grayColor}Configurar shell zsh personalizada${endColor}"
		echo -e "\t\t    ${purpleColor}4)${endColor}  ${grayColor}Configurar grub${endColor}"
		echo -e "\t\t    ${purpleColor}5)${endColor}  ${grayColor}Instalar y configurar oh my tmux${endColor}"
		echo -e "\t\t    ${purpleColor}6)${endColor}  ${grayColor}Salir${endColor}\n"
		read -r -p "$prompt" opcion
}


helpPanel
case $opcion in
	1)
		actualizarRepositorios
		pedirUsuario "Introduce nombre de usuario en el que configurar el escritorio"
		grupo=$(id -gn "$usuario")

		echo -e "\n\t${grayColor}Instalando ${purpleColor}bspwm${endColor}${grayColor}, ${endColor}${purpleColor}sxhkd${endColor} ${grayColor}y sus ${endColor}${purpleColor}dependencias${endColor}${endColor}\n"
		tput civis
		instalar "${dependenciasBspwm[@]}"

		# El compositor se llama picom en los sistemas actuales y compton en los antiguos
		if ! estaInstalado picom && ! estaInstalado compton
		then
			if apt-cache show picom &> /dev/null
			then
				instalar picom
			else
				instalar compton
			fi
		else
			echo -e "\tcompositor ${blueColor}instalado${endColor}"
		fi

		echo -e "\n\t${turquoiseColor}Porfavor sea paciente, pronto todo estara listo...${endColor}\n"
		instalar "${dependenciasOpcionales[@]}"

		instalarHerramientasVM "$usuario"

		if ! command -v bspwm &> /dev/null || ! command -v sxhkd &> /dev/null
		then
			tput cnorm
			echo -e "\n\t${redColor}[*] No se pudo instalar bspwm o sxhkd, revisa tu conexión y los repositorios${endColor}"
			echo -e "\t${redColor}    Detalles en ${endColor}${grayColor}$registro${endColor}\n"
			exit 1
		fi
		echo -e "\n\t${greenColor}Dependencias instaladas ✔${endColor}\n"

		sleep 0.5
		echo -e "\t${turquoiseColor}Configurando archivo .xinitrc${endColor}\n"
		echo "sxhkd &" > "$homeUsuario/.xinitrc"
		echo "exec bspwm" >> "$homeUsuario/.xinitrc"
		chown -h "$usuario:$grupo" "$homeUsuario/.xinitrc"

		sleep 0.3
		echo -e "\n\t${grayColor}Moviendo archivo sxhkd configurado....${endColor}"
		copiarConfig sxhkd "$usuario" "$homeUsuario"

		sleep 0.3
		echo -e "\n\t${grayColor}Moviendo archivos bspwm configurados....${endColor}"
		copiarConfig bspwm "$usuario" "$homeUsuario"
		chmod +x "$homeUsuario/.config/bspwm/bspwmrc" "$homeUsuario"/.config/bspwm/scripts/*
		# El fondo se guarda aparte para conservar el que se elija con la opción 2
		mkdir -p "$homeUsuario/.config/personalizador"
		if [[ ! -f "$homeUsuario/.config/personalizador/wallpaper" ]]
		then
			cp "$rutaPrograma/background.png" "$homeUsuario/.config/personalizador/wallpaper"
		fi
		chown -hR "$usuario:$grupo" "$homeUsuario/.config/personalizador"

		sleep 0.3
		echo -e "\n\t${grayColor}Moviendo archivos picom configurados....${endColor}"
		copiarConfig picom "$usuario" "$homeUsuario"
		rm -rf "$homeUsuario/.config/compton" 2> /dev/null

		echo -e "\n\t${grayColor}Instalando ${purpleColor}polybar${endColor}${grayColor} y sus ${endColor}${purpleColor}dependecias${endColor}${endColor}\n"
		if ! command -v polybar &> /dev/null
		then
			if apt-cache show polybar &> /dev/null
			then
				instalar polybar
			fi
			if ! command -v polybar &> /dev/null
			then
				compilarPolybar
			fi
		fi
		if command -v polybar &> /dev/null
		then
			echo -e "\tpolybar ${blueColor}instalado${endColor} ${grayColor}($(polybar --version | head -n 1))${endColor}"
		else
			echo -e "\tpolybar ${redColor}no se pudo instalar${endColor}"
			fallos+=("polybar")
		fi

		#VERSIÓN 2 # Incluye personalización en el lanzador de aplicaciónes
		echo -e "\n\t${grayColor}Configurando lanzador....${endColor}"
		copiarConfig rofi "$usuario" "$homeUsuario"

		# Caja solo se anuncia para el escritorio MATE: esta entrada la muestra en el lanzador
		if command -v caja &> /dev/null
		then
			mkdir -p "$homeUsuario/.local/share/applications"
			cp "$rutaPrograma/applications/caja-browser.desktop" "$homeUsuario/.local/share/applications/"
			chown "$usuario:$grupo" "$homeUsuario/.local" "$homeUsuario/.local/share" "$homeUsuario/.local/share/applications" "$homeUsuario/.local/share/applications/caja-browser.desktop"
		fi

		echo -e "\n\t${grayColor}Configurando fuentes....${endColor}"
		instalarFuentes
		configurarTerminal "$usuario"
		sleep 0.5

		echo -e "\n\t${grayColor}Moviendo archivos polybar configurados....${endColor}"
		copiarConfig polybar "$usuario" "$homeUsuario"
		chmod +x "$homeUsuario/.config/polybar/launch.sh" "$homeUsuario"/.config/polybar/scripts/*
		sleep 0.5

		echo -e "\n\t${grayColor}Configurando ultimos ajustes${endColor}\n"
		# Restos de las versiones anteriores, que compilaban bspwm y sxhkd en el home
		rm -rf "$homeUsuario/bspwm" "$homeUsuario/sxhkd" &> /dev/null
		# Si el usuario ya está dentro de bspwm se recarga para aplicar los cambios
		if pgrep -u "$usuario" -x bspwm &> /dev/null
		then
			pkill -u "$usuario" -x "picom|compton" &> /dev/null
			sleep 1
			comoUsuario "$usuario" env "XDG_RUNTIME_DIR=/run/user/$(id -u "$usuario")" "DISPLAY=${DISPLAY:-:0}" bspc wm -r >> "$registro" 2>&1
		fi

		resumenFallos
		echo -e "\n\t${greenColor}[*] Escritorio configurado.${endColor} ${grayColor}Elige la sesión${endColor} ${purpleColor}bspwm${endColor} ${grayColor}en la pantalla de inicio de sesión${endColor}"
		preguntarReinicio
	;;

	2)
		clear
		echo
		echo -e "${blueColor}	    ▐                       ▐           ▐                         ▐ ${endColor}"
		echo -e "${blueColor}	 ▄▖ ▐▗▖  ▄▖ ▗▗▖  ▄▄  ▄▖     ▐▄▖  ▄▖  ▄▖ ▐ ▗  ▄▄  ▖▄  ▄▖ ▗ ▗ ▗▗▖  ▄▟ ${endColor}"
		echo -e "${blueColor}	▐▘▝ ▐▘▐ ▝ ▐ ▐▘▐ ▐▘▜ ▐▘▐     ▐▘▜ ▝ ▐ ▐▘▝ ▐▗▘ ▐▘▜  ▛ ▘▐▘▜ ▐ ▐ ▐▘▐ ▐▘▜ ${endColor}"
		echo -e "${blueColor}	▐   ▐ ▐ ▗▀▜ ▐ ▐ ▐ ▐ ▐▀▀     ▐ ▐ ▗▀▜ ▐   ▐▜  ▐ ▐  ▌  ▐ ▐ ▐ ▐ ▐ ▐ ▐ ▐ ${endColor}"
		echo -e "${blueColor}	▝▙▞ ▐ ▐ ▝▄▜ ▐ ▐ ▝▙▜ ▝▙▞     ▐▙▛ ▝▄▜ ▝▙▞ ▐ ▚ ▝▙▜  ▌  ▝▙▛ ▝▄▜ ▐ ▐ ▝▙█ ${endColor}"
		echo -e "${blueColor}			 ▖▐                          ▖▐                     ${endColor}"
		echo -e "${blueColor}			 ▝▘                          ▝▘       ${endColor}\n\n"

		pedirUsuario "¿A que usuario en entorno bspwm quieres cambiarle el fondo de pantalla?"
		if [[ ! -f "$homeUsuario/.config/bspwm/bspwmrc" ]]
		then
			echo -e "\n\t${redColor}[*] El usuario $usuario no tiene el entorno bspwm configurado, usa antes la opción 1${endColor}\n"
			exit 1
		fi
		echo -e "\n\t${grayColor}Introduce la ruta absoluta de una imagen${endColor}"
		read -r -e -p "$espacio" rutaimagen
		if [[ ! -f "$rutaimagen" ]] || ! file -b --mime-type "$rutaimagen" | grep -q "^image/"
		then
			echo -e "\n\t${redColor}[*] La ruta introducida no es una imagen válida${endColor}\n"
			exit 1
		fi
		mkdir -p "$homeUsuario/.config/personalizador"
		cp -f "$rutaimagen" "$homeUsuario/.config/personalizador/wallpaper"
		chown -hR "$usuario:$(id -gn "$usuario")" "$homeUsuario/.config/personalizador"
		# Si el usuario está dentro de bspwm el fondo se cambia al momento
		if pgrep -u "$usuario" -x bspwm &> /dev/null
		then
			comoUsuario "$usuario" env "DISPLAY=${DISPLAY:-:0}" "XAUTHORITY=$homeUsuario/.Xauthority" feh --no-fehbg --bg-fill "$homeUsuario/.config/personalizador/wallpaper" >> "$registro" 2>&1
		fi
		echo -e "\n\t${greenColor}[*] ${endColor}${greenColor}El fondo de pantalla se a modificado correctamente${endColor}\n"

	;;

	3)
		clear
		echo
		echo -e "\n${blueColor}		     ▗▀  ▝                              ▐   ${endColor}"
		echo -e "${blueColor}	 ▄▖  ▄▖ ▗▗▖ ▗▟▄ ▗▄   ▄▄ ▗ ▗  ▖▄  ▄▖     ▗▄▄  ▄▖ ▐▗▖ ${endColor}"
		echo -e "${blueColor}	▐▘▝ ▐▘▜ ▐▘▐  ▐   ▐  ▐▘▜ ▐ ▐  ▛ ▘▐▘▐       ▞ ▐ ▝ ▐▘▐ ${endColor}"
		echo -e "${blueColor}	▐   ▐ ▐ ▐ ▐  ▐   ▐  ▐ ▐ ▐ ▐  ▌  ▐▀▀      ▞   ▀▚ ▐ ▐ ${endColor}"
		echo -e "${blueColor}	▝▙▞ ▝▙▛ ▐ ▐  ▐  ▗▟▄ ▝▙▜ ▝▄▜  ▌  ▝▙▞     ▐▄▄ ▝▄▞ ▐ ▐ ${endColor}"
		echo -e "${blueColor}			     ▖▐                             ${endColor}"
		echo -e "${blueColor}			     ▝▘                             ${endColor}\n"

		echo -e "\t${grayColor}¿Qué estilo de shell quieres?${endColor}\n"
		echo -e "\t    ${purpleColor}1)${endColor}  ${grayColor}Powerlevel10k${endColor} ${blueColor}(por defecto)${endColor}"
		echo -e "\t    ${purpleColor}2)${endColor}  ${grayColor}Parrot style${endColor}  ${redColor}┌─[${endColor}usuario${yellowColor}@${endColor}${turquoiseColor}equipo${endColor}${redColor}]─[${endColor}${greenColor}~${endColor}${redColor}]${endColor}"
		echo -e "\t    ${purpleColor}3)${endColor}  ${grayColor}Minimal${endColor}       ${blueColor}~${endColor} ${purpleColor}❯${endColor}\n"
		while true
		do
			read -r -p "$espacio" estilo || exit 1
			estilo=${estilo:-1}
			[[ "$estilo" == [123] ]] && break
			echo -e "\n\t${redColor}[*] Elige 1, 2 o 3${endColor}\n"
		done
		nombresEstilo=("" "Powerlevel10k" "Parrot style" "Minimal")

		pedirUsuario "¿En que usuario desea instalar la shell zsh?" permitirRoot
		usuarios=("$usuario")
		if [[ "$usuario" == "root" ]]
		then
			# Se repite hasta recibir un usuario válido o una respuesta vacía
			while true
			do
				echo -e "\n\t${grayColor}Introduce otro usuario aparte de ${redColor}root${endColor}${grayColor} (vacío para ninguno)${endColor}"
				read -r -p "$espacio" otro || exit 1
				if [[ -z "$otro" || "$otro" == "root" ]]
				then
					break
				elif id "$otro" &> /dev/null && [[ -d "$(getent passwd "$otro" | cut -d: -f6)" ]]
				then
					usuarios+=("$otro")
					break
				fi
				echo -e "\n\t${redColor}[*] El usuario ${endColor}${grayColor}$otro${endColor}${redColor} no existe${endColor}"
			done
		else
			echo -e "\n\t${grayColor}Quieres instalar también una shell zsh en el usuario ${redColor}root${endColor}${grayColor} (yes, no)${endColor}"
			read -r -p "$espacio" condicion || exit 1
			esAfirmativo "$condicion" && usuarios+=("root")
		fi
		echo -e "\n\t${grayColor}Se instalará el estilo ${endColor}${purpleColor}${nombresEstilo[$estilo]}${endColor}${grayColor} en: ${endColor}${purpleColor}${usuarios[*]}${endColor}"

		tput civis
		actualizarRepositorios
		tput civis
		echo -e "\t${purpleColor}[*] ${grayColor}Realizando preparaciones${endColor}${endColor}\n"
		instalar "${dependenciasZsh[@]}"
		if ! command -v zsh &> /dev/null
		then
			tput cnorm
			echo -e "\n\t${redColor}[*] No se pudo instalar zsh, revisa tu conexión y los repositorios${endColor}"
			echo -e "\t${redColor}    Detalles en ${endColor}${grayColor}$registro${endColor}\n"
			exit 1
		fi
		# En Debian el comando bat se llama batcat
		if ! command -v bat &> /dev/null && command -v batcat &> /dev/null
		then
			ln -sf "$(command -v batcat)" /usr/local/bin/bat
		fi
		echo -e "\n\t${purpleColor}[*] ${grayColor}Configurando plugins${endColor}${endColor}\n"
		rm -rf /usr/share/zsh-sudo 2> /dev/null
		cp -r "$rutaPrograma/plugin/zsh-sudo" /usr/share
		chmod -R a+rX /usr/share/zsh-sudo
		echo -e "\t${purpleColor}[*] ${grayColor}Mejorando el diseño${endColor}${endColor}\n"
		instalarFuentes
		echo -e "\t${purpleColor}[*] ${grayColor}Espere unos momentos....${endColor}${endColor}"

		configurados=()
		for quien in "${usuarios[@]}"
		do
			configurarZsh "$quien" "$estilo" && configurados+=("$quien")
		done

		resumenFallos
		if [[ ${#configurados[@]} -eq 0 ]]
		then
			tput cnorm
			echo -e "\n\t${redColor}[*] No se pudo configurar la shell en ningún usuario. Detalles en ${endColor}${grayColor}$registro${endColor}\n"
			exit 1
		fi
		echo -e "\n\t${greenColor}Completado en: ${configurados[*]}${endColor} ${grayColor}Cierra sesión y vuelve a entrar para usar la nueva shell${endColor}"
		preguntarReinicio
	;;
	4)
		clear
		echo -e "\n${blueColor}		    ▐        ▝           ▗      ▝▜  ▝▜          ${endColor}"
		echo -e "${blueColor}	 ▄▄  ▖▄ ▗ ▗ ▐▄▖     ▗▄  ▗▗▖  ▄▖ ▗▟▄  ▄▖  ▐   ▐   ▄▖  ▖▄ ${endColor}"
		echo -e "${blueColor}	▐▘▜  ▛ ▘▐ ▐ ▐▘▜      ▐  ▐▘▐ ▐ ▝  ▐  ▝ ▐  ▐   ▐  ▐▘▐  ▛ ▘${endColor}"
		echo -e "${blueColor}	▐ ▐  ▌  ▐ ▐ ▐ ▐      ▐  ▐ ▐  ▀▚  ▐  ▗▀▜  ▐   ▐  ▐▀▀  ▌  ${endColor}"
		echo -e "${blueColor}	▝▙▜  ▌  ▝▄▜ ▐▙▛     ▗▟▄ ▐ ▐ ▝▄▞  ▝▄ ▝▄▜  ▝▄  ▝▄ ▝▙▞  ▌  ${endColor}"
		echo -e "${blueColor}	 ▖▐                                                     ${endColor}"
		echo -e "${blueColor}	 ▝▘                       ${endColor}"

		echo -e "\n\t${greenColor}Se instalará un tema para el grub. Porfavor espere....${endColor}"
		tput civis
		if bash "$rutaPrograma/grub/install.sh" >> "$registro" 2>&1
		then
			echo -e "\n\t${purpleColor}[*] ${endColor}${grayColor}Felicidades!! ${endColor}"
			echo -e "\t${purpleColor}[*] ${endColor}${grayColor}Tema${endColor} ${turquoiseColor}TELA${endColor} ${grayColor}instalado con exito${endColor}\n"
		else
			echo -e "\n\t${redColor}[*] No se pudo instalar el tema del grub. Detalles en ${endColor}${grayColor}$registro${endColor}\n"
		fi
		tput cnorm
	;;
	5)
		clear
		echo -e "${blueColor}	    ▐                    ▗              ${endColor}"
		echo -e "${blueColor}	 ▄▖ ▐▗▖     ▗▄▄ ▗ ▗     ▗▟▄ ▗▄▄ ▗ ▗ ▗ ▗ ${endColor}"
		echo -e "${blueColor}	▐▘▜ ▐▘▐     ▐▐▐ ▝▖▞      ▐  ▐▐▐ ▐ ▐  ▙▌ ${endColor}"
		echo -e "${blueColor}	▐ ▐ ▐ ▐     ▐▐▐  ▙▌      ▐  ▐▐▐ ▐ ▐  ▟▖ ${endColor}"
		echo -e "${blueColor}	▝▙▛ ▐ ▐     ▐▐▐  ▜       ▝▄ ▐▐▐ ▝▄▜ ▗▘▚ ${endColor}"
		echo -e "${blueColor}			 ▞                      ${endColor}"
		echo -e "${blueColor}			▝▘                      ${endColor}\n"

		pedirUsuario "¿En que usuario deseas aplicar esta configuración?" permitirRoot
		tput civis
		echo -e "\n\t${purpleColor}[*] ${endColor}${grayColor}Instalando ${endColor}${yellowColor}tmux${endColor}\n"
		instalar tmux git
		if [[ ! -f "$homeUsuario/.tmux/.tmux.conf" ]]
		then
			rm -rf "$homeUsuario/.tmux" 2> /dev/null
			comoUsuario "$usuario" git clone --depth 1 https://github.com/gpakosz/.tmux.git "$homeUsuario/.tmux" >> "$registro" 2>&1
		fi
		tput cnorm
		if [[ -f "$homeUsuario/.tmux/.tmux.conf" ]] && command -v tmux &> /dev/null
		then
			comoUsuario "$usuario" ln -s -f .tmux/.tmux.conf "$homeUsuario/.tmux.conf"
			[[ -f "$homeUsuario/.tmux.conf.local" ]] || comoUsuario "$usuario" cp "$homeUsuario/.tmux/.tmux.conf.local" "$homeUsuario/"
			echo -e "\n\t${greenColor}[*] Tmux fue instalado y configurado con exito! ${endColor}\n"
		else
			echo -e "\n\t${redColor}[*] No se pudo instalar oh my tmux (¿hay conexión a internet?). Detalles en ${endColor}${grayColor}$registro${endColor}\n"
		fi
	;;

	*)
		echo -e "\n\t${redColor}[*]${endColor} ${redColor}Saliendo....${endColor}\n\n"
		exit 1

esac
