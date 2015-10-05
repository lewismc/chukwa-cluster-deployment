#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# The chukwa-cluster-deployment script
#
# Environment Variables
#
#   JAVA_HOME      The java implementation to use.  Overrides JAVA_HOME.
#   MACHINES_FILE  The local name of a flat file containing IP addresses to deploy Chukwa to.
#   CHUKWA_VERSION Version of Chuwka we wish to deploy
#
# Usage: chukwa-cluster-deployment [-m|--master] <Install Directory>
#    -m|--master         Optionally checks out Chukwa master branch from the official Apache Git source repository. 
#    Install Directory   Directory which Chuwka is to be installed in on every node present in IP_FILE
#

MACHINES_FILE=machines.txt
CHUKWA_VERSION=0.6.0
ARCHIVE_URL=http://archive.apache.org/dist/chukwa/chukwa-${CHUKWA_VERSION}.tar.gz
CHUKWA_MASTER=https://git-wip-us.apache.org/repos/asf/chukwa.git

while [[ $# > 0 ]]
do
    case $1 in
        -m|--master)
            MASTERFLAG=true
            shift
            ;;
        *)
            break
            ;;
    esac
done


if [[ $# -ne 1 ]]; then
    echo "chukwa-cluster-deployment [-m|--master]"
    echo -e "\t-m|--master\tOptionally checks out Chukwa master branch from the official Apache Git source repository."
    echo -e "\tInstall Directory\tDirectory which Chuwka is to be installed in on every node present in IP_FILE."
    exit 1
fi

INSTALL_DIR="$1"

while read ip; do
    ssh ip
    cd ${INSTALL_DIR}
    if [[ MASTERFLAG ]]; then
        git clone ${CHUKWA_MASTER}
        cd chukwa
        mvn install -DskipTests
        cd target
        for f in *.tar.gz; do
            tar -zxvf "$f"
            f=${f##*/}
            f=${f%.tar.gz}
            cd ${f}
        done
        echo "export CHUKWA_HOME=$(pwd)" >> ${HOME}/.bashrc
        source ${HOME}/.bashrc
        cp $CHUKWA_HOME/share/chukwa/${f}-SNAPSHOT-client.jar $HADOOP_HOME/share/hadoop/common/lib
        cp $CHUKWA_HOME/share/chukwa/${f}-SNAPSHOT-client.jar $HBASE_HOME/lib
    else 
        wget ${ARCHIVE_URL}
        tar -zxvf chukwa-${CHUKWA_VERSION}.tar.gz
        cd chukwa-${CHUKWA_VERSION}
        echo "export CHUKWA_HOME=$(pwd)" >> ${HOME}/.bashrc
        source ${HOME}/.bashrc
        cp $CHUKWA_HOME/share/chukwa/chukwa-${CHUKWA_VERSION}-client.jar $HADOOP_HOME/share/hadoop/common/lib
        cp $CHUKWA_HOME/share/chukwa/chukwa-${CHUKWA_VERSION}-client.jar $HBASE_HOME/lib
    fi
    cp $HADOOP_CONF_DIR/log4j.properties $HADOOP_CONF_DIR/log4j.properties.bk
    cp $CHUKWA_HOME/etc/chukwa/hadoop-log4j.properties $HADOOP_CONF_DIR/log4j.properties
    cp $HADOOP_CONF_DIR/hadoop-metrics2.properties $HADOOP_CONF_DIR/hadoop-metrics2.properties.bk
    cp $CHUKWA_HOME/etc/chukwa/hadoop-metrics2.properties $HADOOP_CONF_DIR/hadoop-metrics2.properties
    cp $CHUKWA_HOME/share/chukwa/lib/json-simple-1.1.jar $HADOOP_HOME/share/hadoop/common/lib
    cp $HBASE_CONF_DIR/log4j.properties $HBASE_CONF_DIR/log4j.properties.bk
    cp $CHUKWA_CONF_DIR/hbase-log4j.properties $HBASE_CONF_DIR/log4j.properties
    cp $HBASE_CONF_DIR/hadoop-metrics2-hbase.properties $HBASE_CONF_DIR/hadoop-metrics2-hbase.properties.bk
    cp $CHUKWA_HOME/etc/chukwa/hadoop-metrics2-hbase.properties $HBASE_CONF_DIR/hadoop-metrics2-hbase.properties
    cp $CHUKWA_HOME/share/chukwa/lib/json-simple-1.1.jar $HBASE_HOME/lib
done <${MACHINES_FILE}

#Restart Hadoop Cluster

#Shutdown
#$HADOOP_PREFIX/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs stop namenode
#HADOOP_PREFIX/sbin/hadoop-daemons.sh --config $HADOOP_CONF_DIR --script hdfs stop datanode
$HADOOP_PREFIX/sbin/stop-dfs.sh
#$HADOOP_YARN_HOME/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR stop resourcemanager
#$HADOOP_YARN_HOME/sbin/yarn-daemons.sh --config $HADOOP_CONF_DIR stop nodemanager
$HADOOP_PREFIX/sbin/stop-yarn.sh
#$HADOOP_YARN_HOME/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR stop proxyserver
#$HADOOP_PREFIX/sbin/mr-jobhistory-daemon.sh --config $HADOOP_CONF_DIR stop historyserver

#Startup
#$HADOOP_PREFIX/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs start namenode
#$HADOOP_PREFIX/sbin/hadoop-daemons.sh --config $HADOOP_CONF_DIR --script hdfs start datanode
$HADOOP_PREFIX/sbin/start-dfs.sh
#$HADOOP_YARN_HOME/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR start resourcemanager
#$HADOOP_YARN_HOME/sbin/yarn-daemons.sh --config $HADOOP_CONF_DIR start nodemanager
#$HADOOP_YARN_HOME/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR start proxyserver
$HADOOP_PREFIX/sbin/start-yarn.sh
#$HADOOP_PREFIX/sbin/mr-jobhistory-daemon.sh --config $HADOOP_CONF_DIR start historyserver

#Restart HBase Cluster
$HBASE_HOME/bin/stop-hbase.sh
$HBASE_HOME/bin/start-hbase.sh

# Initialize the default Chukwa HBase schema
$HBASE_HOME/bin/hbase shell < $CHUKWA_HOME/etc/chukwa/hbase.schema

# Configure and star Chukwa Agent

