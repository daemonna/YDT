#!/bin/bash  

#
# Author : peter.ducai@gmail.com 
# Homepage : 
# License : BSD http://en.wikipedia.org/wiki/BSD_license
# Copyright (c) 2014, peter ducai
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
#coding guidelines: http://google-styleguide.googlecode.com/svn/trunk/shell.xml                         






####################################################################################################
#                                                                                                  #
# GLOBAL VALUES                                                                                    #
####################################################################################################

###################
# TERMINAL COLORS #
###################

NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
BLACK='\033[30m'
BLUE='\033[34m'
VIOLET='\033[35m'
CYAN='\033[36m'
GREY='\033[37m'

############################
# system values            #
############################
NOW=$(date +"%s-%d-%m-%Y")

################
# HOST values  #
################

HOST_ARCH=$(uname -m)
HOST_OS=$(uname -o)
HOST_KERNEL_VERSION=$(uname -r)
HOST_DISTRO="N/A"
HOST_PYTHON_VERSION=$(python -c 'import sys; print("%i" % (sys.hexversion<0x03000000))')
HOST_INSTALL_QEMU="NO"
HOST_INSTALL_NFS="NO"
HOST_CPU_THREADS=$(cat /proc/cpuinfo|grep process|wc -l)

###################
# target values   #
###################
declare -a TARGETS=("qemumips" "qemuppc" "qemux86" "qemux86-64" "genericx86" "genericx86-64" "beagleboard" "mpc8315e-rdb" "routerstationpro")
declare -a TARGETS_EXTERNAL
declare -a PACKAGE_MANAGERS=("rpm" "ipk" "tar" "deb")
PACKAGE_MANAGER="ipk" #default package manager


#######################
# Global adt values   #
#######################
INSTALL_FOLDER="${HOME}/.ydt" #current location as default
DOWNLOAD_FOLDER="${HOME}/.ydt/down" #The central download directory used by the build process to store downloads
CONFIG_FOLDER="${HOME}/.ydt/configs"
YOCTO_ADT_REPO="http://downloads.yoctoproject.org/releases/yocto/yocto-1.5.1/"
LOG_FOLDER="${HOME}/.ydt/log"
LOG="${LOG_FOLDER}/ydt_ng.log"
HISTORY="${HOME}/.ydt/history"
EXTERNAL_TARGETS_FOLDER="${HOME}/.ydt/external_targets"
INTERACTIVE="N" #by default not interactive

############################
# YOCTO version            #
############################
YOCTO_VERSION="1.5.1"
YOCTO_DISTRO="poky"








####################################################################################################
#                                                                                                  #
# LOGGING FUNCTIONS                                                                                #
####################################################################################################

########################
# logging functions    #
########################
adt_log_write() {
  #echo "logging [$NOW] $1 [$2]"
  echo "[$NOW] $1 [$2]" >> $LOG 
}

adt_history_write() {
  #echo "history writes [$NOW] $1"
  echo "[$NOW] $1" >> $HISTORY
}







####################################################################################################
#                                                                                                  #
# DISTRO RELATED FUNCTIONS                                                                         #
####################################################################################################

#########################################
# find out type of linux distro of HOST #
#########################################
get_distro() {
  
  echo -e "checking for right Python version.."
  if [ ${HOST_PYTHON_VERSION} -eq 0 ]; then
    echo -e "${RED}[ERROR]${NONE} we require python version 2.x"
    exit
  else 
    echo -e "${GREEN}[OK]${NONE} python version is 2.x\n"
  fi

  if [ -f /etc/redhat-release ] ; then
    HOST_DISTRO='redhat'
  elif [ -f /etc/SuSE-release ] ; then
    HOST_DISTRO="suse"
  elif [ -f /etc/debian_version ] ; then
    HOST_DISTRO="debian" # including Ubuntu!
  fi
}



################################################
# install required software for current distro #
################################################
install_essentials() {
  case "${HOST_DISTRO}" in
  redhat) yum install gawk make wget tar bzip2 gzip python unzip perl patch \
     diffutils diffstat git cpp gcc gcc-c++ glibc-devel texinfo chrpath \
     ccache perl-Data-Dumper perl-Text-ParseWords
    ;;
  suse) zypper install python gcc gcc-c++ git chrpath make wget python-xml \
     diffstat texinfo python-curses patch
    ;;
  debian) apt-get install gawk wget git-core diffstat unzip texinfo gcc-multilib \
     build-essential chrpath
    ;;
  *) echo "DISTRO error" 
    exit 1
    ;;
  esac
}


