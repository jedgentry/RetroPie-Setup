#! /usr/bin/env bash

rp_module_id="gcdrv"
rp_module_desc="Install gamecube adapter driver"
rp_module_menus="3+"
rp_module_flags="nobin"

function install_gcdrv() {
	apt-get install libusb-dev
	apt-get install git 
	git fetch git://github.com/ToadKing/wii-u-gc-adapter
	cd wii-u-gc-adapter/
	gcc wii-u-gc-adapter.c -o gcdrv
	chmod +x gcdrv
	mkdir ~/gcdrv
	mv gcdrv ~/gcdrv
	echo "start on startup\ntask\nexec ~/gcdrv" >> gcdrv.conf
	mv gcdrv.conf /etc/init/gcdrv.conf 
}
