#!/bin/bash

#
# Preconditions:
#
# - you have read the README
# - you are running this on a mac
# - you have cloned the jenkins-spinup repo
# - you have access to a remote linux box
# - you have a private ssh pem or key file for that linux box
# - you have named that file: linuxbox_ssh.key
# - you have created an appropriate jenkins.env file
# - you may have to make this script executable: chmod u+x 01_mac.sh
#
# Usage:
#      ./01_mac.sh ubuntu@ec2-blah-blah-blah.eu-west-3.compute.amazonaws.com
#
#

SSH_ADDRESS=$1
SSH_PRIVATE_KEY_FILE=linuxbox_ssh.key
JENKINS_ENV_FILE=jenkins.env
NEXT_SCRIPT_FILE=02_ubuntu.sh
DOCKER_SCRIPT_FILE=03_docker.sh

echo "running 01_mac.sh";

# check the SSH details of the linux box were specified
if [ -z $SSH_ADDRESS ]
then
    echo -e "\033[31;mNo SSH address specified\033[0;m"
    echo -e "\033[32;m    usage: ./01_mac.sh ubuntu@ec2-blah-blah-blah.eu-west-3.compute.amazonaws.com\033[0;m"
    exit 1
fi

# check linuxbox_privatessh.key file is present
if ! test -f "$SSH_PRIVATE_KEY_FILE"; then
  echo -e "\033[31;m$SSH_PRIVATE_KEY_FILE is missing, see README\033[0;m"
  exit 1
fi

# check jenkins.env file is present
if test ! -f "$JENKINS_ENV_FILE"; then
    echo -e "\033[31;m$JENKINS_ENV_FILE is missing, see README\033[0;m"
    exit 1
fi

# check 02_ubuntu.sh file is present
if test ! -f "$NEXT_SCRIPT_FILE"; then
    echo -e "\033[31;m$NEXT_SCRIPT_FILE is missing, see README\033[0;m"
    exit 1
fi

# check 03_docker.sh file is present
if test ! -f "$DOCKER_SCRIPT_FILE"; then
    echo -e "\033[31;m$DOCKER_SCRIPT_FILE is missing, see README\033[0;m"
    exit 1
fi

# make sure the private key is readable:
chmod 600 $SSH_PRIVATE_KEY_FILE

# transfer jenkins.env file and the next script to the remote box using scp
scp -v -i $SSH_PRIVATE_KEY_FILE $JENKINS_ENV_FILE $NEXT_SCRIPT_FILE $SSH_ADDRESS:~/.

# ssh into the linux box and run the next script
ssh -t -v -i $SSH_PRIVATE_KEY_FILE $SSH_ADDRESS "chmod u+x $NEXT_SCRIPT_FILE; bash ./$NEXT_SCRIPT_FILE;"

# store exit status of ssh
status=$?
# audible alert that things are finished
if test $status -eq 0
then
  say -v Moira "jenkins spinup is complete"
else
	say -v Moira "fail, did you remember to copy ssh keys to git hub?"
fi
