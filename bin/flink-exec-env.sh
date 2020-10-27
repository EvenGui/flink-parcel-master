#!/bin/bash

# Determine the location of the script to locate parcel
# Reference: http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
SOURCE="${BASH_SOURCE[0]}"
BIN_DIR="$( dirname "$SOURCE" )"
while [ -h "$SOURCE" ]
do
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
  BIN_DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd )"
done
BIN_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Define subfolders of Flink parcel
ETC_DIR=$BIN_DIR/../etc
LIB_DIR=$BIN_DIR/../lib
OPT_DIR=$LIB_DIR/flink/opt

# Autodetect JAVA_HOME if not defined
if [ -e /usr/bin/bigtop-detect-javahome ] ; then
  . /usr/bin/bigtop-detect-javahome
fi

# Detect if /etc/flink/conf has been introduced, otherwise fall back to the parcel local option.
# /etc/flink/conf is to be populated by the Flink Gateway role, but it is not not mandatory.
DEFAULT_FLINK_CONF_DIR=$ETC_DIR/flink/conf.dist

if [ -d /etc/flink/conf ] ; then
  DEFAULT_FLINK_CONF_DIR=/etc/flink/conf
fi

# Verify that the hadoop command exists. This is expected as the Flink parcel declares dependency
# on the CDH parcel.
if ! [ -x "$(command -v hadoop)" ]; then
  echo '[ERROR] The hadoop command is not installed. Verify your Cloudera Distribution for Hadoop installation.' >&2
  exit 1
fi

# Verify that the CDH parcel directory exists. This is expected as the Flink parcel declares dependency
# on the CDH parcel.
CDH_PARCEL_HOME=$BIN_DIR/../../CDH
if ! [ -d $CDH_PARCEL_HOME ]; then
  echo '[ERROR] The CDH parcel directory was not found. Verify your Cloudera Distribution for Hadoop installation.' >&2
  exit 1
fi

# Set environment variables
export HADOOP_HOME=${HADOOP_HOME:-/usr/lib/hadoop}
export HADOOP_CONF_DIR=${HADOOP_CONF_DIR:-/etc/hadoop/conf}
export FLINK_HOME=${FLINK_HOME:-/usr/lib/flink}
export FLINK_CONF_DIR=${FLINK_CONF_DIR:-$DEFAULT_FLINK_CONF_DIR}
export FLINK_LOG_DIR=${FLINK_LOG_DIR:-/var/log/flink}
export HADOOP_CLASSPATH=${HADOOP_CLASSPATH:-$(hadoop classpath)}
export HBASE_CONF_DIR=${HBASE_CONF_DIR:-/etc/hbase/conf}

# Add cloudera optional dependencies
CLOUDERA_OPT_JARS=${CLOUDERA_OPT_JARS:=$OPT_DIR/cloudera/*.jar}
export HADOOP_CLASSPATH=$HADOOP_CLASSPATH:$CLOUDERA_OPT_JARS
