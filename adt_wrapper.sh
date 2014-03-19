#!/bin/bash

#
# Author : peter.ducai@gmail.com 
# Homepage : 
# License : BSD http://en.wikipedia.org/wiki/BSD_license
# Copyright 2014, peter ducai
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met: 
# 
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer. 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution. 
# 3. Neither the name of the copyright holder nor the names of its contributors
#    may be used to endorse or promote products derived from this software without
#    specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Purpose : wrapper to automate Yocto ADT without user interaction
# Usage : run with --help parameter to see usage
#



#############################
# DEFAULT PARAMS from ADT   #
#############################

WRAPPER_VER="0.1"
NOW=$(date +"%s-%d-%m-%Y")
ADT_PATH="adt-installer"  # path to ADT installer
INSTALL_DIR="${HOME}/adt"

YOCTOADT_REPO="http://downloads.yoctoproject.org/releases/yocto/yocto-1.5.1/adt-installer"
YOCTOADT_TARGETS="arm"
YOCTOADT_QEMU="N"
YOCTOADT_NFS_UTIL="N"
YOCTOADT_ROOTFS_arch="skyboard-evb-sdk"
YOCTOADT_TARGET_SYSROOT_IMAGE_arch="skyboard-evb-sdk"
YOCTOADT_TARGET_MACHINE_arch="skyboard-evb"
YOCTOADT_TARGET_SYSROOT_LOC_arch="$HOME/yocto_sdk/sysroots/arm"


########################################
# FUNCTIONS                           
########################################

# print usage
usage() {

    echo -e "\n# USAGE ########################################\n"
    echo -e "adt_wrapper.sh --adt-path=\"adt-installer\" --package-system=\"ipk\" --install-path=\"${HOME}\" --target-arch=\"arm\" --target-machine=\"skyboard-evb\" --target-rootfs=\"skyboard-evb-sdk\" --sysroot-image=\"skyboard-evb-sdk\""
    echo -e "\nOPTIONS:"
    echo -e "[supported rootfs] minimal minimal-dev sato sato-dev sato-sdk lsb lsb-dev lsb-sdk"
    echo -e "[supported archs] x86 x86_64 arm ppc mips"
}

# process parameters from CLI
process_parameters() {
    # process parameters
    echo "processing paramaters"
    for i in "$@"
    do
    case "$i" in
    --package-system=*) echo -e"setting package manager"
        PACKAGE_MANAGERS=(${i#*=})
        CLI_ARGS="${CLI_ARGS} --set-package-system=\"${PACKAGE_MANAGERS[@]}\""
        ;;
    --install-path=*) INSTALL_DIR=${i#*=}
        echo -e "setting installation path to ${INSTALL_DIR}"
        CLI_ARGS="${CLI_ARGS} --install-path=\"${INSTALL_DIR}\"" 
        ;;
    --target-arch=*) YOCTOADT_TARGETS="${i#*=}"
        ;;
    --target-machine=*) YOCTOADT_TARGET_MACHINE_arch="${i#*=}"
        ;;
    --target-rootfs=*) YOCTOADT_ROOTFS_arch="${i#*=}"
        ;;
    --sysroot-image=*) YOCTOADT_TARGET_SYSROOT_IMAGE_arch="${i#*=}"
        ;;
    --sysroot-loc=*) export YOCTOADT_TARGET_SYSROOT_arm="${i#*=}"
        ;;
    --help) usage
        ;;
    *) echo "INVALID option!!!" 
        usage
        print_params
        exit
        ;;
    esac
    done
}


