#!/bin/bash

#
# Installation script for google pubsub integration
#
# 2/19/23 - Jason Cress (jcress@us.ibm.com)
#

if [[ -z "$OMNIHOME" ]]; then
   echo "OMNIHOME is not set. Please set it to the correct location of the omnibus installation and re-run this script"
   exit
fi


THISHOST=`hostname`

. lib/libfunctions.sh


###############
#             #
# Begins here #
#             #
###############

# prompt user for environment details

logstashInstall=$(getYesNo "Do you need to install logstash?")
if [ $logstashInstall -eq 1 ]; then
   echo "Installing logstash"
   sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
   sudo cp logstash8.repo /etc/yum.repos.d/logstash8.repo
   sudo yum install logstash
   /usr/share/logstash/bin/logstash-plugin install logstash-input-google_pubsub
fi


confirm=0

# Set default values. Default values with blank strings *require* input from the user, and thus do not support a default value

#installing the files

#cp ../omnibus/probes/linux2x86/* $OMNIHOME/probes/linux2x86/
#cp ../omnibus/java/conf/* $OMNIHOME/java/conf/

# configuring the integration...

OBJECTSERVER="AGG_P"
FSCREDS="$OMNIHOME/probes/linux2x86/pubsubcredentials.json"
FSCONF="$OMNIHOME/probes/linux2x86/logstash-google-pubsub.conf"
MESSAGE_BUS_TCP_LISTENING_PORT="8180"
MESSAGE_BUS_ENDPOINT="/probe/googlepubsub"

while [ $confirm -eq 0 ]; do

	OBJECTSERVER=$(getInput "What is the object server name?" $OBJECTSERVER)
        YOUR_GC_PROJECT_ID=$(getInput "What is the Google project id where the PubSub topic resides?")
        YOUR_GC_PUBSUB_TOPIC=$(getInput "What is the PubSub topic name?")
        YOUR_GC_PUBSUB_TOPIC_SUBSCRIPTION=$(getInput "What is the PubSub topic subscription name?")
        FSCREDS=$(getInput "Where will Google JSON credentials file be located?" $FSCREDS) 
	FSCONF=$(getInput "Where will the logstash configuration file reside?" $FSCONF) 
        MESSAGE_BUS_TCP_LISTENING_PORT=$(getInput "What TCP port do you wish to use for the message bus endpoint?" $MESSAGE_BUS_TCP_LISTENING_PORT)
        MESSAGE_BUS_ENDPOINT=$(getInput "What will be the endpoint used for the message bus probe?" $MESSAGE_BUS_ENDPOINT)
        MESSAGE_BUS_URL="http://$THISHOST:$MESSAGE_BUS_TCP_LISTENING_PORT$MESSAGE_BUS_ENDPOINT"

	echo "############################"
	echo "#                          #"
	echo "# Double-check your values #"
	echo "#                          #"
	echo "############################"
	echo ""
	echo "Object Server Name: $OBJECTSERVER"
	echo "OMNIHOME: $OMNIHOME"
	echo "Google project id: $YOUR_GC_PROJECT_ID"
	echo "Google pubsub topic name: $YOUR_GC_PUBSUB_TOPIC"
	echo "Google pubsub topic subscription name: $YOUR_GC_PUBSUB_TOPIC_SUBSCRIPTION"
	echo "JSON credentials file location: $FSCREDS"
        echo "Logstash configuration file location: $FSCONF"
	echo "TCP port for message bus endpoint: $MESSAGE_BUS_TCP_LISTENING_PORT"
	echo "Endpoint name for message bus posts: $MESSAGE_BUS_ENDPOINT"
        echo "URL for message bus posts: $MESSAGE_BUS_URL"
	echo ""
	confirm=$(getYesNo "Are these values correct?")

done

echo "Installing"

cat ../omnibus/probes/linux2x86/logstash-google-pubsub.conf | sed -e s/\<-YOUR_GC_PROJECT_ID-\>/$YOUR_GC_PROJECT_ID/ -e s/\<-YOUR_GC_PUBSUB_TOPIC-\>/$YOUR_GC_PUBSUB_TOPIC/ -e s/\<-YOUR_GC_PUBSUB_TOPIC_SUBSCRIPTION-\>/$YOUR_GC_PUBSUB_TOPIC_SUBSCRIPTION/ -e s!\<-CREDENTIALS_JSON-\>!$FSCREDS! -e s!\<-YOUR_MESSAGE_BUS_PROBE_ENDPOINT_URL-\>!$MESSAGE_BUS_URL! > $FSCONF
cat ../omnibus/probes/linux2x86/message_bus_google_pubsub.props |sed -e s/\<-OBJECT_SERVER_NAME-\>/$OBJECTSERVER/ -e s/\<-MESSAGE_BUS_TCP_LISTENING_PORT-\>/$MESSAGE_BUS_TCP_LISTENING_PORT/  > $OMNIHOME/probes/linux2x86/message_bus_google_pubsub.props
cat ../omnibus/probes/linux2x86/message_bus_google_pubsub_parser.json | sed -e s!\<-MESSAGE_BUS_ENDPOINT-\>!$MESSAGE_BUS_ENDPOINT! > $OMNIHOME/probes/linux2x86/message_bus_google_pubsub_parser.json
cp ../omnibus/probes/linux2x86/message_bus_google_pubsub.rules $OMNIHOME/probes/linux2x86/
cat ../omnibus/java/conf/googlePubSubWebhookTransport.properties |sed s!\<-MESSAGE_BUS_ENDPOINT-\>!$MESSAGE_BUS_ENDPOINT!  > $OMNIHOME/java/conf/googlePubSubWebhookTransport.properties
mkdir -p $OMNIHOME/var/logstash/data
