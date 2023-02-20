#!/bin/bash

# common library functions
# 12/12/22 Jason Cress (jcress@us.ibm.com)

# Verify oc is installed an in path

verifyOpenshift()
{
	which oc > /dev/null 2>&1
	if [ $? -eq 1 ]; then
	        CLUSTER="ERROR: unable to find 'oc' in path. Ensure that oc is installed and in your path"
	else
		# Verify that we are connected to openshift, and have user confirm correct cluster
		oc cluster-info > /dev/null
		if [ $? -eq 1 ]; then
			CLUSTER="ERROR: Not connected to a cluster. Please ensure you are logged into the cluster you want to deploy hybrid Event Manager to"
		else
		        CLUSTER=$(oc cluster-info |grep "control plane" |awk -F "running at" '{print $2}' 2>/dev/null)
		        correctCluster=$(getYesNo "You are currently logged into the cluster $CLUSTER. Is this the correct cluster?")
		        if [ $correctCluster -eq 0 ]; then
		                CLUSTER="ERROR: Please login to the correct cluster and restart the installation"
		        else
		                echo "Proceeding with the installation..."
		        fi
		fi
	fi
	echo $CLUSTER
}

echoerr()
{
	printf "%s\n" "$*" >&2;
}

#####################################
#
# get input without echoing to screen
#
#####################################

getSecretInput()
{
	PROMPT=$1
	DEFAULTVALUE=${@:2}
	if [ -z "$DEFAULTVALUE" ]; then
		gotinput=0
		while [ $gotinput -eq 0 ]; do
			read -s -p "$PROMPT: " USERINPUT
			if [ -z "$USERINPUT" ]; then
				echoerr "Error: this entry requires an input"
			else
				gotinput=1
				local GETINPUTRESULT=$USERINPUT
			fi
		done
	else
		read -s -p "$PROMPT (default: $DEFAULTVALUE): " USERINPUT
		if [ -z $USERINPUT ]; then
			local GETINPUTRESULT=$DEFAULTVALUE
		else
			local GETINPUTRESULT=$USERINPUT
		fi
	fi
	echoerr
	echo $GETINPUTRESULT
}

##############################
#
# Get input, echoing to screen
#
##############################

getInput()
{
	PROMPT=$1
	DEFAULTVALUE=${@:2}
	if [ -z "$DEFAULTVALUE" ]; then
		gotinput=0
		while [ $gotinput -eq 0 ]; do
			read -p "$PROMPT: " USERINPUT
			if [ -z "$USERINPUT" ]; then
				echoerr "Error: this entry requires an input"
			else
				gotinput=1
				local GETINPUTRESULT=$USERINPUT
			fi
		done
	else
		read -p "$PROMPT (default: $DEFAULTVALUE): " USERINPUT
		if [ -z $USERINPUT ]; then
			local GETINPUTRESULT=$DEFAULTVALUE
		else
			local GETINPUTRESULT=$USERINPUT
		fi
	fi
	echo $GETINPUTRESULT
}

#####################
#
# Get a yes/no answer
#
#####################

getYesNo()
{
	local GETCONFIRM=9
	PROMPT=$1

	while [ $GETCONFIRM -eq 9 ]; do
		read -p "$PROMPT (Y/n)" USERINPUT
		if [[ -z $USERINPUT || $USERINPUT = "Y" || $USERINPUT = "y" ]]; then
			local GETCONFIRM=1
		elif [[ $USERINPUT = "N" || $USERINPUT = "n" ]]; then
			local GETCONFIRM=0
		else
			echoerr "Please enter Y or N"
		fi
	done
	echo $GETCONFIRM

}

#######################################
#
# Escape special characters in a string
#
#######################################

escapeString()
{
	echo $1 | sed 's/\//\\\//g' 
}
