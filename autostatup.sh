#!/bin/bash

# Define text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
LGREEN='\033[1;32m' # Light Green
NC='\033[0m' # No Color

# Function to update the package lists, upgrade installed packages, and clean up
update_system() {
    if sudo apt update -y && sudo apt upgrade -y && sudo apt autoclean -y && sudo apt autoremove -y; then
        echo -e "${GREEN}System update completed successfully.${NC}"
    else
        echo -e "${RED}Error: Failed to update system.${NC}"
    fi
}

# Function to install sudo and wget
install_utilities() {
    if sudo apt install -y sudo wget; then
        echo -e "${GREEN}Utilities (sudo and wget) installed successfully.${NC}"
    else
        echo -e "${RED}Error: Failed to install utilities (sudo and wget).${NC}"
    fi
}

# Function to install Nginx and obtain SSL certificates
install_nginx() {
    if sudo apt install nginx -y && sudo apt install snapd -y && sudo snap install core && sudo snap install --classic certbot && sudo ln -s /snap/bin/certbot /usr/bin/certbot && sudo certbot --nginx; then
        echo -e "${GREEN}Nginx installed and SSL certificates obtained successfully.${NC}"
    else
        echo -e "${RED}Error: Failed to install Nginx or obtain SSL certificates.${NC}"
    fi
}

# Function to install x-ui
install_x_ui() {
    if bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh); then
        echo -e "${GREEN}x-ui installed successfully.${NC}"
    else
        echo -e "${RED}Error: Failed to install x-ui.${NC}"
    fi
}

# Function to install Telegram MTProto proxy
install_telegram_proxy() {
    if curl -L -o mtp_install.sh https://git.io/fj5ru && bash mtp_install.sh; then
        echo -e "${GREEN}Telegram MTProto proxy installed successfully.${NC}"
    else
        echo -e "${RED}Error: Failed to install Telegram MTProto proxy.${NC}"
    fi
}

# Function to install OpenVPN
install_openvpn() {
    if curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh && chmod +x openvpn-install.sh && ./openvpn-install.sh; then
        echo -e "${GREEN}OpenVPN installed successfully.${NC}"
    else
        echo -e "${RED}Error: Failed to install OpenVPN.${NC}"
    fi
}

# Function to create a swap file
create_swap() {
    read -p "Choose swap size (512M or 1G): " swap_size
    case $swap_size in
        512M)
            if sudo fallocate -l 512M /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile && echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab; then
                echo -e "${GREEN}Swap file created successfully.${NC}"
            else
                echo -e "${RED}Error: Failed to create swap file.${NC}"
            fi
            ;;
        1G)
            if sudo fallocate -l 1G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile && echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab; then
                echo -e "${GREEN}Swap file created successfully.${NC}"
            else
                echo -e "${RED}Error: Failed to create swap file.${NC}"
            fi
            ;;
        *)
            echo -e "${RED}Invalid choice. Please choose either 512M or 1G.${NC}"
            ;;
    esac
}

# Function to change SSH port
change_ssh_port() {
    read -p "Enter the new SSH port: " new_ssh_port
    if sudo sed -i "s/#Port 22/Port $new_ssh_port/g" /etc/ssh/sshd_config && sudo systemctl restart ssh; then
        echo -e "${GREEN}SSH port changed successfully.${NC}"
    else
        echo -e "${RED}Error: Failed to change SSH port.${NC}"
    fi
}

# Function to add a cron job to reboot the system every 2 days
schedule_reboot() {
    if (crontab -l ; echo "0 0 */2 * * sudo /sbin/reboot") | crontab -; then
        echo -e "${GREEN}Scheduled system reboot every 2 days.${NC}"
    else
        echo -e "${RED}Error: Failed to schedule system reboot.${NC}"
    fi
}

# Function to optimize VPS for x-ui proxy
optimize_vps_for_x_ui_proxy() {
    if sudo nano /etc/sysctl.conf && cat <<EOF >> /etc/sysctl.conf
# Enable TCP window scaling
net.ipv4.tcp_window_scaling = 1

# Increase TCP buffer sizes
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Decrease the time default value for tcp_fin_timeout connection
net.ipv4.tcp_fin_timeout = 15

# Turn on window scaling which can enlarge the transfer window.
net.ipv4.tcp_window_scaling = 1

# Enable timestamps as defined in RFC1323.
net.ipv4.tcp_timestamps = 1

# Increase TCP max buffer size
net.ipv4.tcp_mem = 16777216 16777216 16777216
EOF
     sudo sysctl -p; then
        echo -e "${GREEN}VPS optimized for x-ui proxy successfully.${NC}"
    else
        echo -e "${RED}Error: Failed to optimize VPS for x-ui proxy.${NC}"
    fi
}

