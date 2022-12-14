#!/system/bin/sh
DEFAULTSHELL=$(echo $1 | rev | cut -d'/' -f1 | rev)
PACKAGES="git clang neovim python2 python clang nodejs zsh perl curl wget kotlin gradle exiftool radare2"
PKG_ESSENTIALS=""
MBINPATH=$(echo $PATH | cut -d":" -f1)
PYMODS="pynvim"
COUNTER=0

inf() {
	echo "\033[0;92m$1\033[0;0m"
	sleep 0.5
}

err() {
	echo "\033[0;91m$1\033[0;0m"
	sleep 0.5
}

# prepare folders
mkdir -p ~/.config/nvim

#START
inf "SETUP: Starting setup..."
if [ -z $1 ]; then
	err "SETUP: run this file again as \nsh setup.sh \$0"
	exit 1
fi
# UPGRADES
prepUpgrade() {
	apt-get upgrade -y && apt-get update -y
}

# SPECIFIC INITS
prepInits() {
	if echo $PREFIX | grep com.termux &> /dev/null; then
		inf "INIT (TERMUX): Checking for permission"
		if ! touch /sdcard/.tmp; then
			inf "INIT (TERMUX): Requesting permission..."
			termux-setup-storage
		else 
			inf "INIT (TERMUX): Permission already granted!"
		fi
		rm -rf /sdcard/.tmp &> /dev/null
	fi
}

# PACKAGES
prepPackages() {
	COUNTER=$(expr $COUNTER + 1)
	if [ $COUNTER -lt 1 ]; then
		inf "PACKAGES: installing user-defined packages"
	elif [ $COUNTER -le 3 ]; then
		inf "PACKAGES: retry installing user-defined packages"
	else
		err "PACKAGES: too many errors! fix your mirrors!"
		exit 1
	fi

	if ! dpkg -s $PACKAGES &> /dev/null; then
		if ! apt-get install -y $PACKAGES; then
			if echo $PREFIX | grep com.termux &> /dev/null; then
				termux-change-repo
				prepPackages
			else
				inf "PACKAGES: manually change mirror and try again!\n"
				exit 1
			fi
		fi
	fi

}

# TERMINAL
prepTerminal() {
	if [ "$DEFAULTSHELL" = "zsh" ]; then
		inf "TERMINAL: Success changing to zsh!"
	else
		chsh -s zsh
		inf "TERMINAL: Done setting terminal. Run script again.\nsh setup.sh \$0"
		export SETUPJUMPFLAG=true
		exec zsh
	fi
}

#OHMYZSH
prepOmz() {
	VERIFYOMZ=$(echo $ZSH | rev | cut -d'/' -f1 | rev)

	if [ -d ~/.oh-my-zsh ]; then
		if [ "$VERIFYOMZ" = ".oh-my-zsh" ]; then
			inf "OMZ: ohmyzsh exist or installed!"
		fi
	 else
		inf "OMZ: Installing oh-my-zsh, wait a while..."
		sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && prepOmz
	fi
}

#p10k
prepP10k() {
	if [ -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]; then
		inf "P10K: powerlevel10k exist or installed!"
		inf "P10K: Dynamically modifying theme..."
		cp -n ~/.zshrc ~/.zshrc.bak 
		# to avoid triggering p10k config if there is existing setuo
		touch -r ~/.zshrc ~/.zshrc.bak
		cat ~/.zshrc.bak > ~/.zshrc
		sed -i 's/ZSH_THEME=.*$/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc
		# to avoid triggering p10k config
		touch -r ~/.zshrc.bak ~/.zshrc
		inf "P10K: Theme applied!"
	else
		inf "P10K: Installing powerlevel10k. wait a while..."
		git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k\
			&& prepP10k
	fi
}

#PIP
prepPIP() {
	inf "PIP: upgrading pip..."
	if pip install --upgrade pip; then
		inf "PIP: pip upgraded! installing python modules..."
		pip3 install $PYMODS
	else
		err "PIP: retry upgrading pip..."
		prepPIP
	fi
}

#NVIM
prepNvim() {
	#vimplug
	if [ -f ~/.local/share/nvim/site/autoload/plug.vim ]; then
		inf "NVIM: plug.vim exist or installed!"
		cp -f config/init.vim ~/.config/nvim/init.vim
		nvim +PlugInstall +qall && nvim +PlugUpgrade +qall && nvim +CocInstall coc-clangd +CocInstall coc-kotlin +CocInstall coc-clang-format-style-options  +CocInstall coc-prettier +CocInstall coc-highlight +CocInstall coc-sh +qall && nvim +"TSUpdate" && nvim +"TSInstall kotlin cl"
		
		inf "NVIM: copied init.vim configuration!"
	else
		inf "NVIM: Installing plug.vim..., wait a while..."
		sh -c 'curl --no-progress-meter -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim' && prepNvim
	fi
}

prepMake() {

	inf "BUILD: Starting build..."
	inf "BUILD: building maxcso..."
	if ! which maxcso &> /dev/null; then
		git clone https://github.com/unknownbrackets/maxcso.git\
			&& (cd $PWD/maxcso && make)\
			&& (cd $PWD/maxcso && mv maxcso $MBINPATH)
		if [ $? -eq 0 ]; then
			inf "BUILD: \"maxcso\" build success"
		else
			err "BUILD: \"maxcso\" build failed!"
		fi
		inf "BUILD: cleaning up..."
		rm -rf "$PWD/maxcso/"
	else
		inf "BUILD: \"maxcso\" already installed!"
	fi
}

# main
main() {
	if ! [ $SETUPJUMPFLAG ]; then
		prepUpgrade
		prepInits
		prepPackages
	fi
	prepTerminal
	prepOmz
	prepP10k
	prepPIP
	prepNvim
	prepMake
	inf "SETUP: Done setting up! Restart your terminal."
}

main
