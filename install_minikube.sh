#! /bin/bash

#################################################################################################################################
#
#            Script : Install minikube on debian
#            Version : 1.0.0
#            But :
#                - check for virtualisation capability of the host
#                - Install minikube
#                - Create a new user for minikube
#                - Silly output ;)
#
#            Revision :
#                - (V1.0.0) Initial creation of the script
#
#           Author: Antoine DELORME
#           Revision : Antoine DELORME
#
#################################################################################################################################

## Show the script usage when called ##
script_usage() {
  printf "List of arguments or options for $0
  OPTIONS :
  -v|--hypervisor : select what hypervisor you'll use for minikube (use the same syntax as below !) :
\t - kvm
\t - virtualbox
  -i|--installer : select your prefered installer between those 2 (use the same syntax as below !) :
\t - brew
\t - snapd
  -w|--whatthewhat : show what will be installed
  -h|--help$ : Show this screen\n"
}

# Function to install kubectl
install_kubectl() {
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
   echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

   chmod +x kubectl
   sudo mkdir -p ~/.local/bin
   sudo mv ./kubectl ~/.local/bin/kubectl
   export PATH=$PATH:~/.local/bin/kubectl

   printf "You might want to reload the shell for the path to work.\n\n"
}

# Function to check if the host can virtualise.
check_virtu() {
   printf "Well, let's check if you're running me on a rust bucket or a hot rod.\n\n"
   if [[ $(grep -E --color 'vmx|svm' /proc/cpuinfo) ]]; then
      printf "You can virtualize, who's a big boy :D. Let's install minikube \\o/\n\n"
   else
      printf "hmmm, that's quite embarrasing... It seems your computer is quite old, or you're virtualizing a linux. Anyway, you can't virtualize here...\n
      so no minikube for you è_é\n\n"
      exit 1
   fi
}

# Function to install docker

install_docker() {
    # Update package information
    sudo apt-get update

    # Install packages to allow apt to use a repository over HTTPS
    sudo apt-get install -y -q\
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Set up the stable repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update the package index again with the Docker packages
    sudo apt-get update -q

    # Install Docker Engine
    sudo apt-get install -y -q docker-ce docker-ce-cli containerd.io

    # Verify that Docker Engine is installed correctly
    sudo docker run hello-world
}

# function to install KVM
install_kvm() {
   printf "You've chosen wisely.
   Let's install KVM :"
   sudo apt -y -q install qemu-kvm libvirt-daemon-system libvirt-daemon virtinst bridge-utils libosinfo-bin

   printf "As some configuration is required, let's do that too 
   (you can edit those later if it's not to your taste)\n"

    sudo tee /etc/netplan/01-netcfg.yaml > /dev/null <<EOF
network:
  ethernets:
    enp1s0:
      dhcp4: false
      # disable existing configuration for ethernet
      #addresses: [10.0.0.30/24]
      #routes:
      #  - to: default
      #    via: 10.0.0.1
      #    metric: 100
      #nameservers:
      #  addresses: [10.0.0.10]
      #  search: [srv.world]
      dhcp6: false
  # add configuration for bridge interface
  # [macaddress] ⇒ specify HW address of enp1s0
  bridges:
    br0:
      interfaces: [enp1s0]
      dhcp4: false
      addresses: [10.0.0.30/24]
      macaddress: 52:54:00:db:f8:fe
      routes:
        - to: default
          via: 10.0.0.1
          metric: 100
      nameservers:
        addresses: [10.0.0.10]
        search: [srv.world]
      parameters:
        stp: false
      dhcp6: false
  version: 2
EOF

   printf "The config is done. Let's apply all this crap\n"
   
   sudo netplan apply

   printf "well, I am doing all the work, but do something at least, check if it's good for you !!!\n\n"

   sudo ip address show

   printf "KVM installed, noice, I'm that good.\n\n"
}

# Function install minikube 
install_minikube() {
   ## Set the revolv.conf, since debian is shit with that
   # Create a temporary resolv.conf file
   printf "nameserver 8.8.8.8" > /tmp/resolv.conf
   # Move the temporary file to the correct location with sudo
   sudo mv /tmp/resolv.conf /etc/resolv.conf
   sudo systemctl restart systemd-resolved
   
   printf "So let's go, let's install minikube with the parameter you've selected : \n\n"
   case $installer in
      brew)
         brew install minikube
      ;;
      *)
         case $hypervisor in
         kvm)
#            printf "######################\n\ninstall minikube : in the case for hyperV\n\n######################\n\n"
            wget http://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 -O minikube
            wget http://storage.googleapis.com/minikube/releases/latest/docker-machine-driver-kvm2
            chmod 755 minikube docker-machine-driver-kvm2
            sudo mv minikube docker-machine-driver-kvm2 /usr/local/bin
         ;;
         *)                  
            curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
            sudo install minikube-linux-amd64 /usr/local/bin/minikube
         ;;
         esac
      ;;
   esac

   printf "So everything is done, let's check the version\n\n"
   minikube version


}

# Show what will be installed
whatthewhat() {
   printf "What will be installed :
   - An hypervisor (kvm or virtualbox)
   - minikube
   - kvm (needed. If not asked, it'll install docker)
   - snapd (optional)
   - brew (optional)
   - kubectl
   - some self esteem"
}


start_minikube() {
   case $hypervisor in
   kvm)
      minikube start --vm-driver=kvm2
   ;;
   *)
      minikube start --driver=docker
   ;;
   esac
}

