#!/bin/bash

#
# This script has been tested to run on Ubuntu Server 18.04
#
# It is not intended to be run manually (it's invoked by a different script)
#
# Head over to the README for detailed instructions
#

GITHUB_SPINUP_KEY_FILE=github_spinup_ssh.key
JENKINS_JOB_KEY_FILE=jenkins_ci_ssh.key
JENKINS_SPINUP_REPO=jenkins-spinup
# allow time to paste key into github, but skip timeout on second try
SSH_KEY_LINUX_BOX_COPY_TIMEOUT_SECONDS=0
SSH_KEY_JENKINS_COPY_TIMEOUT_SECONDS=0


#
#
# Update instance
#
#

echo "running 02_ubuntu.sh";

# keep security up to date
sudo apt update
sudo apt upgrade


#
#
# CREATE SSH KEY PAIR FOR GITHUB AND CLONE JENKINS-SPINUP REPO
#
#

if ! test -f "$GITHUB_SPINUP_KEY_FILE.pub"; then # only do this is we haven't already generated the key file

    # create a new ssh key pair
    echo | ssh-keygen -t rsa -b 4096 -C "ssh key pair, linux box -> github, in order to clone spin up repo" -f "$GITHUB_SPINUP_KEY_FILE" -P '';

    # allow time to past key into github
    SSH_KEY_LINUX_BOX_COPY_TIMEOUT_SECONDS=120

    # move the private key to ~./.ssh
    mkdir -p ~/.ssh;
    mv $GITHUB_SPINUP_KEY_FILE ~/.ssh;
fi

# start the ssh-agent and add the private key so that we can clone from github
eval "$(ssh-agent -s)";
ssh-add ~/.ssh/$GITHUB_SPINUP_KEY_FILE;

# display the contents of the github public key, prompt user to copy and paste it into the github web UI
echo -e '\033[32;m\n-----------------------------------------------------------\n'
echo -e '                     ACTION REQUIRED\n'
echo -e 'Copy and paste the following public ssh key paragraph (all'
echo -e 'the red text) into github, so that this [linux box] can clone'
echo -e 'the '${JENKINS_SPINUP_REPO}' repo:\n\033[31;m'
cat $GITHUB_SPINUP_KEY_FILE.pub
echo -e '\n\033[0;m'
read -n 1 -s -r -p "Press any key to confirm you have pasted the linux box public ssh key into github..." -t $SSH_KEY_LINUX_BOX_COPY_TIMEOUT_SECONDS

if ! test -d "$JENKINS_SPINUP_REPO"; then # only do this is we haven't already cloned the repo
  # add github to known hosts file
  ssh-keyscan -H github.com >> ~/.ssh/known_hosts
  # clone this repo
  git clone git@github.com:erdo/$JENKINS_SPINUP_REPO.git
  # switch to feature branch if developing script changes
  # git checkout --track origin/feature/erdo_new_thing
fi

if ! test -d "$JENKINS_SPINUP_REPO"; then # if there is still no jenkins-setup folder, we don't continue
  echo 'Error no folder found, did repo clone correctly?'
  exit 1
fi

# move the jenkins.env file, and cd into the newly cloned jenkins-spinup folder
mv jenkins.env $JENKINS_SPINUP_REPO
cd $JENKINS_SPINUP_REPO
git pull


#
#
# INSTALL DOCKER ON LINUX BOX
#
#

# let apt use packages over HTTPS
echo y | sudo apt install apt-transport-https ca-certificates curl software-properties-common

# add the GPG key for the official Docker repository to your system
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# add the Docker repository to APT sources for Ubuntu 18 (bionic)
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

# update the package database with the Docker packages from the newly added repo
sudo apt update

# ensure we will install from the Docker repo instead of the default Ubuntu repo
apt-cache policy docker-ce

# install docker
echo Y | sudo apt install docker-ce

# install docker-compose
echo Y | sudo apt install docker-compose


#
#
# FIND IP ADDRESS, CREATE SSH KEY PAIR FOR JENKINS
#
#

# call public ifconfig service at ifconfig.co to get ip address (this call is rate limited btw)
export IP_ADDRESS=$(curl -s ifconfig.co)
export JENKINS_URL="http://${IP_ADDRESS}:8080"

if ! test -f "../$JENKINS_JOB_KEY_FILE"; then # only do this if we haven't already generated the key file
    # create jenkins ssh key pair
    echo | ssh-keygen -t rsa -b 4096 -C "ssh key pair, jenkins jobs -> github, in order to clone job repos" -f "../$JENKINS_JOB_KEY_FILE" -P '';
    # allow time to past key into github
    SSH_KEY_JENKINS_COPY_TIMEOUT_SECONDS=120
fi


#
#
# CREATE DOCKER IMAGE AND DEPLOY IT
#
#

# add current user to the docker group
sudo usermod -aG docker ${USER}

# make the final script executable
chmod u+x 03_docker.sh;

# using heredoc block means we don't have to log out and log back in to be in the docker group
newgrp docker << HEREDOCSBLOCK
  bash ./03_docker.sh;
HEREDOCSBLOCK

# display the contents of the jenkins public key, prompt user to copy and paste it into the github web UI
set GREEN_COLOUR='\033[32;m'
set RED_COLOUR='\033[31;m'
set NO_COLOUR='\033[0;m'
echo -e '\033[32;m\n-----------------------------------------------------------\n'
echo -e '                     ACTION REQUIRED \n'
echo -e 'Ensure the authorization callback URL on your github oauth'
echo -e 'app (in developer settings) is:\033[31;m'
echo -e '\n'$JENKINS_URL'/securityRealm/finishLogin\n\033[32;m'
echo -e 'Copy and paste the following public ssh key paragraph (all'
echo -e 'the red text) into github, so that [jenkins jobs] can clone'
echo -e 'github repositories (this is not the same as the previous'
echo -e 'ssh key):\n\033[31;m'
cat ../$JENKINS_JOB_KEY_FILE.pub
echo -e '  \n\033[0;m'

read -n 1 -s -r -p "Press any key to confirm you have set the oauth callback URL, and pasted the jenkins public ssh key into github..."  -t $SSH_KEY_JENKINS_COPY_TIMEOUT_SECONDS

# use the wait-for-it script to wait until our jenkins instance is publicly accessible:
chmod u+x wait-for-it.sh
./wait-for-it.sh ${IP_ADDRESS}:8080 --timeout=60

# store exit status of wait-for-it script
status=$?
if test $status -eq 0
then
  # wait for a little, jenkins won't actually be ready yet
  sleep 25
  # tidy up, delete private keys
  # rm ../jenkins_ci_ssh.key
  echo -e '\033[32;m\nCongratulations, you can now access jenkins at '${JENKINS_URL}'\033[0;m\n'
  exit 0
else
  echo "timeout waiting for jenkins, check logs"
  exit 1
fi
