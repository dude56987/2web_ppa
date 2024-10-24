# 2web Debian & Ubuntu Repo

This is the repo for updating ubuntu and debian versions of 2web with APT

## Install the Repo


	sudo curl -SsL --compressed -o '/etc/apt/trusted.gpg.d/2web_ppa.gpg' 'https://dude56987.github.io/2web_ppa/2web_ppa.gpg'
	sudo curl -SsL --compressed -o '/etc/apt/sources.list.d/2web_ppa.list' 'https://dude56987.github.io/2web_ppa/2web_ppa.list'
	sudo apt update


Or if you use wget instead of curl


	sudo wget -q -O '/etc/apt/trusted.gpg.d/2web_ppa.gpg' 'https://dude56987.github.io/2web_ppa/2web_ppa.gpg'
	sudo wget -q -O '/etc/apt/sources.list.d/2web_ppa.list' 'https://dude56987.github.io/2web_ppa/2web_ppa.list'
	sudo apt update

## Uninstall the Repo

To manually remove the repo use the below commands

	sudo rm -v '/etc/apt/trusted.gpg.d/2web_ppa.gpg'
	sudo rm -v '/etc/apt/sources.list.d/2web_ppa.list'

To remove all the packages from this repo use the below command

	sudo apt-get purge '2web'

## Packages

- [2web](https://github.com/dude56987/2web/) v1.0.0.824
- [2web](https://github.com/dude56987/2web/) v1.0.0.691
- [2web](https://github.com/dude56987/2web/) v1.0.0.685

## License

- [GPLv3](./LICENSE)

