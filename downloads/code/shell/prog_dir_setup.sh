#!/bin/sh
#
###
###  This script will set up your program's working environment on a CentOS Environment
###
###  Our Installation Base is "/usr/local/bin/$INSTALL_NAME"
###    where we create subdirectories: bin and lib.
###  Our Log file, data, and pid Base is "/var/spool/$INSTALL_NAME"
###    where we create subdirectories: data, log, and pid.
###  Our Config file BASE will be "/etc/$INSTALL_NAME".
###
###  You can change those to work in a chroot environment below
###
###
###  We also create a user name "$INSTALL_NAME" and change ownership
###    of the "/var/spool/$INSTALL_NAME" subdirectories to "$INSTALL_NAME.root"
###
###  We also write out an installation log file in "/tmp"
###
###
###  
###
###
###  I hope you find this script useful.
###  - Shaun "http://sphughes.com"
###
###
###  Copyright 2011 Shaun Hughes
###  
###   Licensed under the Apache License, Version 2.0 (the "License");
###   you may not use this file except in compliance with the License.
###   You may obtain a copy of the License at
###
###       http://www.apache.org/licenses/LICENSE-2.0
###
###   Unless required by applicable law or agreed to in writing, software
###   distributed under the License is distributed on an "AS IS" BASIS,
###   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
###   See the License for the specific language governing permissions and
###   limitations under the License.
###
###
###
###  We check for our one necessary user supplied variable below
###
[ -z ${1} ] && echo -e "\n -- \"USAGE: prog_dir_setup.sh YourProgramNameThatYouAreSettingUpTheEnvironment\" -- \n" && exit 1;
###
###
###
###   We test to see if we have root priveledges below
###     Comment out the ([ `id -u ....) line to run as another user for testing purposes or creating a chroot environment
###     Also comment out the (CHRT_BASE='') line and uncomment the (CHRT_BASE="/home/`whoami`" line
###     Reverse the process to run as root
###
[ `id -u` -ne "0" ] && echo -e "\n -- error: You are not root user - exiting -- \n" && exit 1;
CHRT_BASE=''
#CHRT_BASE="/home/`whoami`"
###
###
###
###   We will set some variables below so I can re-use this script
###   The "INSTALL_NAME" is the name of the program we will be preparing
###   the environment to run, change as you see fit.
###
INSTALL_NAME="$1"
INSTALL_BASE=${CHRT_BASE}'/usr/local/bin'
LOG_BASE=${CHRT_BASE}'/var/spool'
CONF_BASE=${CHRT_BASE}'/etc'
OUT_LOG_BASE='/tmp'
RUNTIME=`date +%Y%m%d-%H%M%S`
###
###
###
###   Now we'll conbine the variables to create the desired paths
###
INSTALL_DIR="${INSTALL_BASE}/${INSTALL_NAME}"
LOG_DIR="${LOG_BASE}/${INSTALL_NAME}"
CONF_DIR="${CONF_BASE}/${INSTALL_NAME}"
OUT_LOG="${OUT_LOG_BASE}/${INSTALL_NAME}_install-${RUNTIME}.log"
###
###
###
###    We test if our program is already a user or a group
###    and we exit with some basic error messages
###
grep "^${INSTALL_NAME}" /etc/passwd && echo -e "\n--error: User ${INSTALL_NAME} exists - exiting--\n" && exit 1;
grep "^${INSTALL_NAME}" /etc/group && echo -e "\n--error: Group ${INSTALL_NAME} exists - exiting--\n" && exit 1;
###
###
###
###  This function below will be used to verify if a target (ie. directory, file, etc.) exists
###
check_target_exists()
{
  [ -e ${1} ] && (echo -e "\n -- error: ${1} exists - exiting -- \n" && exit 1);
  return 0
}
###
###
###
###  This function will be used to create directory ${1} and log output to a file specified in ${2}
###
create_dir_and_log()
{
   (mkdir -v ${1} 2>&1)|tee -a ${2} || (echo -e "\n -- error: Unable to write to ${2} -- \
\n           -- likely permission issue - exiting -- \n" && exit 1);
   [ -e ${1} ] || (echo -e "\n -- error: Unable to create ${1} -- \
\n           -- likely permission issue - exiting -- \n" && exit 1);
   [ -e ${2} ] || (echo -e "\n -- error: Unable to create ${2} -- \
\n           -- likely permission issue - exiting -- \n" && exit 1);
   return 0
}
###
###
###
###  This function combines the verification and creating and logging functions
###
check_create_and_log()
{
check_target_exists ${1} && create_dir_and_log ${1} ${2};
}
###
###
###
###  Now we will check to see if something similarly named exists where we plan to create
###  our install directory, log directory, and config directory
###  We use the "check_target_exists" function above
###
###  We could comment out these lines and use the check when we create each directory
###    but this keeps the user from having to proceed further if any of these exist 
###
check_target_exists ${INSTALL_DIR};
check_target_exists ${LOG_DIR};
check_target_exists ${CONF_DIR};
###
###
###
###  Now we will let the user know what we are planning to do
###
clear
echo -e "\n";
echo -e "  We will be creating a system account named \"${INSTALL_NAME}\"";
echo -e "  We will be creating an install Directory named \"${INSTALL_DIR}\"";
echo -e "  We will be creating a Logging/Data Directory named \"${LOG_DIR}\"";
echo -e "  We will also be creating a Configuration Directory named \"${CONF_DIR}\"";
echo -e "\n";
if [ ! -z ${CHRT_BASE} ]; then
{
echo -e " -- We will also be  Creating the chroot base directories -- ";
echo -e " -- The chroot base is \"${CHRT_BASE}\" -- ";
echo -e " -- \"${CHRT_BASE}/usr\" -- ";
echo -e " -- \"${CHRT_BASE}/usr/local\" -- ";
echo -e " -- \"${CHRT_BASE}/usr/local/bin\" -- ";
echo -e " -- \"${CHRT_BASE}/var\" -- ";
echo -e " -- \"${CHRT_BASE}/var/spool\" -- ";
echo -e " -- \"${CHRT_BASE}/etc\" -- ";
echo -e "\n";
}
fi
###
###
###
###  Now we will check to see if the user approves
###
echo -n "  Do you wish to proceed with the above changes [y/n] :";
read AGREE
  case $AGREE in
    y|Y|yes|Yes|YES) echo -e "\n  Here we go ... proceeding with setup\n"
     ;;
    n|N|no|No|NO) echo -e "\n  Okay - We will quit now\n"
     exit 0
     ;;
    *) echo -e  "\n  `basename ${0}` : Unrecognized input\n" >&2
     exit 1
     ;;
   esac
