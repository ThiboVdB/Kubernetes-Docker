#!/usr/bin/bash
#Stop script on error
set -e

script="kubernetes.sh"
#Declare the number of mandatory args
margs=1

# Common functions - BEGIN
function example {
    echo -e "example: $script -t master"
}

function usage {
    echo -e "usage: $script -t <master-or-node>\n"
}

function help {
    usage
    echo -e "MANDATORY:"
    echo -e "  -t, --type  VAL  Specify if the current system is a Kubernetes master or node.\n"
    example
}

# Ensures that the number of passed args are at least equals
# to the declared number of mandatory args.
# It also handles the special case of the -h or --help arg.
function margs_precheck {
    if [ $2 ] && [ $1 -lt $margs ]; then
        if [ $2 == "--help" ] || [ $2 == "-h" ]; then
            help
            exit
        else
            usage
            example
            exit 1 # error
        fi
    fi
}

# Ensures that all the mandatory args are not empty
function margs_check {
    if [ $# -lt $margs ]; then
        usage
        example
        exit 1 # error
    fi
}
# Common functions - END

# Custom functions - BEGIN
function process_arguments {
    while [ -n "$1" ]
    do
        case $1 in
            -h|--help) echo "some usage details"; exit 1;;
            -x) do_something; shift; break;;
            -y) do_something_else; shift; break;;
            *) echo "some usage details"; exit 1;;
        esac
        echo $1; shift
    done
}


function update_packages {
    echo -e "${BLUE}Updating all packages${NC}"
    
    apt update -y
    apt upgrade -y
}


function install_firewalld {
    echo -e "${BLUE}Check if firewalld is installed${NC}"
    if [ $(dpkg-query -W -f='${Status}' firewalld 2>/dev/null | grep -c "ok installed") -eq 0 ];
    then
        echo "firewalld is not installed... installing now"
        apt install firewalld -y
    else
        echo "firewalld is already installed"
    fi
    
    
}

function configure_firewall {
    echo -e "${BLUE}Configuring firewall ports${NC}"

    if [ $type == "master" ];
    then
        firewall-cmd --add-port=6443/tcp --permanent
        firewall-cmd --add-port=2379-2380/tcp --permanent
        firewall-cmd --add-port=10250-10252/tcp --permanent
    else
        if [ $type == "node" ];
        then
        firewall-cmd --add-port=10250/tcp --permanent
        firewall-cmd --add-port=30000-32767/tcp --permanent
        fi
    fi
    echo -e "Reload firewall"
    firewall-cmd --reload
}

function disable_swap_memory {
    swapoff -a
    sed -e '/swap/ s/^#*/#/' -i /etc/fstab
}   

function iptables_bridge {
    cat <<-EOF | tee /etc/modules-load.d/k8s.conf
    br_netfilter
EOF

    cat <<-EOF | tee /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
EOF
    sysctl --system
}


function install_dependencies {
  repo_packages=("apt-transport-https" "curl")
    
    for pkg in ${repo_packages[@]};do
      echo -e "${BLUE}Check if $pkg is installed${NC}"
        if [ $(dpkg-query -W -f='${Status}' $pkg 2>/dev/null | grep -c "ok installed") -eq 0 ];
        then
            echo "$pkg is not installed... installing now"
            apt install $pkg -y
        else
            echo "$pkg is already installed"
        fi
    done
    
}

function add_kubernetes_gpg_key_add_repo {
    echo -e "${BLUE}Adding Kubernetes official GPG key${NC}"
    
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo -e "${BLUE}Adding Kubernetes official repository${NC}"
    cat <<-EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
    deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
}

function install_kubernetes {
    echo -e "${BLUE}Check if Kubernetes and all dependencies are installed${NC}"
    
    
    kub_packages=("kubelet" "kubeadm" "kubectl")
    
    for pkg in ${kub_packages[@]};do
        if [ $(dpkg-query -W -f='${Status}' $pkg 2>/dev/null | grep -c "ok installed") -eq 0 ];
        then
            echo "$pkg is not installed... installing now"
            apt install $pkg -y
            apt-mark hold $pkg
        else
            echo "$pkg is already installed"
        fi
    done
}

# Custom functions - END

# Main
margs_precheck $# $1

type=
# Args while-loop
while [ "$1" != "" ];
do
    case $1 in
        -t  | --type )  shift
            type=$1
        ;;
        -h   | --help )        help
            exit
        ;;
        *)
            echo "$script: illegal option $1"
            usage
            example
            exit 1 # error
        ;;
    esac
    shift
done

# Pass here your mandatory args for check
margs_check $type

# Your stuff goes here
BLUE='\033[1;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting script${NC}"
update_packages
install_firewalld
configure_firewall $type
disable_swap_memory
iptables_bridge
install_dependencies
add_kubernetes_gpg_key_add_repo
update_packages
install_kubernetes
echo -e "${BLUE}Script finished!${NC}"
