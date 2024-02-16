mkdir -p /home/vscode/.local/bin

DIFFT_VERSION="0.55.0"
if [ ! -f ~/.local/bin/difft ]; then
    echo "installing difftastic ${DIFFT_VERSION}"
    curl -Lo /tmp/difft.tar.gz https://github.com/Wilfred/difftastic/releases/download/${DIFFT_VERSION}/difft-x86_64-unknown-linux-gnu.tar.gz
    tar xvf /tmp/difft.tar.gz --directory ~/.local/bin
fi

ln -sfv $PWD/.gitconfig ~/.gitconfig
ln -sfv $PWD/difftool.sh ~/difftool.sh
ln -sfv $PWD/gitconflict.sh ~/gitconflict.sh
ln -sfv $PWD/gitignore_global.txt ~/gitignore_global.txt