######################################
# install additional graphics libs   #
######################################
install_graphical_extras() {
  case "${HOST_DISTRO}" in
  redhat) yum install SDL-devel xterm
    ;;
  suse) zypper install libSDL-devel xterm
    ;;
  debian) apt-get install libsdl1.2-dev xterm
    ;;
  *) echo "DISTRO error"
    exit 1
    ;;
  esac
}


#####################################
# install documentation             #
#####################################
install_documentation() {
  case "${HOST_DISTRO}" in
  redhat) yum install make docbook-style-dsssl docbook-style-xsl \
     docbook-dtds docbook-utils fop libxslt dblatex xmlto
    ;;
  suse) zypper install make fop xsltproc dblatex xmlto
    ;;
  debian) apt-get install make xsltproc docbook-utils fop dblatex xmlto
    ;;
  *) echo "DISTRO error"
    exit 1
    ;;
  esac
}


########################
# install ADT extras   #
########################
install_adt_extras() {
  case "${HOST_DISTRO}" in
  redhat) yum install autoconf automake libtool glib2-devel
    ;;
  suse) zypper install autoconf automake libtool glib2-devel
    ;;
  debian) apt-get install autoconf automake libtool libglib2.0-dev
    ;;
  *) echo "DISTRO error"
    exit 1
    ;;
  esac
}

###############################
#  install qemu (default NO)  #
###############################
install_qemu() {
  if [[ "$HOST_INSTALL_QEMU" == "Y" ]];then
    case "${HOST_DISTRO}" in
    redhat) yum install autoconf automake libtool glib2-devel
      ;;
    suse) zypper install autoconf automake libtool glib2-devel
      ;;
    debian) apt-get install autoconf automake libtool libglib2.0-dev
      ;;
    *) echo "DISTRO error"
      exit 1
      ;;
    esac
  else
    echo -e "skipping installation of Qemu"
  fi

}

########################
# install NFS          #
########################
install_nfs() {
  case "${HOST_DISTRO}" in
  redhat) yum install autoconf automake libtool glib2-devel
    ;;
  suse) zypper install autoconf automake libtool glib2-devel
    ;;
  debian) apt-get install autoconf automake libtool libglib2.0-dev
    ;;
  *) echo "DISTRO error"
    exit 1
    ;;
  esac
}






####################################################################################################
#                                                                                                  #
# INITIAL CHECKS, SELF-HEALING FEATURES, BACKUPS                                                   #                                          ####################################################################################################  

##############################################
# prepare essential folders and config files #
##############################################                                                                   
prepare_essentials() {
  echo -e "\ninitializing CHECKs"
  echo ""
  printf "checking for user rights..   "
##########################
# check if user is root  #
##########################
  if [ $(id -u) == "0" ]; then
    echo -e "${RED}"
    echo -e "#######################################################"
    echo -e "# WARNING!!! running script as ROOT USER              #"
    echo -e "# Are you sure you want to run this script as root?   #"
    echo -e "# User access to ROOT's files can be limited!!!       #"
    echo -e "#######################################################"
    echo -e "${NONE}[Y/n]"
    read USER_INPUT
    if [[ "${USER_INPUT}" == "Y" ]];then
      printf "[OK]"
    else
      echo "exiting"
      exit
    fi
  else
    echo -e "running as as ${GREEN}${USER}${NONE}.. OK"
  fi


###############################
# check for top .ydt folder   #
###############################
  echo -e "checking for .ydt folder..."
  if [[ -d $HOME/.ydt ]];then
    echo -e "you're running YDT installer for first time as ${GREEN}${USER}${NONE}"
  else
    echo -e "no .ydt folder... creating in $HOME/.ydt ."
    mkdir $HOME/.ydt
  fi

########################
# check log file       #
########################
  if [[ -d $LOG_FOLDER ]];then
    echo "$LOG_FOLDER exists.. OK"
    adt_log_write "                               " ""
    adt_log_write "installer run by $USER" "INFO"
  else
    echo "$LOG_FOLDER not found.. creating one"
    mkdir $LOG_FOLDER
    touch ${LOG_FOLDER}/ydt_ng.log
    echo "#created on ${NOW}" >> ${LOG_FOLDER}/ydt_ng.log
    adt_log_write "                               " "new entry"
    adt_log_write "FIRST INITIALIZATION, run by $USER" "INFO"
    adt_log_write "log file missing.. recreated in ${LOG_FOLDER}" "WARNING"
  fi


####################### 
# check CONFIG files  #
#######################
  if [[ -d $CONFIG_FOLDER ]];then
    echo "config found... OK"
  else
    echo "missing config directory... creating default one"
    mkdir $CONFIG_FOLDER
    echo "creating default config file"
    touch ${CONFIG_FOLDER}/default.config
    echo "writing default parameters into config"
    echo "#autogenerated default config" >> ${CONFIG_FOLDER}/default.config
    echo "# logged on [$NOW]"
    echo -e "--interactive" >> ${CONFIG_FOLDER}/default.config
    adt_log_write "config file missing.. recreated in ${CONFIG_FOLDER}" "WARNING"
  fi

#######################
# check HISTORY file  #
#######################
  if [[ -f ${HISTORY} ]];then
    echo "history found at ${HISTORY}... OK"
  else 
    echo "history not found... creating new one"
    touch ${HISTORY}
    adt_log_write "history file missing.. recreated in ${HISTORY}" "WARNING"
    adt_history_write "history file missing.. recreated in ${HISTORY}"
  fi
}






