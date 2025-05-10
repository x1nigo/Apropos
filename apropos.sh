#!/usr/bin/env bash

# Apropos - A simple, post-arch, bash installer script for my configuration
# files and system setup.
# Chris Iñigo <https://github.com/x1nigo>

### GENERAL VARIABLES ###

dotfilesrepo="https://github.com/x1nigo/dotfiles.git"
export TERM=ansi

### FUNCTIONS ###

installpkg() {
	pacman --noconfirm --needed -S "$1" >/dev/null 2>&1
}

error() {
	printf "%s\n" "$1" >&2
	exit 1
}

welcomemsg() {
	clear
	echo "#####################################################################"
	echo "Welcome! This script should be able to install my configuration files"
	echo "for Arch Linux. - CB2"
	echo " "
	echo "WARNING: This should be run as root - preferrably on a fresh install."
	echo "#####################################################################"
	echo " "
	echo "Press Enter/Return to continue."
	read -r enter
}

getuserandpass() {
	clear
	echo "Please enter a username (only lowercase letters)."
	printf "Username: "
	read -r name
	echo "Next, your password for this account."
	printf "Password: "
	read -r pass
}

adduserandpass() {
	useradd -m -g wheel "$name"
	echo "$name:$pass" | chpasswd
	unset pass
	srcdir="/home/$name/.local/src"
	echo "%wheel ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/temp
	sudo -u "$name" mkdir -p "$srcdir"
}

maininstall() {
	clear
	echo "Installing \`$1\` ($n of $total). $2."
	installpkg "$1"
}

installationloop() {
	total=$(wc -l < progs.csv)
	while IFS=, read -r program comment; do
		n=$((n + 1))
		maininstall "$program" "$comment"
	done < progs.csv
}

installconfig() {
	clear
	echo "Installing configuration files..."
	sudo -u "$name" git -C "$srcdir" clone "$dotfilesrepo" >/dev/null 2>&1
	# Install dwm and other suckless software.
	for i in $(echo "dwm st dmenu dwmblocks"); do
		sudo -u "$name" git -C "$srcdir" clone "https://github.com/x1nigo/$i.git" >/dev/null 2>&1
		cd "$srcdir"/"$i" && make clean install >/dev/null 2>&1
	done
	cd "$srcdir"
	# Transfer ".local" and ".config" files to their respective locations.
	shopt -s dotglob
	sudo -u "$name" mv -f .local/* /home/$name/.local/
	[ -d /home/$name/.config ] && {
		sudo -u "$name" mv -f .config/* /home/$name/.config/
	} || sudo -u "$name" mv -f .config /home/$name/
	chmod -R +x /home/$name/.local/bin
	# Enable tap to click and natural scrolling.
	[ ! -f /etc/X11/xorg.conf.d/40-libinput.conf ] && printf 'Section "InputClass"
		Identifier "libinput touchpad catchall"
		MatchIsTouchpad "on"
		MatchDevicePath "/dev/input/event*"
		Driver "libinput"
	# Enable left mouse button by tapping
	Option "Tapping" "on"
	Option "NaturalScrolling" "on"
EndSection' >/etc/X11/xorg.conf.d/40-libinput.conf
	# Make pacman look good.
	grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
}

resetpermissions() {
	rm -f /etc/sudoers.d/temp
	echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/00-wheel-sudo
}

exitmsg() {
	clear
	echo "#####################################################################"
	echo "Done! You now have a fully functioning Arch Linux desktop which you"
	echo "may now use as your daily driver."
	echo " "
	echo "Provided that there were no hidden errors, you're good to go! And"
	echo "even if there were, I'm sure you'll find a way to make this work."
	echo "- CB2"
	echo "#####################################################################"
	echo " "
	echo "Press Enter/Return to reboot the system."
	read -r enter
	reboot
}

### EXECUTION PHASE ###

welcomemsg || error "User exited."
getuserandpass || error "User exited."
adduserandpass || error "User exited."
installationloop || error "User exited."
installconfig || error "User exited."
resetpermissions || error "User exited."
exitmsg