# Function for firewall management
firewall_management() {
    while true; do
        echo -e "${LGREEN}===== Firewall Management =====${NC}"
        echo -e " ${YELLOW}1.${NC} View open ports"
        echo -e " ${YELLOW}2.${NC} Add port(s)"
        echo -e " ${YELLOW}3.${NC} Delete port(s)"
        echo -e " ${YELLOW}4.${NC} Enable/Disable UFW"
        echo -e " ${YELLOW}0.${NC} Back"
        echo -e "${LGREEN}===============================${NC}"
        read -p "Enter your choice: " firewall_choice
        case $firewall_choice in
            1) view_open_ports ;;
            2) add_ports ;;
            3) delete_ports ;;
            4) enable_disable_ufw ;;
            0) break ;;
            *) echo -e "${RED}Invalid choice. Please enter a number between 0 and 4.${NC}" ;;
        esac
    done
}

# Function to view open ports
view_open_ports() {
    sudo netstat -tuln
}

# Function to add ports
add_ports() {
    read -p "Enter port(s) to add (comma-separated): " ports
    IFS=',' read -r -a port_array <<< "$ports"
    for port in "${port_array[@]}"; do
        if sudo ufw allow "$port"; then
            echo -e "${GREEN}Port $port added successfully.${NC}"
        else
            echo -e "${RED}Error: Failed to add port $port.${NC}"
        fi
    done
}

# Function to delete ports
delete_ports() {
    read -p "Enter port(s) to delete (comma-separated): " ports
    IFS=',' read -r -a port_array <<< "$ports"
    for port in "${port_array[@]}"; do
        if sudo ufw delete allow "$port"; then
            echo -e "${GREEN}Port $port deleted successfully.${NC}"
        else
            echo -e "${RED}Error: Failed to delete port $port.${NC}"
        fi
    done
}

# Function to enable/disable UFW
enable_disable_ufw() {
    read -p "Enable or Disable UFW? (enable/disable): " ufw_choice
    case $ufw_choice in
        enable)
            if sudo ufw enable; then
                echo -e "${GREEN}UFW enabled successfully.${NC}"
            else
                echo -e "${RED}Error: Failed to enable UFW.${NC}"
            fi
            ;;
        disable)
            if sudo ufw disable; then
                echo -e "${GREEN}UFW disabled successfully.${NC}"
            else
                echo -e "${RED}Error: Failed to disable UFW.${NC}"
            fi
            ;;
        *)
            echo -e "${RED}Invalid choice. Please enter 'enable' or 'disable'.${NC}"
            ;;
    esac
}

# Function to display menu
display_menu() {
    echo -e "${LGREEN}========== Menu ==========${NC}"
    echo -e " ${YELLOW}1.${NC} Update system"
    echo -e " ${YELLOW}2.${NC} Install utilities (sudo and wget)"
    echo -e " ${YELLOW}3.${NC} Install Nginx and obtain SSL certificates"
    echo -e " ${YELLOW}4.${NC} Install x-ui"
    echo -e " ${YELLOW}5.${NC} Install Telegram MTProto proxy"
    echo -e " ${YELLOW}6.${NC} Install OpenVPN"
    echo -e " ${YELLOW}7.${NC} Create swap file"
    echo -e " ${YELLOW}8.${NC} Change SSH port"
    echo -e " ${YELLOW}9.${NC} Schedule system reboot every 2 days"
    echo -e " ${YELLOW}10.${NC} Optimize VPS for x-ui proxy"
    echo -e " ${YELLOW}11.${NC} Firewall Management"
    echo -e " ${YELLOW}0.${NC} Exit"
    echo -e "${LGREEN}==========================${NC}"
}

# Main script
while true; do
    display_menu
    read -p "Enter your choice: " choice
    case $choice in
        1) update_system ;;
        2) install_utilities ;;
        3) install_nginx ;;
        4) install_x_ui ;;
        5) install_telegram_proxy ;;
        6) install_openvpn ;;
        7) create_swap ;;
        8) change_ssh_port ;;
        9) schedule_reboot ;;
        10) optimize_vps_for_x_ui_proxy ;;
        11) firewall_management ;;
        0) echo -e "${LGREEN}Exiting...${NC}"; break ;;
        *) echo -e "${RED}Invalid choice. Please enter a number between 0 and 11.${NC}" ;;
    esac
done
