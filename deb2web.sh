#! /bin/bash
########################################################################
# deb2web builds the 2web PPA for updating the repository
# Copyright (C) 2023  Carl J Smith
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
########################################################################
function main(){
	if [ "$1" == "-d" ] || [ "$1" == "--download" ] || [ "$1" == "download" ] ;then
		################################################################################
		# Add all git repos for software to be packaged for the repo here
		################################################################################
		mkdir -p "./source/2web/"
		# clone repo if it is not there
		# or
		# pull any changes
		sudo git clone "https://github.com/dude56987/2web.git" "./source/2web/" || sudo git -C "./source/2web/" pull
	elif [ "$1" == "-b" ] || [ "$1" == "--build" ] || [ "$1" == "build" ] ;then
		################################################################################
		# Add build instructions for each package in the repo here.
		################################################################################
		# build the source code into a package for use in the repository.
		sudo mkdir -p "./repo/"
		# make the build
		sudo make -C "./source/2web" build
		# get the version number
		version=$(dpkg-deb -I "./source/2web/2web_UNSTABLE.deb" | grep "Version:" | tr -d ' ' | cut -d':' -f2)
		# copy the build over to this directory for use in the ppa
		cp -v "./source/2web/2web_UNSTABLE.deb" "./repo/2web_v$version.deb"
		# set permissions of the repo files to world readable so webserver can host files
		sudo chmod -R ugo+r ./repo/
		# make the current user the owner
		sudo chown -R $USERNAME:$USERNAME ./repo/
	elif [ "$1" == "-s" ] || [ "$1" == "--scan" ] || [ "$1" == "scan" ] ;then
		################################################################################
		# Scan the repo for new packages and rebuild all gpg signatures
		################################################################################
		githubUsername="$2"
		repoName="$3"
		mkdir -p "./repo/"
		gpgEmail="$githubUsername@users.noreply.github.com"

		# export public key file to repo for users using the key to verify packages in the repo
		#gpg --armor --export "$gpgEmail" > ./repo/KEY.gpg
		# export key without armor for usage
		gpg --export "$gpgEmail" > ./$repoName.gpg
		find "./repo/" -name '*.deb' | uniq | while read packageName;do
			# check the integrity of the package
			if dpkg-sig --verify "$packageName" | grep -q "NOSIG";then
				echo "The package '$packageName' has not been signed, Signing the package..."
				# sign the package if no signiture was found on the package
				# - this will prevent signed packages from being resigned
				dpkg-sig --sign builder "$packageName"
			else
				echo "The package has been signed '$packageName'..."
			fi
		done

		# generate the packages file, remove prefix path
		dpkg-scanpackages --multiversion ./repo/ | sed "s/\.\/repo\///g" > ./repo/Packages

		# compress the packages file
		gzip -k --best -f ./repo/Packages
		# build the release files
		apt-ftparchive release ./repo/ > ./repo/Release

		# sign the packages in the repo
		gpg --default-key "$gpgEmail" -abs -o - ./repo/Release > ./repo/Release.gpg
		gpg --default-key "$gpgEmail" --clearsign -o - ./repo/Release > ./repo/InRelease

		echo "You must update the repo with git commit and git push in order to see"
		echo "changes on the repo online"
		# generate the .list file for the repo
		echo "deb [signed-by=/etc/apt/trusted.gpg.d/$repoName.gpg] https://$githubUsername.github.io/$repoName/repo/ ./" > ./$repoName.list
		# update the readme
		{
			echo "# 2web Debian & Ubuntu Repo"
			echo ""
			echo "This is the repo for updating ubuntu and debian versions of 2web with APT"
			echo ""
			echo "## Install the Repo"
			echo ""
			echo ""
			# download and store the public key as a trusted key
			echo "	sudo curl -SsL --compressed -o '/etc/apt/trusted.gpg.d/$repoName.gpg' 'https://$githubUsername.github.io/$repoName/$repoName.gpg'"
			# download and store the list file
			echo "	sudo curl -SsL --compressed -o '/etc/apt/sources.list.d/$repoName.list' 'https://$githubUsername.github.io/$repoName/$repoName.list'"
			echo "	sudo apt update"
			echo ""
			echo ""
			echo "Or if you use wget instead of curl"
			echo ""
			echo ""
			# wget variant of above commands
			echo "	sudo wget -q -O '/etc/apt/trusted.gpg.d/$repoName.gpg' 'https://$githubUsername.github.io/$repoName/$repoName.gpg'"
			echo "	sudo wget -q -O '/etc/apt/sources.list.d/$repoName.list' 'https://$githubUsername.github.io/$repoName/$repoName.list'"
			echo "	sudo apt update"
			echo ""
			echo "## Uninstall the Repo"
			echo ""
			echo "To manually remove the repo use the below commands"
			echo ""
			echo "	sudo rm -v '/etc/apt/trusted.gpg.d/$repoName.gpg'"
			echo "	sudo rm -v '/etc/apt/sources.list.d/$repoName.list'"
			echo ""
			echo "To remove all the packages from this repo use the below command"
			echo ""
			# read all the existing packages in the repo
			cat "./repo/Packages" | tr -d ' ' | grep "Package:" | cut -d':' -f2 | uniq | while read packageTitle;do
				# create a link to the package name on the github username
				echo "	sudo apt-get purge '$packageTitle'"
			done
			echo ""
			echo "## Packages"
			echo ""
			# read all the existing packages in the repo
			find "./repo/" -name '*.deb' | uniq | sort -r | while read packageName;do
				version=$(dpkg-deb -I "${packageName}" | tr -d ' ' | grep "Version:" | cut -d':' -f2 )
				packageTitle=$(dpkg-deb -I "${packageName}" | tr -d ' ' | grep "Package:" | cut -d':' -f2 )
				# create a link to the package name on the github username
				echo "- [$packageTitle](https://github.com/$githubUsername/$packageTitle/) v$version"
			done
			echo ""
			echo "## License"
			echo ""
			echo "- [GPLv3](./LICENSE)"
			echo ""
		} > "README.md"
	elif [ "$1" == "-c" ] || [ "$1" == "--create-key" ] || [ "$1" == "create-key" ];then
		################################################################################
		# Create a gpg key to be used here
		################################################################################
		# - MUST use the github username noreply email
		githubUsername="$2"
		gpgEmail="$githubUsername@users.noreply.github.com"
		# build a new gpg key if one does not exist for signing the software
		echo "################################################################################"
		echo "- Use the largest available encryption for your PPA repo"
		echo "- Do not set a expiration date."
		echo "- Your email will be used to identify your local gpg key for backup"
		echo "################################################################################"
		echo "Create A Key with the following properties"
		echo "################################################################################"
		echo "- NAME: $githubUsername"
		echo "- COMMENT: Repo Key"
		echo "- EMAIL: $gpgEmail"
		echo "- ENCRYPTION: RSA and RSA"
		echo "- ENCRYPTION BITS: 4096"
		echo "################################################################################"
		echo "Leave the passwords blank for these gpg keys"
		echo "################################################################################"
		echo "- You can use the application seahorse in order to build and manage your keys  "
		echo "  with a graphical interface."
		echo "################################################################################"
		gpg --full-gen-key
	elif [ "$1" == "-i" ] || [ "$1" == "--install" ] || [ "$1" == "install" ];then
		repoName="$2"
		# install git repo to local machine
		sudo cp -v ./${repoName}.list /etc/apt/sources.list.d/${repoName}.list
		sudo cp -v ./${repoName}.gpg /etc/apt/trusted.gpg.d/${repoName}.gpg
	elif [ "$1" == "-u2" ] || [ "$1" == "--uninstall-local-2web" ] || [ "$1" == "uninstall-local-2web" ];then
		repoName="$2"
		# install the repo to the local machine, repo is also hosted on local machine
		sudo rm -v "/etc/apt/sources.list.d/${repoName}_2web.list"
		sudo rm -v "/etc/apt/trusted.gpg.d/${repoName}.gpg"
	elif [ "$1" == "-2" ] || [ "$1" == "--install-local-2web" ] || [ "$1" == "install-local-2web" ];then
		# install to the local 2web instance, for hosting repo and install as a usable repo on local machine
		repoName="$2"
		# create the ppa directory
		sudo mkdir -p /var/cache/2web/web/kodi/ppa/

		# copy the repo files to the local 2web server
		sudo cp -v ./repo/Release /var/cache/2web/web/kodi/ppa/
		sudo cp -v ./repo/Release.gpg /var/cache/2web/web/kodi/ppa/
		sudo cp -v ./repo/InRelease /var/cache/2web/web/kodi/ppa/
		sudo cp -v ./repo/Packages /var/cache/2web/web/kodi/ppa/

		find "./repo/" -name '*.deb' | uniq | while read packageName;do
				# copy the package over to the local server
				sudo cp -v "$packageName" /var/cache/2web/web/kodi/ppa/
		done
		# use mdns to host on the local machine
		{
			echo "deb [signed-by=/etc/apt/trusted.gpg.d/$repoName.gpg] http://$(hostname).local/kodi/ppa/ ./"
		} > "./${repoName}_2web.list"

		# update the readme
		{
			echo "# 2web Debian & Ubuntu Repo"
			echo ""
			echo "This is the repo for updating ubuntu and debian versions of 2web with APT"
			echo ""
			echo "## Install the Repo"
			echo ""
			echo ""
			# download and store the public key as a trusted key
			echo "	sudo curl -SsL --compressed -o '/etc/apt/trusted.gpg.d/$repoName.gpg' 'https://$(hostname).local/kodi/ppa/$repoName.gpg'"
			# download and store the list file
			echo "	sudo curl -SsL --compressed -o '/etc/apt/sources.list.d/$repoName.list' 'https://$(hostname).local/kodi/ppa/$repoName.list'"
			echo "	sudo apt update"
			echo ""
			echo ""
			echo "Or if you use wget instead of curl"
			echo ""
			echo ""
			# wget variant of above commands
			echo "	sudo wget -q -O '/etc/apt/trusted.gpg.d/$repoName.gpg' 'https://$(hostname).local/kodi/ppa/$repoName.gpg'"
			echo "	sudo wget -q -O '/etc/apt/sources.list.d/$repoName.list' 'https://$(hostname).local/kodi/ppa/$repoName.list'"
			echo "	sudo apt update"
			echo ""
			echo ""
			echo "## Uninstall the Repo"
			echo ""
			echo "To manually remove the repo use the below commands"
			echo ""
			echo "	sudo rm -v '/etc/apt/trusted.gpg.d/$repoName.gpg'"
			echo "	sudo rm -v '/etc/apt/sources.list.d/$repoName.list'"
			echo ""
			echo "To remove all the packages from this repo use the below command"
			echo ""
			# read all the existing packages in the repo
			cat "./repo/Packages" | tr -d ' ' | grep "Package:" | cut -d':' -f2 | uniq | while read packageTitle;do
				# create a link to the package name on the github username
				echo "	sudo apt-get purge '$packageTitle'"
			done
			echo ""
			echo "## Packages"
			echo ""
			# read all the existing packages in the repo
			find "./repo/" -name '*.deb' | uniq | sort -r | while read packageName;do
				version=$(dpkg-deb -I "${packageName}" | tr -d ' ' | grep "Version:" | cut -d':' -f2 )
				packageTitle=$(dpkg-deb -I "${packageName}" | tr -d ' ' | grep "Package:" | cut -d':' -f2 )
				# create a link to the package name on the github username
				echo "- [$packageTitle](http://$(hostname).local/repos/$packageTitle/) v$version"
			done
			echo ""
			echo "## License"
			echo ""
			echo "- [GPLv3](./LICENSE)"
			echo ""
		} > "/var/cache/2web/web/kodi/ppa/README.md"
		# create a readme webpage in the repo directory
		{
			echo "<html>"
			echo "<head>"
			echo "<script src='/2webLib.js'></script>"
			echo "<link rel='stylesheet' type='text/css' href='/style.css'>"
			echo "<link rel='icon' type='image/png' href='/favicon.png'>"
			echo "</head>"
			echo "<body>"
			echo "<?PHP"
			echo "include('/usr/share/2web/templates/header.php');"
			echo "?>"
			echo "<div class='titleCard'>"
			markdown "/var/cache/2web/web/kodi/ppa/README.md"
			echo "</div>"
			echo "<script>CreateCopyButtons();</script>";
			echo "<?PHP"
			echo "include('/usr/share/2web/templates/footer.php');"
			echo "?>"
			echo "</body>"
			echo "</html>"
		} > "/var/cache/2web/web/kodi/ppa/index.php"
		# install the repo to the local machine, repo is also hosted on local machine
		sudo cp -v ./${repoName}_2web.list /etc/apt/sources.list.d/${repoName}_2web.list
		sudo cp -v ./${repoName}.gpg /etc/apt/trusted.gpg.d/${repoName}.gpg
	elif [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$1" == "help" ];then
		echo "################################################################################"
		echo "HELP"
		echo "################################################################################"
		echo ""
		echo "--create-key"
		echo ""
		echo "	Generate a new GPG key. This must be setup before a scan will complete"
		echo "	correctly. Key must use github noreply email."
		echo ""
		echo "--download
		echo ""
		echo "	Download or pull updates for software packages in repository."
		echo ""
		echo "--build
		echo ""
		echo "	Build all packages in the repository."
		echo ""
		echo "--scan \$github_username \$github_project_name"
		echo ""
		echo "	Read all of the packages and rebuild the repository information."
		echo ""
		echo "--install-local-2web"
		echo ""
		echo "Can be added to commands to build the repo for a local 2web server"
		echo ""
		echo "################################################################################"
	else
		# default action
		echo "################################################################################"
		echo "This is deb2web for building a ppa from a github repo"
		echo "################################################################################"
		echo "Use --help in order to see help options."
	fi
}
################################################################################
main "$@"
exit
