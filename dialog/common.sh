#!/bin/bash

set -u

_CONFIG=/opt/retronas/dialog/retronas.cfg
source $_CONFIG

export SC="systemctl --no-pager --full"

## If this is run as root, switch to our RetroNAS user
## Manifests and cookies stored in ~/.gogrepo
DROP_ROOT() {
    if [ "${USER}" == "root" ]
    then
        export SUCOMMAND="sudo -u ${OLDRNUSER}"
    else
        export SUCOMMAND=""
    fi
}


### Get LANG file
GET_LANG() {
    [ ! -z "${LANG}" ] && RNLANG=$(echo $LANG | awk -F'_' '{print $1}')
    [ -z ${RNLANG} ] && RNLANG="en"
    
    if [ -f ${LANGDIR}/${RNLANG} ]
    then
        source ${LANGDIR}/${RNLANG}
    else
        echo "Failed to load language file, check config is complete"
        exit 1
    fi

}

### Run a script
EXEC_SCRIPT() {
    local SCRIPT="${1}"
    bash "${SCRIPT}"
}

### Clear function, standardised
CLEAR() {
    clear
}

### Wait for user input
PAUSE() {
    echo "${PAUSEMSG}"
    read -s
}

#
# Install Ansible Dependencies, runs with every installer
#
RN_INSTALL_DEPS() {
    source $_CONFIG
    cd ${ANDIR}
    ansible-playbook retronas_dependencies.yml
}

#
# Run the playbook
#
RN_INSTALL_EXECUTE() {
    source $_CONFIG
    local PLAYBOOK=$1

    cd ${ANDIR}
    ansible-playbook "${PLAYBOOK}"
}

#
# GENERIC function to call a command format output
#
RN_SERVICE_STATUS() {
  source $_CONFIG
  local CMD="$1"

  CLEAR
  echo "${CMD}"
  echo ; $CMD ; echo
  PAUSE
}

#
# SYSTEMD status checks
#
RN_SYSTEMD_STATUS() {
  RN_SYSTEMD $1 "status"
}

#
# SYSTEMD start/enable
#
RN_SYSTEMD_START() {
  RN_SYSTEMD $1 "enable"
  RN_SYSTEMD $1 "restart"
}

#
# SYSTEMD stop/disable
#
RN_SYSTEMD_STOP() {
  RN_SYSTEMD $1 "disable"
  RN_SYSTEMD $1 "stop"
}

#
# SYSTEMD
#
RN_SYSTEMD() {
  source $_CONFIG
  loca SC="systemctl"
  local SERVICE="$1"
  local COMMAND="${2:-status}"

  RN_SERVICE_STATUS "${SC} ${COMMAND} ${SERVICE}"

}

#
# DIRECTLY call a status command, and pass args
#
RN_DIRECT_STATUS() {
  source $_CONFIG
  local SERVICE="$1"
  local ARGS="$2"

  if [ -x "$(which $SERVICE)" ]
  then
    RN_SERVICE_STATUS "${SERVICE} ${ARGS}"
  fi

}