####################################################################################################
#                                                                                                  #
# COMMON FUNCTIONS                                                                                 #
####################################################################################################

###################################
#  list possible Yocto targets    #
###################################
list_targets() {
  echo -e "available targets:"
  echo -e "${GREEN}qemumips qemuppc qemux86 qemux86-64 genericx86 genericx86-64 beagleboard mpc8315e-rdb routerstationpro${NONE}"
}

################################################################################ 
# define target(s) separated by space, to see values use list_targets switch.  #
################################################################################ 
set_targets() {
  if [[ "${INTERACTIVE}" == "Y" ]];then
    echo -e "your HOST is ${GREEN}${HOST_ARCH}${NONE}, what targets you want to install?"
    list_targets
    echo -e "${NONE}[target names]"
    read TRGT
    # TODO validate target
  else
    echo "setting targets to $TARGETS[@]"    
  fi
}

#############################
# list available rootfs     #
#############################
list_rootfs() {
  echo -e "available rootfs:"
  echo -e "${GREEN}minimal minimal-dev sato sato-dev sato-sdk lsb lsb-dev lsb-sdk${NONE}"
}


###############################
# download specific toolchain #
###############################
download_toolchain() {
  echo "DOWNLOADING http://downloads.yoctoproject.org/releases/yocto/yocto-${YOCTO_VERSION}/toolchain/${YOCTO_DISTRO}-eglibc-${HOST_ARCH}-core-image-sato-${TARGET}-toolchain-1.5.1.sh"
  wget -O $DOWNLOAD_FOLDER/${YOCTO_DISTRO}-eglibc-${HOST_ARCH}-core-image-sato-${TARGET}-toolchain-${YOCTO_VERSION}.sh http://downloads.yoctoproject.org/releases/yocto/yocto-${YOCTO_VERSION}/toolchain/${YOCTO_DISTRO}-eglibc-${HOST_ARCH}-core-image-sato-${TARGET}-toolchain-${YOCTO_VERSION}.sh   
}


run_interactive() {
  echo -e "welcome to interactive mode\nthese are current parameters"
  print_parameters
  echo -e "${GREEN}specify install folder${NONE}"
}


run_installer() {
  echo "running INSTALLER"
  adt_log_write "running INSTALLER" "INFO"
  adt_history_write "running INSTALLER"

  if [[ "${INTERACTIVE}" == "Y" ]];then
    adt_log_write "running interactive mode.. collecting user input" "INFO"
    adt_history_write "running interactive mode.. collecting user input"
    run_interactive
  else
    adt_log_write "running non-interactive mode" "INFO"
    adt_history_write "running non-interactive mode"
  fi

  echo -e "${GREEN}running installation..${NONE}"
  adt_log_write "running installation with following parameters:" "INFO"
  adt_log_write "params" "INFO"
  adt_history_write "running installation with following parameters:"
  adt_history_write "params"




# END OF INSTALLATION
  adt_log_write "end of install" "INFO"
  adt_history_write "end of install"
}







