#!/bin/bash
#
# @(#)Bootstrap macOS for software development.
# @(#)Usage: GITHUB_USER=[your_name] GITHUB_MAIL=[your_address] ./bootstrap.sh

# check variable
if [ -z "$GITHUB_USER" ]; then
  echo "GITHUB_USER is empty!" >&2
  exit 1
fi

if [ -z "$GITHUB_MAIL" ]; then
  echo "GITHUB_MAIL is empty!" >&2
  exit 1
fi

# define version
PYTHON2_VERSION=2.7.14
PYTHON3_VERSION=3.6.5
GO_VERSION=1.10.1
RUBY_VERSION=2.5.1
NODE_VERSION=8.11.1
JAVA_VERSION=8.0.163-zulu

# show command
set -x

# .bashrc & .bash_profile
touch ~/.bashrc
cat <<EOL >> ~/.bash_profile
if [ -f ~/.bashrc ] ; then
  . ~/.bashrc
fi
EOL

# generate ssh key
ssh-keygen -t rsa -b 4096 -C "github@example.com"

# Homebrew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# install tools
brew install wget
brew install tree
brew install jq
brew install mysql
brew install pwgen
brew install watch

# git
brew install git
git config --global user.name $GITHUB_USER
git config --global user.email $GITHUB_MAIL
git config --global credential.helper osxkeychain
git config --global rebase.autosquash true

# git-secrets
brew install git-secrets
git secrets --register-aws --global
git secrets --install ~/.git-templates/git-secrets
git config --global init.templatedir '~/.git-templates/git-secrets'

# direnv
brew install direnv
echo 'export EDITOR=vim' >> ~/.bashrc
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc

# anyenv
git clone https://github.com/riywo/anyenv ~/.anyenv
cat <<'EOL' >> ~/.bashrc
if [ -d $HOME/.anyenv ] ; then
    export PATH="$HOME/.anyenv/bin:$PATH"
    eval "$(anyenv init -)"
    # for tmux
    for D in `\ls $HOME/.anyenv/envs`
    do
        export PATH="$HOME/.anyenv/envs/$D/shims:$PATH"
    done
fi
EOL
source ~/.bashrc
mkdir -p $(anyenv root)/plugins
git clone https://github.com/znz/anyenv-update.git $(anyenv root)/plugins/anyenv-update

anyenv update
anyenv install pyenv
anyenv install goenv
anyenv install rbenv
anyenv install nodenv
source ~/.bashrc

# Python
pyenv install $PYTHON2_VERSION
pyenv install $PYTHON3_VERSION
pyenv global $PYTHON2_VERSION

git clone https://github.com/yyuu/pyenv-virtualenv.git $(pyenv root)/plugins/pyenv-virtualenv
echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
echo 'export PYENV_VIRTUALENV_DISABLE_PROMPT=1' >> ~/.bashrc

pip install --upgrade pip

# golang
goenv install $GO_VERSION
goenv global $GO_VERSION

# Ruby
rbenv install $RUBY_VERSION
rbenv global $RUBY_VERSION
rbenv exec gem install bundle --no-document
echo "gem: --no-document" > ~/.gemrc

# nodejs
nodenv install $NODE_VERSION
nodenv global $NODE_VERSION

# Java / Scala
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java $JAVA_VERSION
sdk install scala
sdk install sbt

# terraform
brew install tfenv
tfenv install latest

# AWS CLI
pip install awscli --upgrade
echo "complete -C '`which aws_completer`' aws"  >> $HOME/.bashrc

# Fabric
pip install fabric --upgrade

# configure .bashrc
cat <<'EOL' >> ~/.bashrc
# alias
alias gpush='git push origin `git rev-parse --abbrev-ref HEAD`'
alias gpd="git pull --rebase origin develop"
alias grd="git rebase develop"
alias gcd="git checkout develop"
alias gb='git branch'
alias gc='git checkout'
alias gco='git commit'
alias gcoa='git commit --allow-empty'

# git
source /usr/local/etc/bash_completion.d/git-prompt.sh
source /usr/local/etc/bash_completion.d/git-completion.bash
GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUPSTREAM=auto
export PS1='\[\033[32m\]\w\[\033[31m\]$(__git_ps1)\[\033[00m\]\$ '
EOL

# configure ssh
cat <<'EOL' >> ~/.ssh/config
Host *
  AddKeysToAgent yes
  UseKeychain yes
  ServerAliveInterval 60

Host github.com
  HostName github.com
  IdentityFile ~/.ssh/id_rsa
  User git
EOL

# cask
brew cask install google-japanese-ime
brew cask install google-chrome
brew cask install iterm2
brew cask install skitch
brew cask install dropbox
brew cask install atom
brew cask install docker
brew cask install intellij-idea
brew cask install kindle
brew cask install alfred
brew cask install spectacle
brew cask install mi
brew cask install flux
brew cask install dash
brew cask install clipy
brew cask install appcleaner
brew cask install cheatsheet
brew cask install freemind

# cleanup
brew upgrade --cleanup

# check install version
source ~/.bashrc
python --version
ruby --version
go version
node --version
java -version
scala -version
terraform --version
aws --version
fab --version
