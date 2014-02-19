#!/bin/bash

# simple Yocto devel toolkit script to install Yocto or it's toolchains
# author: peter.ducai@gmail.com

# HOST data
HOST_ARCH=$(uname -m)
HOST_OS=$(uname -o)
HOST_KERNEL_VERSION=$(uname -r)

# TARGET
TARGET_ARCH="i586"  #(i586 x86_64 powerpc mips armv7a armv5te)
declare -a TARGETS=("qemumips" "qemuppc" "qemux86" "qemux86-64" "genericx86" "genericx86-64" "beagleboard" "mpc8315e-rdb" "routerstationpro")
PACKAGE_MANAGER="rpm"
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
  sed -i "s/MACHINE ??= \"qemux86\"/MACHINE ??= \"${TARGET}\"/g" conf/local.conf

  echo "going to run bitbake (but sleeping 200s)"
  #run bitbake and build
  bitbake -c fetchall ${IMAGE_TYPE}  #first just fetch all packages
  bitbake ${IMAGE_TYPE}  #then build YOCTO
}

############################
# toolchain installer      #
############################
install_toolchain_only() {

  # download toolchain
  echo -e "installing toolchain: ${YOCTO_DISTRO}-eglibc-${HOST_ARCH}-${IMAGE_TYPE}-${TARGET_ARCH}-toolchain-${YOCTO_VERSION}.sh"
  wget ${YOCTO_REPO}/toolchain/${HOST_ARCH}/${YOCTO_DISTRO}-eglibc-${HOST_ARCH}-${IMAGE_TYPE}-${TARGET_ARCH}-toolchain-${YOCTO_VERSION}.sh
  #run toolchain installer

  # and execute toolchain installer
  echo -e "running toolchain"
  sh ${YOCTO_DISTRO}-eglibc-${HOST_ARCH}-${IMAGE_TYPE}-${TARGET_ARCH}-toolchain-${YOCTO_VERSION}.sh
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
  echo "install dir set to ${INSTALL_DIR}"
  
#check if folder exists
  if [[ -d ${INSTALL_DIR} ]];then
    echo "changing to install dir ${INSTALL_DIR}"
    cd ${INSTALL_DIR}
  else
    echo "not found.. creating ${INSTALL_DIR}"
    mkdir ${INSTALL_DIR}
    cd ${INSTALL_DIR}
  fi

  echo -e "choose target: qemumips qemuppc qemux86 qemux86-64 genericx86 genericx86-64 beagleboard"
  read TRG
  if [[ ! -z ${TRG} ]];then
    TARGET=${TRG}
  fi
  echo "target set to ${TARGET}"

  echo -e "choose package manager [rpm], but also [tar, deb, ipk] available:"
  read PKG
  if [[ ! -z ${PKG} ]];then
    PACKAGE_MANAGER=${PKG}
  fi
  echo "package manager set to ${PACKAGE_MANAGER}"

  echo -e "choose image type [core-image-sato], but also [core-image-minimal, core-image-base, core-image-sato-dev, core-image-lsb]"
  read IMGTYPE
  if [[ ! -z ${IMGTYPE} ]];then
    IMAGE_TYPE=${IMGTYPE}
  fi
  echo "image type set to ${IMAGE_TYPE}"
}


#########################################################################################
#                                                                                       #
# MAIN FUNCTION                                                                         #
#########################################################################################

echo -e "welcom to simple YOCTO installer"
echo -e "##################################################"

echo -e "do you want to proceed with:"
echo -e "[1] full YOCTO install"
echo -e "[2] toolchain only"
echo ""
read CHOICE



case "${CHOICE}" in
1) collect_user_data
  install_full_yocto
  ;;
2) echo -e "image type is: ${IMAGE_TYPE}" 
  echo -e "select target arch: i586 x86_64 powerpc mips armv7a armv5te"
  read TRG
  if [[ ! -z {$TRG} ]];then
    TARGET=${TRG}
  fi
  install_toolchain_only
  ;;
*) echo "wrong choice"
  ;;
esac