####################################################################################################
#                                                                                                  #
# INFO                                                                                             #
####################################################################################################

##################################
# print history of installations #
##################################
show_history() {
  echo -e "\nHISTORY.......................\n"
  cat $HISTORY 
}

list_configs() {
  echo -e "\nFollowing configs were found.."
  ls $HOME/.ydt/configs/
}

print_parameters() {
  get_distro
  echo -e "@${NOW}"
  echo -e "- ${YELLOW}HOST PARAMETERS ${NONE}------------------------------------"

  echo -e "  architecture:     ${GREEN}${HOST_ARCH}${NONE}"
  echo -e "  operating system: ${GREEN}${HOST_OS}${NONE}"
  echo -e "  kernel version:   ${GREEN}${HOST_KERNEL_VERSION}${NONE}"
  echo -e "  distribution:     ${GREEN}${HOST_DISTRO}${NONE}"
  echo -e "  CPU threads:      ${GREEN}${HOST_CPU_THREADS}${NONE}"
  echo -e "------------------------------------------------------"

  echo -e "- ${YELLOW}DISTRO PARAMETERS ${NONE}----------------------------------"
  echo -e "  distro:           ${GREEN}${YOCTO_DISTRO}${NONE}"
  echo -e "  version:          ${GREEN}${YOCTO_VERSION}${NONE}"
  echo -e "------------------------------------------------------"

  echo -e "- ${YELLOW}TARGET PARAMETERS ${NONE}----------------------------------"
  echo -e "  targets:          ${GREEN}${TARGETS[@]}${NONE}"
  echo -e "  external targets: ${GREEN}${TARGETS_EXTERNAL[@]}${NONE}"
  echo -e "  package managers: ${GREEN}${PACKAGE_MANAGERS[@]}${NONE}"
  echo -e "------------------------------------------------------"
  
  echo -e "- ${YELLOW}INSTALL PARAMETERS ${NONE}----------------------------------"
  echo -e "  install folder:   ${GREEN}${INSTALL_FOLDER}${NONE}"
  echo -e "  download folder:  ${GREEN}${DOWNLOAD_FOLDER}${NONE}"
  echo -e "  ADT repo:         ${GREEN}${YOCTO_ADT_REPO}${NONE}"
  echo -e "  log file:         ${GREEN}${LOG}${NONE}"
  echo -e "  history file:     ${GREEN}${HISTORY}${NONE}"
  echo -e "  install NFS:      ${GREEN}${HOST_INSTALL_NFS}${NONE}"
  echo -e "  install Qemu:     ${GREEN}${HOST_INSTALL_QEMU}${NONE}"
  echo -e "------------------------------------------------------"
}



print_usage() {
  echo "running under BASH ${BASH_VERSION}"
  print_parameters
  echo -e "\nUsage:\n"
  echo -e "--interactive            [enter interactive mode where installer will ask for every parameter]"
  echo -e "--list-params            [list all parameters]"
  echo -e "--list-targets           [list all available targets]"
  echo -e "--set-targets          = ${GREEN}qemuarm qemuppc qemux86 qemux86-64 genericx86 genericx86-64 beagleboard mpc8315e-rdb routerstationpro${NONE}"
  echo -e "                         [external targets] ${GREEN}${EXT_TARGETS}${NONE}"
  echo -e "                         [set targets, for more than one, separate with space]"
  echo -e "--list-rootfs            [list rootfs variables]"
  echo -e "--set-rootfs           = ${GREEN}minimal minimal-dev sato sato-dev sato-sdk lsb lsb-dev lsb-sdk${NONE}"
  echo -e "                         [external rootfs]  ${GREEN}${EXT_ROOTFS}${NONE}"
  echo -e "--set-package-system   = ${GREEN}ipk tar deb rpm${NONE}"
  echo -e "                         [set packaging system for YOCTO]"
  echo -e "--install-qemu           [install Qemu package for simulation of other architectures] ROOT required!${NONE}"
  echo -e "--install_nfs            [install NFS package] ROOT required!${NONE}"
  echo -e "--install-path           ${GREEN}PATH${NONE}"
  echo -e "                         [specify installation path]${NONE}"
  echo -e "--show-history           [show installation history]${NONE}"
  echo -e "--load-from-config     = <path_to_config>${NONE}"
  echo -e "                         [load values from specified config file]${NONE}"
  echo -e "--save-to-config       = <path_to_config>${NONE}"
  echo -e "                         [save values to specified config file]${NONE}"
  echo -e "--list-configs           [list available config files]"
  echo -e "--set-external-targets-path = <path_to_folder>"
  echo -e "--set-download-folder  = <path>"
  echo -e "--clean-download-folder  [to clean all downloads]"
  echo -e "--view-log               [view log file content]"
  echo -e "--clear-log              [delete log file]"
}


