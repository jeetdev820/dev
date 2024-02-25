!/bin/bash

# Function to update the package lists, upgrade installed packages, and clean up
update_system() {
    if sudo apt update -y && sudo apt upgrade -y && sudo apt autoclean -y && sudo apt autoremove -y; then
        echo "System update completed successfully."
    else
        echo "Error: Failed to update system."
    fi
}

# Function to install sudo and wget
install_utilities() {
    if sudo apt install -y sudo wget; then
        echo "Utilities (sudo and wget) installed successfully."
    else
        echo "Error: Failed to install utilities (sudo and wget)."
    fi
}

# Function to install Nginx and obtain SSL certificates
install_nginx() {
    if sudo apt install nginx -y && sudo apt install snapd -y && sudo snap install core && sudo snap install --classic certbot && sudo ln -s /snap/bin/certbot /usr/bin/certbot && sudo certbot --nginx; then
        echo "Nginx installed and SSL certificates obtained successfully."
    else
        echo "Error: Failed to install Nginx or obtain SSL certificates."
    fi
}

# Function to install x-ui
install_x_ui() {
    if bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh); then
        echo "x-ui installed successfully."
    else
        echo "Error: Failed to install x-ui."
    fi
}

# Function to install Telegram MTProto proxy
install_telegram_proxy() {
    if curl -L -o mtp_install.sh https://git.io/fj5ru && bash mtp_install.sh; then
        echo "Telegram MTProto proxy installed successfully."
    else
        echo "Error: Failed to install Telegram MTProto proxy."
    fi
}

# Function to install OpenVPN
install_openvpn() {
    if curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh && chmod +x openvpn-install.sh && ./openvpn-install.sh; then
        echo "OpenVPN installed successfully."
    else
        echo "Error: Failed to install OpenVPN."
    fi
}

# Function to create a swap file
create_swap() {
    read -p "Choose swap size (512M or 1G): " swap_size
    case $swap_size in
        512M)
            if sudo fallocate -l 512M /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile && echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab; then
                echo "Swap file created successfully."
            else
                echo "Error: Failed to create swap file."
            fi
            ;;
        1G)
            if sudo fallocate -l 1G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile && echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab; then
                echo "Swap file created successfully."
            else
                echo "Error: Failed to create swap file."
            fi
            ;;
        *)
            echo "Invalid choice. Please choose either 512M or 1G."
            ;;
    esac
}

# Function to change SSH port
change_ssh_port() {
    read -p "Enter the new SSH port: " new_ssh_port
    if sudo sed -i "s/#Port 22/Port $new_ssh_port/g" /etc/ssh/sshd_config && sudo systemctl restart ssh; then
        echo "SSH port changed successfully."
    else
        echo "Error: Failed to change SSH port."
    fi
}

# Function to add a cron job to reboot the system every 2 days
schedule_reboot() {
    if (crontab -l ; echo "0 0 */2 * * sudo /sbin/reboot") | crontab -; then
        echo "Scheduled system reboot every 2 days."
    else
        echo "Error: Failed to schedule system reboot."
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
        echo "VPS optimized for x-ui proxy successfully."
    else
        echo "Error: Failed to optimize VPS for x-ui proxy."
    fi
}

# Function to display menu
display_menu() {
    echo "========== Menu =========="
    echo "1. Update system"
    echo "2. Install utilities (sudo and wget)"
    echo "3. Install Nginx and obtain SSL certificates"
    echo "4. Install x-ui"
    echo "5. Install Telegram MTProto proxy"
    echo "6. Install OpenVPN"
    echo "7. Create swap file"
    echo "8. Change SSH port"
    echo "9. Schedule system reboot every 2 days"
    echo "10. Optimize VPS for x-ui proxy"
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
        0) echo "Exiting..."; break ;;
        *) echo "Invalid choice. Please enter a number between 0 and 10." ;;
    esac
done
