#!/usr/bin/env bash

# This file is part of RetroPie.
# 
# (c) Copyright 2012-2015  Florian Müller (contact@petrockblock.com)
# 
# See the LICENSE.md file at the top-level directory of this distribution and 
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="dosbox"
rp_module_desc="DOS emulator"
rp_module_menus="2+"
rp_module_flags="dispmanx"

function depends_dosbox() {
    getDepends libsdl1.2-dev libsdl-net1.2-dev libsdl-sound1.2-dev libasound2-dev libpng12-dev automake autoconf zlib1g-dev
}

function sources_dosbox() {
    wget -O- -q http://downloads.petrockblock.com/retropiearchives/dosbox-r3876.tar.gz | tar -xvz --strip-components=1
}

function build_dosbox() {
    ./autogen.sh
    ./configure --prefix="$md_inst" --disable-opengl
    # enable dynamic recompilation for armv4
    sed -i 's|/\* #undef C_DYNREC \*/|#define C_DYNREC 1|' config.h
    if isPlatform "rpi2" || isPlatform "odroid"; then
        sed -i 's/C_TARGETCPU.*/C_TARGETCPU ARMV7LE/g' config.h
        sed -i 's|/\* #undef C_UNALIGNED_MEMORY \*/|#define C_UNALIGNED_MEMORY 1|' config.h
    else
        sed -i 's/C_TARGETCPU.*/C_TARGETCPU ARMV4LE/g' config.h
    fi
    make clean
    make
    md_ret_require="$md_build/src/dosbox"
}

function install_dosbox() {
    make install
    md_ret_require="$md_inst/bin/dosbox"
}

function configure_dosbox() {
    mkRomDir "pc"

    rm -f "$romdir/pc/Start DOSBox.sh"
    cat > "$romdir/pc/+Start DOSBox.sh" << _EOF_
#!/bin/bash
params="\$1"
if [[ "\$params" =~ "+Start DOSBox.sh" ]]; then
    params="-c \"MOUNT C $romdir/pc\""
elif [[ "\$params" =~ \.sh$ ]]; then
    bash "\$params"
    exit
else
    params+=" -exit"
fi
$rootdir/supplementary/runcommand/runcommand.sh 0 "$md_inst/bin/dosbox \$params" "$md_id"
_EOF_
    chmod +x "$romdir/pc/+Start DOSBox.sh"
    chown $user:$user "$romdir/pc/+Start DOSBox.sh"

    mkUserDir "$configdir/pc/"

    # move any old configs to the new location
    if [[ -d "$home/.dosbox" && ! -h "$home/.dosbox" ]]; then
        mv "$home/.dosbox/"* "$configdir/pc/"
        rmdir "$home/.dosbox"
    fi
    ln -snf "$configdir/pc" "$home/.dosbox"

    local config_path=$(su "$user" -c "\"$md_inst/bin/dosbox\" -printconf")
    if [[ -f "$config_path" ]]; then
        iniConfig "=" "" "$config_path"
        iniSet "usescancodes" "false"
        iniSet "core" "dynamic"
        iniSet "cycles" "max"
        iniSet "scaler" "none"
    fi

    # slight hack so that we set dosbox as the default emulator for "+Start DOSBox.sh"
    iniConfig "=" '"' "$configdir/all/emulators.cfg"
    iniSet "ab19770b84adcb74b0044f78b79000379" "dosbox"
    chown $user:$user "$configdir/all/emulators.cfg"

    addSystem 1 "$md_id" "pc" "$romdir/pc/+Start\ DOSBox.sh %ROM%" "" ".sh"
}

