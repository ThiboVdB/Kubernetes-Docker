#!/usr/bin/bash
#Stop script on error
set -e

script="docker.sh"
#Declare the number of mandatory args
margs=0

# Common functions - BEGIN
function example {
    echo -e "example: $script"
}

function usage {
    echo -e "usage: $script [-u, --username]\n"
}

function help {
    usage
    echo -e "OPTIONAL:"
    echo -e "  -u, --username  VAL  Specify an optional username to be added to the docker users group.\n"
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

# function install_firewalld {
#     echo -e "${BLUE}Check if firewalld is installed${NC}"
#     if [ $(dpkg-query -W -f='${Status}' firewalld 2>/dev/null | grep -c "ok installed") -eq 0 ];
#     then
#         echo "firewalld is not installed... installing now"
#         apt install firewalld -y
#     else
#         echo "firewalld is already installed"
#     fi
    
    
# }

function update_packages {
    echo -e "${BLUE}Updating all packages${NC}"
    
    apt update -y
    apt upgrade -y
}

function setup_repository {
  
    
  repo_packages=("apt-transport-https" "ca-certificates" "curl" "gnupg-agent" "software-properties-common")
    
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

function add_docker_gpg_key {
    echo -e "${BLUE}Adding Docker's official GPG key${NC}"
    
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
}

# function check_repo_fingerprint {
#     echo -e "${BLUE}Adding Docker's official GPG key${NC}"
    
#     apt-key fingerprint 0EBFCD88
# }

# function configure_firewall_http_https {
#     echo -e "${BLUE}Configuring firewall ports for HTTP and HTTPS${NC}"
#     firewall-cmd --add-port=80/tcp --permanent
#     firewall-cmd --add-port=443/tcp --permanent
#     echo -e "Reload firewall"
#     firewall-cmd --reload
# }

function add_docker_apt_repo {
  #  echo -e "${BLUE}Check if mysql is installed${NC}"
    
   add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
    
}

function install_docker {
    echo -e "${BLUE}Check if Docker and all dependencies are installed${NC}"
    
    
    php_packages=("docker-ce" "docker-ce-cli" "containerd.io")
    
    for pkg in ${php_packages[@]};do
        if [ $(dpkg-query -W -f='${Status}' $pkg 2>/dev/null | grep -c "ok installed") -eq 0 ];
        then
            echo "$pkg is not installed... installing now"
            apt install $pkg -y
        else
            echo "$pkg is already installed"
        fi
    done
}

function add_curr_user_to_group {
    echo -e "${BLUE}Adding current user to Docker group${NC}"

    if [$1 != ""];
    then
        usermod -aG docker $username
    else
        usermod -aG docker ${USER}
    fi
}
# function install_phpmyadmin {
#     apt install phpmyadmin php-mbstring php-zip php-gd php-json php-curl -y
# }

# function restart_enable_services {
    
    
#     services=("apache2" "mysql")
    
#     for serv in ${services[@]};do
#         echo -e "${BLUE}Check if $serv is enabled${NC}"
#         if [ $(systemctl is-enabled $serv 2>/dev/null | grep -c "enabled") -eq 0 ];
        
#         then
#             echo "$serv is not enabled... enabling now"
#             systemctl enable $serv
#         else
#             echo "$serv is already enabled"
#         fi
#         echo -e "Restarting $serv"
#         systemctl restart $serv
        
#     done
    
# }

# function configure_mysql {
#     echo -e "${BLUE}Configuring mysql with provided credentials${NC}"
#     mysql -u root --execute="USE mysql; UPDATE user SET plugin='mysql_native_password' WHERE User='root'; FLUSH PRIVILEGES;"
#     mysql -u root --execute="CREATE USER IF NOT EXISTS '$username'@'localhost' IDENTIFIED WITH mysql_native_password BY '$password'; "
#     mysql -u root --execute="GRANT ALL PRIVILEGES ON *.* to '$username'@'localhost';"
# }

# function configure_firewall_mysql {
#     echo -e "${BLUE}Configuring firewall port for mysql${NC}"
#     echo -e "Reload firewall"
#     firewall-cmd --add-port=3306/tcp --permanent
#     firewall-cmd --reload
# }
# Custom functions - END

# Main
margs_precheck $# $1

username=
# password=
# # Args while-loop
while [ "$1" != "" ];
do
    case $1 in
        -u  | --username )  shift
            username=$1
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
# margs_check $username $password

# Your stuff goes here
BLUE='\033[1;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting script${NC}"
update_packages
setup_repository
add_docker_gpg_key
add_docker_apt_repo
install_docker
add_curr_user_to_group $1
echo -e "${BLUE}Script finished! Run 'docker run hello-world' to test your installation!${NC}"
