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
# Purpose : Yocto development toolkit installer
# Usage : run without paramaters to see usage
#

# HOST data
HOST_ARCH=$(uname -m)
HOST_OS=$(uname -o)
HOST_KERNEL_VERSION=$(uname -r)

# TARGET
declare -a TARGET_ARCHS=("armv5te" "armv7a" "i586" "mips32" "ppc7400" "ppce500v2" "x86_64" )
declare -a TARGETS=("qemumips" "qemuppc" "qemux86" "qemux86-64" "genericx86" "genericx86-64" "beagleboard" "mpc8315e-rdb" "routerstationpro")
declare -a PACKAGE_MANAGERS=("rpm" "tar" "deb" "ipk")
IMAGE_RECIPE="core-image-sato" #default for toolchains
TARGET="qemux86" #or MACHINE in config

# YOCTO data
YOCTO_VERSION="1.5.1"
YOCTO_DISTRO="poky"
YOCTO_REPO="http://downloads.yoctoproject.org/releases/yocto/yocto-${YOCTO_VERSION}"
INSTALL_DIR="/opt/poky/1.5.1"  #default as adt installer



###############################
# install full yocto          #
###############################
install_full_yocto() {

  cd ${INSTALL_DIR}
  wget ${YOCTO_REPO}/poky-dora-10.0.1.tar.bz2
  tar xvjf poky-dora-10.0.1.tar.bz2

  # source directory to default 'build' dir
  source ${YOCTO_DISTRO}/oe-init-build-env

  # change MACHINE in conf/local.conf
  sed -i "s/MACHINE ??= \"qemux86\"/MACHINE ??= \"${TARGETS[@]}\"/g" conf/local.conf

  echo "going to run bitbake (but sleeping 200s)"
  sleep 400
  #run bitbake and build
  bitbake -c fetchall ${IMAGE_RECIPE}  #first just fetch all packages
  bitbake ${IMAGE_RECIPE}  #then build YOCTO
}

install_full_yocto_devel() {

  cd ${INSTALL_DIR}

  if [[ -d ${INSTALL_DIR}/${YOCTO_DISTRO} ]];then
    if [[ -d ${INSTALL_DIR}/${YOCTO_DISTRO}/.git ]];then
      echo -e "YOCTO git folder already exists.. updating with git."
      git pull
    else
      echo -e "YOCTO folder already exist but it's not GIT repository. Please delete it and rerun installer."
    fi
  else
    git clone git://git.yoctoproject.org/${YOCTO_DISTRO}
  fi

  # source directory to default 'build' dir
  source ${YOCTO_DISTRO}/oe-init-build-env

  # change MACHINE in conf/local.conf
  sed -i "s/MACHINE ??= \"qemux86\"/MACHINE ??= \"${TARGETS[@]}\"/g" conf/local.conf

  echo "going to run bitbake (but sleeping 200s)"
  sleep 400
  #run bitbake and build
  bitbake -c fetchall ${IMAGE_RECIPE}  #first just fetch all packages
  bitbake ${IMAGE_RECIPE}  #then build YOCTO
}




############################
# toolchain installer      #
############################
install_toolchain_only() {

  for ta in "${TARGET_ARCHS[@]}"
  do
    # download toolchain
    echo -e "DOWNLOADING toolchain from ${YOCTO_REPO}/toolchain/${YOCTO_DISTRO}-eglibc-${HOST_ARCH}-${IMAGE_RECIPE}-${ta}-toolchain-${YOCTO_VERSION}.sh"
    #sleep 400
    wget ${YOCTO_REPO}/toolchain/${HOST_ARCH}/${YOCTO_DISTRO}-eglibc-${HOST_ARCH}-${IMAGE_RECIPE}-${ta}-toolchain-${YOCTO_VERSION}.sh
    #run toolchain installer

    # and execute toolchain installer
    echo -e "running toolchain ${YOCTO_DISTRO}-eglibc-${HOST_ARCH}-${IMAGE_RECIPE}-${ta}-toolchain-${YOCTO_VERSION}.sh"
    #sh ${YOCTO_DISTRO}-eglibc-${HOST_ARCH}-${IMAGE_RECIPE}-${ta}-toolchain-${YOCTO_VERSION}.sh
  done  
}


############################
# collect info from user   #
############################
collect_user_data() {

  echo -e "choose install directory [${INSTALL_DIR}]:"
  read INSTDIR
  if [[ ! -z ${INSTDIR} ]];then
    INSTALL_DIR=${INSTDIR}
  fi
  
  
#check if folder exists
  if [[ -d ${INSTALL_DIR} ]];then
    echo "changing to install dir ${INSTALL_DIR}"
    cd ${INSTALL_DIR}
  else
    echo "not found.. creating ${INSTALL_DIR}"
    mkdir ${INSTALL_DIR}
    cd ${INSTALL_DIR}
  fi

  echo -e "choose target [${TARGETS[@]}]:"
  read TRG
  if [[ ! -z ${TRG} ]];then
    read -a TARGETS <<<${TRG}
  fi
  

  echo -e "choose target architecture [${TARGET_ARCHS[@]}]:"
  read TRGA
  if [[ ! -z ${TRGA} ]];then
    read -a TARGET_ARCHS <<<${TRGA}
  fi
  

  echo -e "choose package manager ${PACKAGE_MANAGERS[@]}:"
  read PKG
  if [[ ! -z ${PKG} ]];then
    read -a PACKAGE_MANAGERS <<<${PKG}
  fi
  

  echo -e "choose image type ${IMAGE_RECIPE}:"
  read IMGTYPE
  if [[ ! -z ${IMGTYPE} ]];then
    IMAGE_RECIPE=${IMGTYPE}
  fi
  

  echo -e "\n\nSummary:"
  echo "install dir set to ${INSTALL_DIR}"
  echo "target set to ${TARGETS[@]}"
  echo "target archs set to ${TARGET_ARCHS[@]}"
  echo "package manager set to ${PACKAGE_MANAGERS}"
  echo "image type set to ${IMAGE_RECIPE}"

}


#########################################################################################
#                                                                                       #
# MAIN FUNCTION                                                                         #
#########################################################################################

echo -e "welcom to simple YOCTO installer"
echo -e "##################################################"

echo -e "do you want to proceed with:"
echo -e "[1] full Poky 10.0.1 install (stable)"
echo -e "[2] full Poky install (cutting edge)"
echo -e "[3] toolchain only"
echo "enter your choice:"
read CHOICE


collect_user_data

case "${CHOICE}" in
1) install_full_yocto
  ;;
2) install_full_yocto_devel
  ;;
3) install_toolchain_only
  ;;
*) echo "wrong choice"
  ;;
esac