# write values into adt_installer.conf
write_adt_conf() {

    echo -e "backing up old adt_installer.conf"
    cp ${ADT_PATH}/adt_installer.conf ${ADT_PATH}/adt_installer.conf.backup
    
    echo -e "# generated with ADT Wrapper [${NOW}]" > ${ADT_PATH}/adt_installer.conf
    
    echo -e "YOCTOADT_REPO=\"${YOCTOADT_REPO}\"" >> ${ADT_PATH}/adt_installer.conf
    echo -e "YOCTOADT_TARGETS=\"arm\"" >> ${ADT_PATH}/adt_installer.conf
    echo -e "YOCTOADT_QEMU=\"N\"" >> ${ADT_PATH}/adt_installer.conf
    echo -e "YOCTOADT_NFS_UTIL=\"N\"" >> ${ADT_PATH}/adt_installer.conf
    echo -e "YOCTOADT_ROOTFS_${YOCTOADT_TARGETS}=\"skyboard-evb-sdk\"" >> ${ADT_PATH}/adt_installer.conf
    echo -e "YOCTOADT_TARGET_SYSROOT_IMAGE_${YOCTOADT_TARGETS}=\"skyboard-evb-sdk\"" >> ${ADT_PATH}/adt_installer.conf
    echo -e "YOCTOADT_TARGET_MACHINE_${YOCTOADT_TARGETS}=\"skyboard-evb\"" >> ${ADT_PATH}/adt_installer.conf
    echo -e "YOCTOADT_TARGET_SYSROOT_LOC_${YOCTOADT_TARGETS}=\"$HOME/skybase-sdk/sysroots/${YOCTOADT_TARGETS}\"\n" >> ${ADT_PATH}/adt_installer.conf
    
    echo -e "\nnew adt_installer.conf generated\n"

}

print_params() {

    echo -e "\ncurrently PARAMETERS are set to:\n"
    echo -e "INSTALL_DIR=\"${INSTALL_DIR}\""
    echo -e "ADT_PATH=\"${ADT_PATH}\"\n"
    echo -e "YOCTOADT_REPO=\"http://kiwaglxswd08.ch.int.kistler.com/adtrepo\""
    echo -e "YOCTOADT_TARGETS=\"arm\""
    echo -e "YOCTOADT_QEMU=\"N\""
    echo -e "YOCTOADT_NFS_UTIL=\"N\""
    echo -e "YOCTOADT_ROOTFS_${YOCTOADT_TARGETS}=\"${YOCTOADT_ROOTFS_arch}\""
    echo -e "YOCTOADT_TARGET_SYSROOT_IMAGE_${YOCTOADT_TARGETS}=\"${YOCTOADT_TARGET_SYSROOT_IMAGE_arch}\""
    echo -e "YOCTOADT_TARGET_MACHINE_${YOCTOADT_TARGETS}=\"${YOCTOADT_TARGET_MACHINE_arch}\""
    echo -e "YOCTOADT_TARGET_SYSROOT_LOC_${YOCTOADT_TARGETS}=\"${YOCTOADT_TARGET_SYSROOT_LOC_arch}\"\n"
}


####################################
# print banner and --help option   #
####################################
print_banner() {
    
    echo -e ""
    echo -e "    ___    ____  ______ "                                           
    echo -e "   /   |  / __ \/_  __/  _      ___________ _____  ____  ___  _____   "
    echo -e "  / /| | / / / / / /    | | /| / / ___/ __ \/ __ \/ __ \/ _ \/ ___/   "
    echo -e " / ___ |/ /_/ / / /     | |/ |/ / /  / /_/ / /_/ / /_/ /  __/ /       " 
    echo -e "/_/  |_/_____/ /_/      |__/|__/_/   \__,_/ .___/ .___/\___/_/        "  
    echo -e "                                        /_/   /_/                     "
    echo -e "Yocto ADT wrapper script ${WRAPPER_VER}"
    echo -e "To see all options, run with --help parameter"
}



#########################################################################################
#                                                                                       #
# MAIN FUNCTION                                                                         #
#########################################################################################

if [[ $# -lt 1 ]]; then
    print_banner
#    echo -e "running with default parameters"
#    process_parameters $@
#    write_adt_conf
#    export ADT_INSTALL_PATH=${INSTALL_DIR}
#    echo -e "${INSTALL_DIR} exported"
#    export SUDO=""
#    ./${ADT_PATH}/adt_installer 
else
    echo -e "some parameters found... OK"
    process_parameters $@
    write_adt_conf
    export ADT_INSTALL_PATH=${INSTALL_DIR}
    echo -e "${INSTALL_DIR} exported"
    export SUDO=""
    ./${ADT_PATH}/adt_installer
fi

exit $?
