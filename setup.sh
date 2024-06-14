mkdir -p /home/vscode/.local/bin

DIFFT_VERSION="0.58.0"
if [ ! -f ~/.local/bin/difft ]; then
  echo "installing difftastic ${DIFFT_VERSION}"
  curl -Lo /tmp/difft.tar.gz https://github.com/Wilfred/difftastic/releases/download/${DIFFT_VERSION}/difft-x86_64-unknown-linux-gnu.tar.gz
  tar xvf /tmp/difft.tar.gz --directory ~/.local/bin
fi

curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin

echo 'eval "$(oh-my-posh --init --shell bash --config ~/.vityusha-ohmyposhv3-v2.json)"' >> ~/.bashrc

# Fonts
mkdir -p ~/.local/share/fonts
curl -Lo /tmp/Meslo.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Meslo.zip
unzip /tmp/Meslo.zip -d ~/.local/share/fonts
rm /tmp/Meslo.zip

mkdir -p ~/.config/Code/User
ln -sfv $PWD/settings.json ~/.config/Code/User/settings.json
ln -sfv $PWD/.gitconfig ~/.gitconfig
ln -sfv $PWD/.vityusha-ohmyposhv3-v2.json ~/.vityusha-ohmyposhv3-v2.json
ln -sfv $PWD/difftool.sh ~/difftool.sh
ln -sfv $PWD/gitconflict.sh ~/gitconflict.sh
ln -sfv $PWD/gitignore_global.txt ~/gitignore_global.txt
