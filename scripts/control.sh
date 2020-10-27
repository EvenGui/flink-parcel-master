#!/bin/bash
CMD=$1

export FLINK_BIN=${FLINK_BIN:-$CDH_FLINK_BIN}
export SCRIPTS_DIR=${SCRIPTS_DIR:-${CONF_DIR}/scripts}
export FLINK_CONF_DIR=${CONF_DIR}/flink-conf

source  ${SCRIPTS_DIR}/configbuilder.sh
source  ${SCRIPTS_DIR}/set-dependencies.sh

case $CMD in
  (start_history_server)

    configbuilder ${CONF_DIR}/aux/configbuilder/hs.json

    echo "Starting Flink History Server"
    exec ${FLINK_BIN}/flink-historyserver start-foreground
    ;;
  (client)
    HADOOP_CREDSTORE_PASSWORD= configbuilder ${CONF_DIR}/aux/configbuilder/cli.json
    set-dependencies
    ;;
  (*)
    echo "Don't understand [$CMD]"
    ;;
esac