check_and_install_brew() {
  if ! command -v brew &>/dev/null; then
    printf "Homebrew is not installed. Installing Homebrew..."
    sudo apt update -q
    sudo apt install -y -q build-essential curl file git
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    printf 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.profile
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  else
    printf "Homebrew is already installed."
  fi
}

check_and_install_snapd() {
  if ! command -v snap &>/dev/null; then
    printf "snapd is not installed. Installing snapd..."
    sudo apt update -q
    sudo apt install -y -q snapd
    sudo systemctl enable --now snapd.socket
    sudo systemctl enable --now snapd.seeded.service
    sudo snap install core
  else
    printf "snapd is already installed."
  fi
}

I_kick_ass_for_the_lord() {
    # Remove KVM
    printf "Checking for KVM...\n"
    if [ -x "$(command -v kvm-ok)" ] || [ -x "$(command -v kvm)" ]; then
        printf "Removing KVM...\n"
        sudo apt-get purge -y -q qemu-kvm libvirt-daemon-system libvirt-daemon virtinst bridge-utils libosinfo-bin
        sudo apt-get autoremove -y -q
        printf "KVM removed successfully.\n"
    else
        printf "KVM is not installed.\n"
    fi

    # Remove Minikube
    printf "Checking for Minikube...\n"
    if [ -x "$(command -v minikube)" ]; then
        printf "Removing Minikube...\n"
        minikube delete
        sudo apt-get purge -y -q minikube
        sudo rm -rf /usr/local/bin/minikube
        sudo rm -rf ~/.minikube
        sudo rm -rf /etc/kubernetes
        sudo rm -rf ~/.kube
        printf "Minikube removed successfully.\n"
    else
        printf "Minikube is not installed.\n"
    fi

    printf "Cleanup complete.\n"
}

############################################
# main function calling all other function #
############################################
main() {
   # List what will be done
   #whatthewhat
   printf "Enjoy your installation with a coffee, a mojito, or simply with a suspicious look\n\n"
   # temporisation
   sleep 2
   check_virtu
   # temporisation
   sleep 2
   case $hypervisor in
   kvm)
      printf "Let's install kvm, as it's what you want pup ! \n"
      hyperv="kvm2"
      if [ -x "$(command -v kvm)" ] || [ -x "$(command -v kvm-ok)" ]; then
         printf "KVM is already installed.\n\n"
      else
         printf "KVM is not installed. Installing KVM kamarade...\n\n"
         install_kvm
      fi
   ;;
   *)
      printf "No hypervisor selected.\nBy default docker will be used and installed if not already installed (this might need some twickering)\n\n"
      hyperv="docker"
      if [[ -x "$(command -v docker)" ]]; then
         printf "You lucky devil, Docker is already installed !\n\n"
      else  
         echo "Docker is not installed. Installing Docker...\n\n"
         install_docker
      fi
   ;;
   esac 
   # temporisation
   sleep 2
   case $installer in
   snapd)
      check_and_install_snapd
   ;;
   brew)
      check_and_install_brew
   ;;
   esac
   # edit permission

   sudo usermod -aG libvirt $(whoami)
   # Re-execute the script with new group
   if ! groups "$(whoami)" | grep -q '\blibvirt\b'; then
      # Re-execute the script with new group
      exec sg libvirt "$(realpath "$0 $*")"
   fi
   # temporisation
   sleep 2
   install_minikube
   # temporisation
   sleep 2
   start_minikube
   sleep 2
   install_kubectl
   sleep 2
   printf "As I am a benevolent god, here the dashboard started ;)\n\n"
   #minikube dashboard --url
}

#########################################################
######################### MAIN ##########################
#########################################################
#     The main will check if the connection with the    #
#    database is up, and proceed to the main function   #
#########################################################

TEMP=`getopt -o v:i:wrh --long hyperv:installer:whatthewhat,remove,help -n 'install_minikube_linux.sh' -- "$@"`
eval set -- "$TEMP"

# extract options and their arguments into variables.
while true ; do
   case "$1" in
      -v|--hyperv)
         if [[ ${2} == "kvm" ]]; then
            hypervisor=${2}
         else
            printf "Unknown option: -${2}\n\t for more information try ${0} -h or ${0} --help\n"
            script_usage
            exit 1
         fi
         shift 2
      ;;
      -i|--installer)
         if [[ ${2} == "brew" ]]; then
            installer=${2}
         else
            printf "Unknown option: -${2}\n\t for more information try ${0} -h or ${0} --help\n"
            script_usage
            exit 1
         fi
         shift 2
      ;;
      -w|--whatthewhat)
         whatthewhat
         exit 0
      ;;
      -r|--remove)
         I_kick_ass_for_the_lord
         exit 0
      ;;
      -h|--help)
         script_usage
         exit 1
      ;;
      \?) # Non recognize option (outside of the given scope)
         printf "Unknown option: -${2}\n\t for more information try ${0} -h or ${0} --help\n"
         exit 1
      ;;
      :) # No arguement given when option needs one
         printf "Missing option argument for -${2}\n"
         exit 1
      ;;
      --)
         shift
         break
         # printf "\n${red}UNKNOW OPTIONS${end}\n\n"
         # script_usage
         # exit 1
      ;;
      *) # any error outside of the 2 before this
         printf "\n${red} UNEXPECTED ERROR ${end}\n\n"
         script_usage
         exit 1
      ;;
   esac
done

# Call the main function
main
