!/bin/bash

# Function to update the package lists, upgrade installed packages, and clean up
update_system() {
    echo "Updating system..."
    sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt autoclean -y && sudo apt autoremove -y
   #  echo "System update complete."
}

# Function to install sudo and wget if not already installed
install_utilities() {
    echo "Installing utilities (sudo and wget)..."
    if ! command -v sudo &>/dev/null; then
        sudo apt install -y sudo
    fi
    if ! command -v wget &>/dev/null; then
        sudo apt install -y wget
    fi
    echo "Utilities installation complete."
}

# Function to install Nginx and obtain SSL certificates
install_nginx() {
    echo "Installing Nginx and obtaining SSL certificates..."
    sudo apt install -y nginx snapd
    sudo snap install core && sudo snap install --classic certbot
    sudo ln -s /snap/bin/certbot /usr/bin/certbot
    sudo certbot --nginx
    echo "Nginx installation and SSL certificate acquisition complete."
}

# Function to install x-ui
install_x_ui() {
    echo "Installing x-ui..."
    bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
    echo "x-ui installation complete."
}

# Function to install Telegram MTProto proxy
install_telegram_proxy() {
    echo "Installing Telegram MTProto proxy..."
    curl -L -o mtp_install.sh https://git.io/fj5ru && bash mtp_install.sh
    echo "Telegram MTProto proxy installation complete."
}

# Function to install OpenVPN
install_openvpn() {
    echo "Installing OpenVPN..."
    curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
    chmod +x openvpn-install.sh
    ./openvpn-install.sh
    echo "OpenVPN installation complete."
}

# Function to create a swap file
create_swap() {
    echo "Creating swap file..."
    read -p "Choose swap size (512M or 1G): " swap_size
    case $swap_size in
        512M) create_swap_file 512M ;;
        1G) create_swap_file 1G ;;
        *) echo "Invalid choice. Please choose either 512M or 1G." ;;
    esac
}

# Function to create a swap file with specified size
create_swap_file() {
    local size=$1
    sudo fallocate -l $size /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
    echo "$size swap file created and enabled."
}

# Function to change SSH port and add rate limiting for SSH connections
change_ssh_port() {
    echo "Changing SSH port..."
    read -p "Enter the new SSH port: " new_ssh_port
    if [[ $new_ssh_port =~ ^[0-9]+$ ]]; then
        sudo sed -i "s/#Port 22/Port $new_ssh_port/g" /etc/ssh/sshd_config
        sudo ufw limit $new_ssh_port/tcp comment 'SSH rate limit'
        sudo systemctl restart ssh
        sudo systemctl restart ufw
        echo "SSH port changed to $new_ssh_port and rate limiting enabled."
    else
        echo "Invalid port number."
    fi
}

# Function to add a cron job to reboot the system every 2 days
schedule_reboot() {
    echo "Scheduling system reboot every 2 days..."
    (crontab -l ; echo "0 0 */2 * * sudo /sbin/reboot") | crontab -
    echo "Cron job added to reboot the system every 2 days."
}

# Function to optimize VPS for x-ui proxy
optimize_vps_for_x_ui_proxy() {
    echo "Optimizing VPS for x-ui proxy..."
    echo "# Enable TCP window scaling" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_window_scaling = 1" | sudo tee -a /etc/sysctl.conf
    echo "# Increase TCP buffer sizes" | sudo tee -a /etc/sysctl.conf
    echo "net.core.rmem_default = 262144" | sudo tee -a /etc/sysctl.conf
    echo "net.core.rmem_max = 16777216" | sudo tee -a /etc/sysctl.conf
    echo "net.core.wmem_default = 262144" | sudo tee -a /etc/sysctl.conf
    echo "net.core.wmem_max = 16777216" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_rmem = 4096 87380 16777216" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_wmem = 4096 65536 16777216" | sudo tee -a /etc/sysctl.conf
    echo "# Decrease the time default value for tcp_fin_timeout connection" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_fin_timeout = 15" | sudo tee -a /etc/sysctl.conf
    echo "# Turn on window scaling which can enlarge the transfer window." | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_window_scaling = 1" | sudo tee -a /etc/sysctl.conf
    echo "# Enable timestamps as defined in RFC1323." | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_timestamps = 1" | sudo tee -a /etc/sysctl.conf
    echo "# Increase TCP max buffer size" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_mem = 16777216 16777216 16777216" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    echo "Optimization complete."
}

# Function to display menu
display_menu() {
    echo "========== Menu =========="
    echo "1. Update system"
    echo "2. Install utilities (sudo and wget)"
    echo "3. Install Nginx and obtain SSL certificates (includes snapd)"
    echo "4. Install x-ui"
    echo "5. Install Telegram MTProto proxy"
    echo "6. Install OpenVPN"
    echo "7. Create swap file"
    echo "8. Change SSH port"
    echo "9. Schedule system reboot every 2 days"
    echo "10. Optimize VPS for x-ui proxy"
    echo "11. Reboot system"
    echo "0. Exit"
    echo "=========================="
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
        11) sudo reboot ;;
        0) echo "Exiting..."; break ;;
        *) echo "Invalid choice. Please enter a number between 0 and 11." ;;
    esac
done
