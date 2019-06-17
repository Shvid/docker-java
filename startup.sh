#!/bin/bash

#
#  Wrapper stript to start java app in docker
#
#  ashvid
#

# export APP_NAME from env
PID=0
JAVA_ARGS="-jar /app/service.jar $* \
        /app/application.properties"

function startupApp() {
    java $JAVA_ARGS &
    PID=$!
    RC=$?
    if [[ $RC -ne 0 ]] ; then
        echo "Unable to successfully start the application ${APP_NAME}. Please check application and deploy logs for more details. RC=$RC"
        return $RC
    fi
    return 0
}

function shutdownApp() {
  if [[ $PID -ne 0 ]] ; then
    kill -TERM $PID
    return $?
  fi
  return 0
}

# support terminate/shutdown application
function sigtermHandler() {
    echo "Received SIGTERM signal. Attempting to shutdown the application $APP_NAME with PID $PID..."
    shutdownApp
    RC=$?
    if [[ $RC -ne 0 ]] ; then
        echo "Unable to successfully shutdown the application ${APP_NAME} with PID $PID. Please check application and deploy logs for more details. RC=$RC"
        exit $RC
    fi
}

# support restart/reconfigure on sighup
function sighupHandler() {
    touch "/tmp/maintenance"
    echo "Received SIGHUP signal. Attempting to reload the application with PID $PID ..."
    shutdownApp || exit $?
    startupApp || exit $?
    rm "/tmp/maintenance"
    echo "SIGHUP successfully reloaded app"
}

# Setup signal handlers
trap 'sigtermHandler' SIGTERM SIGINT
trap 'sighupHandler'  SIGHUP

# Startup application
startupApp
RC=$?
if [[ $RC -ne 0 ]] ; then
    echo "Unable to successfully start the application ${APP_NAME}. Please check application and deploy logs for more details. RC=$RC"
    shutdownApp
    exit $RC
fi

echo "Successfully started the application ${APP_NAME} with PID $PID. Moving to wait state ..."
wait $PID

sleep 5
echo "Exiting from container...\n"
