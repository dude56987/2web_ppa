########################################################################
# deb2web makefile for building new versions of the repo
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
all: build
	# - this will fail if you have not built gpg keys with 'make keys'
	# - if you do not have the correct signing key this will also fail
	# scan for new debian files
	bash deb2web.sh --scan "dude56987" "2web_ppa"
	# display the ppa link
	#bash deb2web.sh --ppa "dude56987" "2web_ppa"
	# In order to use this in github you must
	# - enable github pages
	# - select the master branch as the source
build:
	bash deb2web.sh --download
	# build the package and copy it with correct name into top level of repo
	bash deb2web.sh --build
keys:
	bash deb2web.sh --create-key "dude56987"
install:
	# install the repo on to the current operating system
	sudo cp -v 2web_ppa.list /etc/apt/sources.list.d/2web_ppa.list
	sudo cp -v ./repo/KEY.gpg /etc/apt/trusted.gpg.d/2web_ppa.gpg
uninstall:
	# remove this repo from the system
	sudo rm -v /etc/apt/sources.list.d/2web_ppa.list
	sudo rm -v /etc/apt/trusted.gpg.d/2web_ppa.gpg
clean:
	# remove the repo itself to be regenerated with make
	sudo rm -rv ./repo/ || echo "No file to clean..."
	# remove the source directory for building packages
	sudo rm -rv ./source/ || echo "No file to clean..."
	sudo rm -v ./2web_ppa.list || echo "No file to clean..."
