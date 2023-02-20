# waiops-em-google-pubsub

# Overview

This repo contains configuration files for creating alerts from Google PubSub messages using logstash and the Watson AIOps Event 
Manager message bus probe. It provides a very basic rules file that simply sets the Summary field of the alert to the PubSub message.

You will need to collect the following information to configure this integration:

	Your Google Project ID: The Google Cloud project id where the PubSub topic resides
	Your Google PubSub topic name: The topic name that will be subscribed to in order to collect events
	Your Google PubSub topic subscription name: The subscription name associated with the topic

You will also need to create a JSON file that contains the credentials for the service account that will be used to
subscribe to the topic. The high level steps for this are:

1. Navigate to https://console.cloud.google.com/apis/credentials
2. On the top pane find the blue "create credentials" button, click it, and select "service account key." (see below if its not there)
3. Choose the service account you want, and select "JSON" as the key type.
4. It should allow give you a json to download. Copy this key file to the message bus probe server.

# How it works

This solution leverages logstash's Google PubSub input plugin to subscribe to a Google PubSub topic, and turn messages received around to
the Message Bus probe as a webhook using the logstash http output plugin. 

# Installing this package

The installation script supports RHEL 7 and RHEL 8. For any other Operating Systems, follow the "Manual Installation" 
instructions below.

You must run this on a server where the OMNIbus message bus probe resides, and set the OMNIHOME environment variable to the installation
path of omnibus. 

Perform the following steps to clone the repo and install the package:


- git clone https://github.ibm.com/jcress/waiops-em-google-pubsub.git
- cd waiops-em-google-pubsub/install
- ./install.sh



# Manual installation

## Installing Logstash

To install Logstash, follow the instructions in the following documentation link:

https://www.elastic.co/guide/en/logstash/current/installing-logstash.html

You must also install the Google pubsub input plugin for Logstash, instructions here:

https://www.elastic.co/guide/en/logstash/current/plugins-inputs-google_pubsub.html

## Installing the Message Bus probe configuration files

Copy the files located under omnibus/probes/linux2x86 to $OMNIHOME/probes/linux2x86/

Modify the following files and parameters:

message_bus_google_pubsub.props:

	Server: The name of your Object Server (e.g. NCOMS or AGG_V)
	Port: The TCP port that the Message Bus probe will listen to for alert POSTs

logstash_google_pubsub.conf:

        project_id=>"<-YOUR_GC_PROJECT_ID->" (your google cloud project id should be between the quotes)
        topic=>"<-YOUR_GC_PUBSUB_TOPIC->" (your topic name should be entered between the quotes)
        subscription=>"<-YOUR_GC_PUBSUB_TOPIC_SUBSCRIPTION->" (your subscription name)
        json_key_file=>"<-CREDENTIALS_JSON->" (full path to where the credentials JSON file resides)
        url => "<-YOUR_MESSAGE_BUS_PROBE_ENDPOINT_URL->" (the url for your message bus endpoint, typically http://$MBSERVER:$PORT/probe/googlepubsub)

message_bus_google_pubsub_parser.json:

	Change the endpoint parameter to match the path in the endpoint url (e.g. /probe/googlepubsub)

Finally, copy the file omnibus/java/conf/googlePubSubWebhookTransport.properties to $OMNIHOME/java/conf, edit the file and replace the 'webhookURI'
parameter to the endpoint you would like to use (e.g. /probe/googlepubsub). This must match the URI used in the logstash configuration file.
	
# Running the integration

1. Start the message bus probe, using the google pubsub properties file provided with this package:

```
$OMNIHOME/probes/nco_p_message_bus -propsfile $OMNIHOME/probes/linux2x86/message_bus_google_pubsub.props
```

2. Start logstash, e.g.:
	
```
/usr/share/logstash/bin/logstash -f $OMNIHOME/probes/linux2x86/logstash-google-pubsub.conf --path.data $OMNIHOME/var/logstash/data
```

# Notes

Logstash can send to multiple outputs. If you want to watch the Google PubSub messages come in to logstash, you can uncomment the section for the
stdout output plugin, and any messages that come in will also write to the stdout of the shell that you start logstash. This can be useful for
troubleshooting.

The example rules included are very basic, it simply sets the Identifier and Summary of the generated alarm to the value of the PubSub message. You
most likely will need to do some work here to format the alarms appropriately based on the contents of the message.

