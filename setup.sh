#!/system/bin/sh
DEFAULTSHELL=$(echo $1 | rev | cut -d'/' -f1 | rev)
PACKAGES="git clang neovim python2 python clang nodejs zsh perl curl wget"

checkStatus() {
	if [ $1 -ne 0 ]; then
		exit 1
	fi
}

# prepare folders
mkdir -p ~/.config/nvim

# initialize
apt-get update -y
apt-get upgrade -y

# packages
dpkg -s $PACKAGES > /dev/null
if [ $? -ne 0 ]; then
	printf "installing packages"
	apt-get install -y $PACKAGES
	checkStatus $?
fi

# terminal setups

if [ "$DEFAULTSHELL" = "zsh" ]; then
	printf "zsh is default!\n"
else
	chsh -s zsh
	printf "reboot terminal and run again\n"
	exit 0
fi
#ohmyzsh
if [ -d ~/.oh-my-zsh ]; then
	printf "oh-my-zsh is installed\n"
 else
	 sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
#powerlevel10k
rmdir ~/.oh-my-zsh/custom/themes/powerlevel10k 2> /dev/null
#if [ $? -eq 0 ]; then
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
#fi

#avoid overwrite
cp -n ~/.zshrc ~/.zshrc.bak 
cat ~/.zshrc.bak > ~/.zshrc
sed -i 's/ZSH_THEME=.*$/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc

# pip
pip3 install pynvim

# nvim
#plug vim
sh -c 'curl --no-progress-meter -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

cp -f config/init.vim ~/.config/nvim/init.vim

printf "done. restart your terminal.\n"
