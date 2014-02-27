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


######################
# terminal colors    #
######################

NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
BLACK='\033[30m'
BLUE='\033[34m'
VIOLET='\033[35m'
CYAN='\033[36m'
GREY='\033[37m'

######################
# default values     #
######################

YOCTO_VERSION="1.5.1"
YOCTO_DISTRO="poky"
YOCTO_REPO="http://downloads.yoctoproject.org/releases/yocto/yocto-${YOCTO_VERSION}"
INSTALL_DIR="/opt/poky/1.5.1"  #default as adt installer

######################
# HOST values        #
######################

HOST_ARCH=$(uname -m)
HOST_OS=$(uname -o)
HOST_KERNEL_VERSION=$(uname -r)
CPU_THREADS=$(cat /proc/cpuinfo |grep processor|wc -l)
declare -a DISTROS=()
declare -a MACHINES=()
declare -a IMAGES=()
declare -a PACKAGE_MANAGERS=("rpm" "tar" "deb" "ipk")



get_stable_branch() {
  echo -e "downloading STABLE"
  wget ${YOCTO_REPO}/poky-dora-10.0.1.tar.bz2
  tar xvjf poky-dora-10.0.1.tar.bz2
}

get_current_branch() {
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
}

############################
# collect info from user   #
############################
collect_user_data() {

  echo -e "collecting user data........................................."
  echo -e "............................................................."

  # CPU THREADS setting, if user set more threads than CPU have, warning is issued and script exits
  echo -e "Your machine has ${CPU_THREADS} cores/thread. How many of them you want to use for building?"
  printf "[${CPU_THREADS}]:"

  read THR
  echo "want to set $THR threads"

  if [[ ! -z "${THR}" ]];then
    if [[ "${THR}" > "${CPU_THREADS}" ]];then
      echo -e "INVALID NUMBER! You try to assign ${THR} of ${CPU_THREADS} available!"
      exit
    fi
    CPU_THREADS="${THR}"
  fi
  echo -e "............................................................."


  # set INSTALL folder
  echo -e "Where do you want to install Yocto?"
  printf "[${INSTALL_DIR}]:"
  read INST
  if [[ -z "${INST}" ]];then
    echo "${INST} is set"
    INSTALL_DIR="${INST}"
  else
    echo "value is empty"
  fi
  echo -e "switching to ${INSTALL_DIR}"
  cd ${INSTALL_DIR}
  echo -e "............................................................."

  # set and download Yocto
  echo -e "Do you want to use CURRENT (git) unstable or rather STABLE (wget) version?"
  printf "[CURRENT]:"
  read ${CUR}
  if [[ ! -z "${CUR}" ]];then
    if [[ "${CUR}" == "STABLE" ]];then
      get_stable_branch
    else 
      get_current_branch
    fi
  fi
  echo -e "............................................................."

  echo -e "inspecting downloaded files"
  DISTROS=($(ls ${INSTALL_DIR}/meta*/conf/distro/*.conf| grep 'conf/distro/' | cut -d '/' -f 9 | cut -d '.' -f 1))
  MACHINES=($(ls ${INSTALL_DIR}/meta*/conf/machine/*.conf| cut -d '/' -f 9 | cut -d '.' -f 1))
  IMAGES=($(ls ${INSTALL_DIR}/meta*/recipe*/images/*.bb |cut -d '/' -f 9 | cut -d '.' -f 1))

 


  

  echo -e "\n\nSummary:"
  echo "install dir set to ${INSTALL_DIR}"
  echo "target set to ${TARGETS[@]}"
  echo "target MACHINE set to ${MACHINES[@]}"
  echo "package manager set to ${PACKAGE_MANAGERS}"
  echo "image type set to ${IMAGES[@]}"
  sleep 40000
}

###############################
# install full yocto          #
###############################
install_full_yocto() {

  echo "full yocto (STABLE)"
  sleep 400

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

  echo "full yocto devel (GIT)"
  sleep 400

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





#########################################################################################
#                                                                                       #
# MAIN FUNCTION                                                                         #
#########################################################################################

echo -e "welcom to simple YOCTO installer"
echo -e "##################################################"

#echo -e "do you want to proceed with:"
#echo -e "[1] full Poky 10.0.1 install (stable)"
#echo -e "[2] full Poky install (cutting edge)"
#echo -e "[3] toolchain only"
#echo "enter your choice:"
#read CHOICE


collect_user_data

#case "${CHOICE}" in
#1) install_full_yocto
#  ;;
#2) install_full_yocto_devel
#  ;;
#3) install_toolchain_only
#  ;;
#*) echo "wrong choice"
  ;;
esac
