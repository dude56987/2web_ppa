# 2web Debian & Ubuntu Repo

This is the repo for updating ubuntu and debian versions of 2web with APT

## Install the Repo


	sudo curl -SsL --compressed -o '/etc/apt/trusted.gpg.d/2web_ppa.gpg' 'https://dude56987.github.io/2web_ppa/repo/KEY.gpg'
	sudo curl -SsL --compressed -o '/etc/apt/sources.list.d/2web_ppa.list' 'https://dude56987.github.io/2web_ppa/2web_ppa.list'
	sudo apt update


Or if you use wget instead of curl


	sudo wget -q -O '/etc/apt/trusted.gpg.d/2web_ppa.gpg' 'https://dude56987.github.io/2web_ppa/repo/KEY.gpg'
	sudo wget -q -O '/etc/apt/sources.list.d/2web_ppa.list' 'https://dude56987.github.io/2web_ppa/2web_ppa.list'
	sudo apt update


## Packages

- [2web](https://github.com/dude56987/2web/)

## License

- [GPLv3](./LICENSE)