print_banner() {
  echo -e "\n\/ _  __|_ _"
  echo -e "/ (_)(_ | (_) development toolkit\n"
}









####################################################################################################
#                                                                                                  #
# MAIN FUNCTION                                                                                    #
####################################################################################################

print_banner

# if no parameters, run interactive
if [[ -z "$1" ]]; then
  echo -e "${RED}###################################################################${NONE}"
  echo -e "${RED}# Are you sure you want to run installer with default parameters? #${NONE}"
  echo -e "${RED}###################################################################${NONE}"
  read CONTINUE
  if [[ "${CONTINUE}" != "Y" ]];then
    print_usage
    exit
  else 
    echo "skipping to installer"
  fi
fi


#######################
# process parameters  #
#######################
for i in "$@"
do
case "$i" in
  --install-folder=*) INSTALL_FOLDER="${i#*=}"
    LOG_FOLDER="${INSTALL_FOLDER}/log"
    echo -e "INSTALL FOLDER set to ${INSTALL_FOLDER}"   
    ;;
  --list-params) print_parameters # to list all parameters
    exit
    ;;
  --list-targets) list_targets  
    ;;
  --set-targets=*) TARGETS=("${i#*=}") # define target(s) separated by space, to see values use list_targets switch. Example "arm x86"
    print_parameters
    ;;
  --list-rootfs) list_rootfs  
    ;;
  --set-rootfs=*) ROOTFS="${i#*=}"
    ;;
  --set-package-system=*) PACKAGE_MANAGER="${i#*=}"  # define packaging system, possible values: rpm, ipk, tar, deb
    ;;
  --install-path) INSTALL_FOLDER="${i#*=}" # path to install dir
    ;;
  --show-history) show_history
    ;;
  --install-qemu=*) HOST_INSTALL_QEMU="${i#*=}"
    install_qemu
    ;;
  --install-nfs) HOST_INSTALL_NFS="${i#*=}"
    install_nfs
    ;;
  --save-to-config) echo "something" # save values to config
    ;;
  --load-from-config) echo "something"
    ;;
  --list-configs) list_configs
    ;;
  --interactive)
    INTERACTIVE="Y"
    ;;
  --set-download-folder) DOWNLOAD_FOLDER="${i#*=}"
    echo -e "download folder set to ${DOWNLOAD_FOLDER}"
    ;;
  --clean-download-folder) echo -e "cleaning download folder ${DOWNLOAD_FOLDER}"
    rm -rf ${DOWNLOAD_FOLDER}/*
    ;;
  --set-external-targets-path=*) EXTERNAL_TARGETS_FOLDER="${i#*=}"
    ;;
  --view-log) if [[ -d $LOG_FOLDER ]];then
        cat $LOG_FOLDER/ydt_ng.log
      else
        echo -e "${RED}log file not found.. re-run installer to see default log${NONE}"
      fi
      exit
    ;;
  --clear-log) rm -rf ${LOG_FOLDER}/ydt_ng.log
    echo "log file deleted at ${NOW} by ${USER}"    
    LOG_CLEARED="Y"
    ;;
  *) echo "invalid option!!!" 
    print_usage
    ;;
esac
done

LOG_FOLDER="${INSTALL_FOLDER}/log"
prepare_essentials

if [[ "${LOG_CLEARED}" == "Y" ]];then
  echo "log file deleted at ${NOW} by ${USER}" > ${LOG_FOLDER}/ydt_ng.log
  exit
fi

adt_log_write "INITIALIZATION finished" "INFO"
adt_history_write "INITIALIZATION finished"

run_installer

############################
# continue with params set #
############################

##############################
# END OF INSTALER            #
##############################
exit $?