###
###
###
###  We check below for a non null value for $CHRT_BASE and create the base chroot directories below
###    This is only done if you uncomment the CHRT_BASE="/home/`id -u`" variable near the top 
###    of this script. You can obviously change it to whatever is appropriate to your needs:w
###
if [ ! -z ${CHRT_BASE} ]; then
{ 
   echo -e "\n -- Creating the chroot base directories -- ";
   echo -e " -- chroot base is \"${CHRT_BASE}\" -- \n";
   check_create_and_log "${CHRT_BASE}/usr" "${OUT_LOG}";
   check_create_and_log "${CHRT_BASE}/usr/local" "${OUT_LOG}";
   check_create_and_log "${CHRT_BASE}/usr/local/bin" "${OUT_LOG}";
   check_create_and_log "${CHRT_BASE}/var" "${OUT_LOG}";
   check_create_and_log "${CHRT_BASE}/var/spool" "${OUT_LOG}";
   check_create_and_log "${CHRT_BASE}/etc" "${OUT_LOG}";
}
fi
###
###
###
###   Now we create our common directories under $CHRT_BASE/usr/local/bin, $CHRT_BASE/var/spool, and $CHRT_BASE/etc
###   Remember - $CHRT_BASE is normally null
###
echo -e "\n -- Starting the creation of common directories -- \n";
check_create_and_log "${INSTALL_DIR}" "${OUT_LOG}";
check_create_and_log "${INSTALL_DIR}/bin" "${OUT_LOG}";
check_create_and_log "${INSTALL_DIR}/lib" "${OUT_LOG}";
check_create_and_log "${LOG_DIR}" "${OUT_LOG}";
check_create_and_log "${LOG_DIR}/log" "${OUT_LOG}";
check_create_and_log "${LOG_DIR}/data" "${OUT_LOG}";
check_create_and_log "${LOG_DIR}/pid" "${OUT_LOG}";
check_create_and_log "${CONF_DIR}" "${OUT_LOG}";
###
###
###
###   Now we create our user and group
###
echo -e "\n -- Adding user \"${INSTALL_NAME}\" with home directory \"${LOG_DIR}\" -- \n";
(useradd -r -U -M -d ${LOG_DIR} ${INSTALL_NAME} 2>&1)|tee -a ${OUT_LOG}; 
###
###
###
###  Now we set the permissions for our "Config" sub directories
###  so our program can write logs and data without running as root
###
echo -e "\n -- Changing ownership of directories under \
\n -- \"${LOG_DIR}\" to \"${INSTALL_NAME}.root\" -- \n";
(chown "${INSTALL_NAME}.root" "${LOG_DIR}/log" 2>&1)|tee -a ${OUT_LOG}; 
(chown "${INSTALL_NAME}.root" "${LOG_DIR}/data" 2>&1)|tee -a ${OUT_LOG};
(chown "${INSTALL_NAME}.root" "${LOG_DIR}/pid" 2>&1)|tee -a ${OUT_LOG};
echo -e "\n -- Success !!!, go have another cup of coffee. -- \n";
exit 0
