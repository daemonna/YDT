#!/bin/bash

INSTALL_DIR="/opt/poky/1.5.1"

# HOST data
HOST_ARCH=$(uname -m)
HOST_OS=$(uname -o)
HOST_KERNEL_VERSION=$(uname -r)


# TARGET
TARGET_ARCH=(i586 x86_64 powerpc mips armv7a armv5te)

# YOCTO data
YOCTO_VERSION="1.5.1"
YOCTO_DISTRO="poky"
YOCTO_REPO="http://downloads.yoctoproject.org/releases/yocto/yocto-${YOCTO_VERSION}"



declare -a TARGETS=("qemumips" "qemuppc" "qemux86" "qemux86-64" "genericx86" "genericx86-64" "beagleboard" "mpc8315e-rdb" "routerstationpro")
PACKAGE_MANAGER="rpm"
IMAGE_TYPE="core-image-sato"
MACHINE="" #will be one of targets



###############################
# install full yocto          #
###############################
install_full_yocto() {
  cd ${INSTALL_DIR}
  git clone git://git.yoctoproject.org/${YOCTO_DISTRO}
  source ${YOCTO_DISTRO}/oe-init-build-env

#alter conf/local.conf
  sed -i 's/MACHINE ??= \"qemux86\"/MACHINE ??= \"${MACHINE}\"/g' conf/local.conf


  bitbake core-image-minimal
}

############################
# toolchain installer      #
############################
install_toolchain_only() {
  wget ${YOCTO_REPO}/toolchain/${HOST_ARCH}/${YOCTO_DISTRO}-eglibc-${HOST_ARCH}-${IMAGE_TYPE}-<arch>-toolchain-${YOCTO_VERSION}.sh
}


############################
# nothing to do with NSA   #
############################
collect_user_data() {
  echo -e "install directory [${INSTALL_DIR}]:"
  read INSTDIR
  echo -e "target"
  read TRG
  echo -e "package manager [rpm], but also [tar, deb, ipk] available:"
  read PKG
  echo -e "image type [core-image-sato], but also [
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
2) collect_user_data
  install_toolchain_only
  ;;
*) echo "wrong choice"
  ;;
esac
