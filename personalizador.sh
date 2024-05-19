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
	echo -e "\n\n\t${redColor}[*] Saliendo....${endColor}"
	exit 1
}

rutaPrograma=$(pwd)

espacio=$(echo -e "\t")

prompt=$(echo -e "\t${redColor}root@$(hostnamectl | head -n1 | xargs |cut -d' ' -f3) #${endColor}  ${grayColor}$0 ${endColor}")

dependenciasBspwm=(bspwm compton wmname feh rofi gnome-terminal caja git libxcb-xinerama0-dev libxcb-icccm4-dev libxcb-randr0-dev libxcb-util0-dev libxcb-ewmh-dev libxcb-keysyms1-dev libxcb-shape0-dev)

dependenciasPolybar=(libxcb-xkb-dev libxcb-xrm-dev libxcb-cursor-dev libasound2-dev libpulse-dev i3-wm libjsoncpp-dev libmpdclient-dev libcurl4-openssl-dev libnl-genl-3-dev build-essential cmake cmake-data pkg-config python3-sphinx libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev python3-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev)

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
		read -p "$prompt" opcion
}

		
if [ "$(id -u)" == "0" ]
then
	helpPanel
	case $opcion in
		1)	
		tput civis
		echo -e "\n\t${purpleColor}[*] Actualizando repositorios....${endColor}\n"	
		apt update -y &> /dev/null
		tput cnorm
		echo -e "\n\t${grayColor}Introduce nombre de usuario en el que configurar el escritorio${endColor}" 
		read -p "$espacio" usuario
		if [[ "$usuario" == "root" ]]
		then
			echo -e "\n\t${redColor}[*] El usuario no debe ser root, crea un usuario con adduser${endColor}\n"
			exit 1
		
		else
		echo -e "\n\t${grayColor}Instalando ${purpleColor}bspwm${endColor}${grayColor}, ${endColor}${purpleColor}sxhkd${endColor} ${grayColor}y sus ${endColor}${purpleColor}dependencias${endColor}${endColor}\n"
		tput civis
		for i in ${dependenciasBspwm[@]}
		do
			apt install "$i" -y &>/dev/null
			echo -e "\t$i ${blueColor}instalado${endColor}"
		done
		echo -e "\n\t${turquoiseColor}Porfavor sea paciente, pronto todo estara listo...${endColor}\n"
		cd /home/$usuario
		git clone https://github.com/baskerville/bspwm.git &> /dev/null
		git clone https://github.com/baskerville/sxhkd.git &> /dev/null
		cd bspwm && make > /dev/null 2>&1 && sudo make install > /dev/null 2>&1
		cd ../sxhkd && make > /dev/null 2>&1 && sudo make install > /dev/null 2>&1
		echo -e "\t${greenColor}Dependencias instaladas ✔${endColor}\n"
		fi
		sleep 0.5
		echo -e "\t${turquoiseColor}Configurando archivo .initrc${endColor}\n"
		if [[ -e /home/$usuario/.xinitrc ]]
		then
			echo "sxhkd &" > /home/$usuario/.xinitrc
			echo "exec bspwm" >> /home/$usuario/.xinitrc
			chown -hR $usuario:$usuario /home/$usuario/.xinitrc
			
		else
			touch /home/$usuario/.xinitrc
			echo "sxhkd &" > /home/$usuario/.xinitrc
			echo "exec bspwm" >> /home/$usuario/.xinitrc
			chown -hR $usuario:$usuario /home/$usuario/.xinitrc
		fi
		
		sleep 0.3
		echo -e "\n\t${grayColor}Moviendo archivo sxhkd configurado....${yellowColor}"
		if [[ -d /home/$usuario/.config/sxhkd ]]
		then
			rm -rf /home/$usuario/.config/sxhkd 2> /dev/null
			cp -r $rutaPrograma/sxhkd /home/$usuario/.config/
			cat $rutaPrograma/sxhkd/sxhkdrc | sed "s/david/$usuario/g" > /home/$usuario/.config/sxhkd/sxhkdrc
			
		else
			cp -r $rutaPrograma/sxhkd /home/$usuario/.config/
			cat $rutaPrograma/sxhkd/sxhkdrc | sed "s/david/$usuario/g" > /home/$usuario/.config/sxhkd/sxhkdrc
		fi
		
		sleep 0.3
		echo -e "\n\t${grayColor}Moviendo archivos bspwm configurados....${yellowColor}"
		if [[ -d /home/$usuario/.config/bspwm ]]
		then
			rm -rf /home/$usuario/.config/bspwm 2> /dev/null
			cp -r $rutaPrograma/bspwm /home/$usuario/.config/
			cat $rutaPrograma/bspwm/bspwmrc | sed "s/david/$usuario/g" > /home/$usuario/.config/bspwm/bspwmrc
		else
			cp -r $rutaPrograma/bspwm /home/$usuario/.config/
			cat $rutaPrograma/bspwm/bspwmrc | sed "s/david/$usuario/g" > /home/$usuario/.config/bspwm/bspwmrc
		fi
		
		sleep 0.3
		echo -e "\n\t${grayColor}Moviendo archivos compton configurados....${yellowColor}"
		if [[ -d /home/$usuario/.config/compton ]]
		then
			rm -rf /home/$usuario/.config/compton 2> /dev/null
			cp -r $rutaPrograma/compton /home/$usuario/.config/
			chmod +x /home/$usuario/.config/compton/compton.conf
		else
			cp -r $rutaPrograma/compton /home/$usuario/.config/
			chmod +x /home/$usuario/.config/compton/compton.conf
		fi
		
		echo -e "\n\t${grayColor}Instalando ${purpleColor}polybar${endColor}${grayColor} y sus ${endColor}${purpleColor}dependecias${endColor}${endColor}\n"
		for a in ${dependenciasPolybar[@]}
		do
			apt install "$a" -y &>/dev/null
			echo -e "\t$a ${blueColor}instalado${endColor}"
			
		done
		
		echo -e "\n\t${grayColor}Configurando polybar....${endColor}\n"
		cd /opt
		rm -rf polybar &> /dev/null
		git clone https://github.com/polybar/polybar.git --recursive &>/dev/null
		cd polybar
		mkdir build 2>/dev/null 
		cd build
		cmake .. &> /dev/null
		make -j$(nproc) 2> /dev/null
		make install &> /dev/null

		#VERSIÓN 2 # Incluye personalización en el lanzador de aplicaciónes
  		echo -e "\n\t${grayColor}Configurando lanzador....${yellowColor}"
		mkdir /home/$usuario/.config/rofi &>/dev/null
		git clone https://github.com/newmanls/rofi-themes-collection/  /home/$usuario/.local/share/rofi &>/dev/null
		echo "@theme \"/home/$usuario/.local/share/rofi/themes/rounded-purple-dark.rasi\"" > /home/$usuario/.config/rofi/config.rasi
		
		
		echo -e "\n\t${grayColor}Configurando fuentes....${endColor}"
		cp -r $rutaPrograma/fonts /usr/local/share/fonts
		sleep 0.5
		
		echo -e "\n\t${grayColor}Moviendo archivos polybar configurados....${yellowColor}"
		if [[ -d /home/$usuario/.config/polybar ]]
		then
			rm -rf /home/$usuario/.config/polybar 2> /dev/null
			cp -r $rutaPrograma/polybar /home/$usuario/.config/
		else
			cp -r $rutaPrograma/polybar /home/$usuario/.config/
		fi
		sleep 0.5
		echo -e "\n\t${grayColor}Configurando ultimos ajustes${endColor}\n"
		chown -hR $usuario:$usuario /home/$usuario/.config
  		chown -hR $usuario:$usuario /home/$usuario/.local
		chown -hR $usuario:$usuario /home/$usuario/bspwm
		chown -hR $usuario:$usuario /home/$usuario/sxhkd
		tput cnorm
		echo -e "\n\t${greenColor}¿Desea reiniciar el equipo para guardar cambios?${endColor}${blueColor} (yes, no)${endColor}"
		read -p "$espacio" reiniciar
		if [[ "$reiniciar" == "yes" ]]
		then				
			init 6
		else
			echo
		fi
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
		
		nivelar=$(echo -e "\t")
		echo -e "\t${grayColor}¿A que usuario en entorno bspwm quieres cambiarle el fondo de pantalla?${endColor}"
		read -p "$nivelar" usuario
		echo -e "\n"
		echo -e "\t${grayColor}Introduce la ruta absoluta de una imagen${endColor}" 
		read -p "$nivelar" rutaimagen
		cat $rutaPrograma/bspwm/bspwmrc | sed "s/david/$usuario/g"| sed "/feh/c\feh --bg-fill $rutaimagen" > /home/$usuario/.config/bspwm/bspwmrc
		chown -hR $usuario:$usuario /home/$usuario/.config/bspwm/bspwmrc
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
		
		tabulador=$(echo -e "\t")
		
		tput civis
		echo -e "\t${purpleColor}[*] ${grayColor}Realizando preparaciones${endColor}${endColor}\n"
		apt install zsh -y &> /dev/null
		echo -e "\t${purpleColor}[*] ${grayColor}Configurando plugins${endColor}${endColor}\n"
		apt install zsh-autosuggestions -y &> /dev/null
		apt install zsh-syntax-highlighting -y &> /dev/null
		cp -r $rutaPrograma/plugin/zsh-sudo /usr/share
		echo -e "\t${purpleColor}[*] ${grayColor}Mejorando el diseño${endColor}${endColor}\n"
		echo -e "\t\t${blueColor}[*] ${grayColor}Comando ${redColor}ls${endColor}${endColor}${endColor}\n"
		#wget https://github.com/Peltoche/lsd/releases/download/0.17.0/lsd_0.17.0_amd64.deb &> /dev/null
		#dpkg -i lsd_0.17.0_amd64.deb &> /dev/null
		#rm lsd_0.17.0_amd64.deb &> /dev/null
  		apt install lsd &> /dev/null
		echo -e "\t\t${blueColor}[*] ${grayColor}Comando ${redColor}cat${endColor}${endColor}${endColor}\n"
		wget https://github.com/sharkdp/bat/releases/download/v0.13.0/bat_0.13.0_amd64.deb &> /dev/null
		dpkg -i bat_0.13.0_amd64.deb &> /dev/null
		rm bat_0.13.0_amd64.deb &> /dev/null
		echo -e "\t\t${blueColor}[*] ${grayColor}Utilidad ${redColor}fzf${endColor}${endColor}${endColor}\n"
		apt install fzf -y &> /dev/null
		
		echo -e "\t${purpleColor}[*] ${grayColor}Espere unos momentos....${endColor}${endColor}\n"
		tput cnorm
		echo -e "\t${grayColor}¿En que usuario desea instalar la shell zsh?${endColor}"
		read -p "$tabulador" usuario
		if [[ "$usuario" == "root" ]]
		then 	
			# Usuario root
			tput civis
			cd /root
			git clone https://github.com/romkatv/powerlevel10k &> /dev/null
			cp $rutaPrograma/zsh/.zshrc /root
			cp $rutaPrograma/zsh/.p10k.zsh /root
			usermod -s /usr/bin/zsh root &> /dev/null
   			#CONFIGURAR TEMA LSD ROOT
      			cp -rf $rutaPrograma/lsd /root/.config &>/dev/null
			echo -e "\n\t${greenColor}Completado....${endColor}\n"
			tput cnorm
			#Usuario distinto de root 
			echo -e "\t${grayColor}Introduce otro usuario aparte de ${redColor}root${endColor}${endColor}"
			read -p "$tabulador" usuario
			tput civis
			cd /home/$usuario
			git clone https://github.com/romkatv/powerlevel10k &> /dev/null
			chown -hR $usuario:$usuario /home/$usuario/powerlevel10k
			cp $rutaPrograma/zsh/.zshrc /home/$usuario/
			cp $rutaPrograma/zsh/.p10k.zsh /home/$usuario/
			usermod -s /usr/bin/zsh $usuario &> /dev/null
   			#CONFIGURAR TEMA LSD USER
      			cp -rf $rutaPrograma/lsd /home/$usuario/.config &>/dev/null
	 		chown -hR $usuario:$usuario /home/$usuario/.config/lsd
			echo -e "\n\t${greenColor}Completado....${endColor}\n"
			tput cnorm
		else 
			echo -e "\t${grayColor}Quieres instalar también una shell zsh en el usuario ${redColor}root${endColor} (yes, no)${endColor}"
			read -p "$tabulador" condicion
			tput civis
			if [[  "$condicion" != "yes" ]]
			then
				tput civis
				cd /home/$usuario
				git clone https://github.com/romkatv/powerlevel10k &> /dev/null
				chown -hR $usuario:$usuario /home/$usuario/powerlevel10k
				cp $rutaPrograma/zsh/.zshrc /home/$usuario/
				cp $rutaPrograma/zsh/.p10k.zsh /home/$usuario/
				usermod -s /usr/bin/zsh $usuario &> /dev/null
    				#CONFIGURAR TEMA LSD USER
      				cp -rf $rutaPrograma/lsd /home/$usuario/.config &>/dev/null
	 			chown -hR $usuario:$usuario /home/$usuario/.config/lsd
				echo -e "\n\t${greenColor}Completado....${endColor}\n"
				tput cnorm
				
			else	
				tput civis
				cd /root
				git clone https://github.com/romkatv/powerlevel10k &> /dev/null
				cp $rutaPrograma/zsh/.zshrc /root
				cp $rutaPrograma/zsh/.p10k.zsh /root
				usermod -s /usr/bin/zsh root &> /dev/null
				#CONFIGURAR TEMA LSD ROOT
      				cp -rf $rutaPrograma/lsd /root/.config &>/dev/null
    
				
				cd /home/$usuario
				git clone https://github.com/romkatv/powerlevel10k &> /dev/null
				chown -hR $usuario:$usuario /home/$usuario/powerlevel10k
				cp $rutaPrograma/zsh/.zshrc /home/$usuario/
				cp $rutaPrograma/zsh/.p10k.zsh /home/$usuario/
				usermod -s /usr/bin/zsh $usuario &> /dev/null
    				#CONFIGURAR TEMA LSD USER
      				cp -rf $rutaPrograma/lsd /home/$usuario/.config &>/dev/null
	 			chown -hR $usuario:$usuario /home/$usuario/.config/lsd
				echo -e "\n\t${greenColor}Completado....${endColor}\n"
				tput cnorm

			fi
			
		fi
		
		tput cnorm
		echo -e "\n\t${greenColor}¿Desea reiniciar el equipo para guardar cambios?${endColor}${blueColor} (yes, no)${endColor}"
		read -p "$tabulador" reiniciar
		if [[ "$reiniciar" == "yes" ]]
		then				
			init 6
		else
			echo
		fi
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
		cd $rutaPrograma/grub
		./install.sh &> /dev/null
		echo -e "\n\t${purpleColor}[*] ${endColor}${grayColor}Felicidades!! ${endColor}"
		echo -e "\t${purpleColor}[*] ${endColor}${grayColor}Tema${endColor} ${turquoiseColor}TELA${endColor} ${grayColor}instalado con exito${endColor}\n"
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
		
		tput civis
		echo -e "\t${purpleColor}[*] ${endColor}${grayColor}Instalando ${endColor}${yellowColor}tmux${endColor}\n"
		apt install tmux -y &> /dev/null
		echo -e "\t${grayColor}¿En que usuario deseas aplicar esta configuración?${endColor}"
		tput cnorm
		read -p "$espacio" usuario
		cd /home/$usuario
		tput civis
		git clone https://github.com/gpakosz/.tmux.git &> /dev/null
		ln -s -f .tmux/.tmux.conf
		cp .tmux/.tmux.conf.local .
		tput cnorm
		echo -e "\n\t${greenColor}[*] Tmux fue instalado y configurado con exito! ${endColor}\n"
	;;
	
	*)
		echo -e "\n\t${redColor}[*]${endColor} ${redColor}Saliendo....${endColor}\n\n"
		exit 1
	
esac

else
	echo -e "\n${redColor}[*] Ejecuta este programa como root${endColor}\n"
fi 

