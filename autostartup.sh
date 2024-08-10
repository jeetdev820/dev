!/bin/bash

# Define text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
LGREEN='\033[1;32m' # Light Green
NC='\033[0m' # No Color

# Function to handle errors
handle_error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Function to update the package lists, upgrade installed packages, and clean up
update_system() {
    if sudo apt update -y && sudo apt upgrade -y && sudo apt autoclean -y && sudo apt autoremove -y; then
        echo -e "${GREEN}System update completed successfully.${NC}"
    else
        handle_error "Failed to update system."
    fi
}

# Function to install sudo and wget
install_utilities() {
    if sudo apt install -y sudo wget; then
        echo -e "${GREEN}Utilities (sudo and wget) installed successfully.${NC}"
    else
        handle_error "Failed to install utilities (sudo and wget)."
    fi
}

# Function to install Nginx and obtain SSL certificates
install_nginx() {
    if sudo apt install nginx -y && sudo apt install snapd -y && sudo snap install core && sudo snap install --classic certbot && sudo ln -s /snap/bin/certbot /usr/bin/certbot && sudo certbot --nginx; then
        echo -e "${GREEN}Nginx installed and SSL certificates obtained successfully.${NC}"
    else
        handle_error "Failed to install Nginx or obtain SSL certificates."
    fi
}

# Function to manage Nginx: stop, start, reload, restart
manage_nginx() {
    echo -e "${LGREEN}===== Nginx Management =====${NC}"
    echo -e " ${YELLOW}1.${NC} Stop Nginx"
    echo -e " ${YELLOW}2.${NC} Start Nginx"
    echo -e " ${YELLOW}3.${NC} Reload Nginx"
    echo -e " ${YELLOW}4.${NC} Restart Nginx"
    echo -e " ${YELLOW}5.${NC} Uninstall Nginx"
    echo -e " ${YELLOW}0.${NC} Back"
    echo -e "${LGREEN}============================${NC}"
    read -p "Enter your choice: " nginx_choice
    case $nginx_choice in
        1) sudo systemctl stop nginx ;;
        2) sudo systemctl start nginx ;;
        3) sudo systemctl reload nginx ;;
        4) sudo systemctl restart nginx ;;
        5) uninstall_nginx ;;
        0) return ;;
        *) handle_error "Invalid choice. Please enter a number between 0 and 5." ;;
    esac
    echo -e "${GREEN}Nginx action completed successfully.${NC}"
}

# Function to configure Nginx for wildcard SSL
configure_nginx_wildcard_ssl() {
    read -p "Enter your domain name (e.g., example.com): " domain_name
    
    # Validate the domain name input
    if [[ ! "$domain_name" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        handle_error "Invalid domain name. Please enter a valid domain."
        return 1
    fi

    # Choose the DNS provider
    echo "Choose your DNS provider:"
    echo "1) Cloudflare"
    echo "2) Gcore"
    read -p "Enter the number corresponding to your DNS provider: " dns_provider_choice

    case $dns_provider_choice in
        1)
            dns_plugin="dns-cloudflare"
            read -p "Enter your Cloudflare email: " cloudflare_email
            read -s -p "Enter your Cloudflare API key: " cloudflare_api_key
            echo

            # Save the Cloudflare API credentials
            cloudflare_credentials_file=~/.secrets/certbot/cloudflare.ini
            mkdir -p $(dirname "$cloudflare_credentials_file")
            echo "dns_cloudflare_email = $cloudflare_email" | sudo tee "$cloudflare_credentials_file" > /dev/null
            echo "dns_cloudflare_api_key = $cloudflare_api_key" | sudo tee -a "$cloudflare_credentials_file" > /dev/null

            # Secure the credentials file
            sudo chmod 600 "$cloudflare_credentials_file"
            ;;
        2)
            dns_plugin="dns-gcore"
            read -s -p "Enter your Gcore API token: " gcore_api_token
            echo

            # Save the Gcore API credentials
            gcore_credentials_file=~/.secrets/certbot/gcore.ini
            mkdir -p $(dirname "$gcore_credentials_file")
            echo "dns_gcore_api_token = $gcore_api_token" | sudo tee "$gcore_credentials_file" > /dev/null

            # Secure the credentials file
            sudo chmod 600 "$gcore_credentials_file"
            ;;
        *)
            handle_error "Invalid choice. Please choose either 1 for Cloudflare or 2 for Gcore."
            return 1
            ;;
    esac

    # Certbot command with the chosen DNS challenge plugin
    if sudo certbot certonly --$dns_plugin \
            -d "$domain_name" \
            -d "*.$domain_name" \
            --agree-tos --non-interactive --email your-email@example.com; then
        echo -e "${GREEN}Wildcard SSL certificate obtained successfully for $domain_name.${NC}"

        # Configure Nginx to use the obtained certificate
        nginx_config_file="/etc/nginx/sites-available/$domain_name.conf"
        if sudo tee "$nginx_config_file" > /dev/null <<EOL
server {
    listen 443 ssl;
    server_name $domain_name *.$domain_name;

    ssl_certificate /etc/letsencrypt/live/$domain_name/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain_name/privkey.pem;

    location / {
        proxy_pass http://localhost:8080; # Adjust according to your setup
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL
        then
            echo -e "${GREEN}Nginx configuration updated successfully for $domain_name.${NC}"
            sudo ln -s "$nginx_config_file" /etc/nginx/sites-enabled/
            sudo systemctl reload nginx
        else
            handle_error "Failed to configure Nginx for $domain_name."
            return 1
        fi
    else
        handle_error "Failed to obtain wildcard SSL certificate for $domain_name."
        return 1
    fi

    # Optional: Log the successful SSL configuration
    log_file="/var/log/nginx_ssl_setup.log"
    echo "$(date): Successfully configured wildcard SSL for $domain_name using $dns_plugin" | sudo tee -a "$log_file"
}


# Function to install x-ui
install_x_ui() {
    if bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh); then
        echo -e "${GREEN}x-ui installed successfully.${NC}"
    else
        handle_error "Failed to install x-ui."
    fi
}

# Function to install Telegram MTProto proxy
install_telegram_proxy() {
    if curl -L -o mtp_install.sh https://git.io/fj5ru && bash mtp_install.sh; then
        echo -e "${GREEN}Telegram MTProto proxy installed successfully.${NC}"
    else
        handle_error "Failed to install Telegram MTProto proxy."
    fi
}

# Function to install OpenVPN and stunnel
install_openvpn() {
    if sudo apt install openvpn stunnel4 -y; then
        echo -e "${GREEN}OpenVPN and stunnel installed successfully.${NC}"
    else
        handle_error "Failed to install OpenVPN and stunnel."
    fi
}

# Function to install fail2ban
install_fail2ban() {
    if sudo apt install fail2ban -y; then
        echo -e "${GREEN}fail2ban installed successfully.${NC}"
    else
        handle_error "Failed to install fail2ban."
    fi
}

# Function to create a swap file
create_swap() {
    read -p "Choose swap size (512M, 1G, or 2G): " swap_size
    case $swap_size in
        512M)
            if sudo fallocate -l 512M /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile && echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab; then
                echo -e "${GREEN}Swap file created successfully.${NC}"
            else
                handle_error "Failed to create swap file."
            fi
            ;;
        1G)
            if sudo fallocate -l 1G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile && echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab; then
                echo -e "${GREEN}Swap file created successfully.${NC}"
            else
                handle_error "Failed to create swap file."
            fi
            ;;
        2G)
            if sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile && echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab; then
                echo -e "${GREEN}Swap file created successfully.${NC}"
            else
                handle_error "Failed to create swap file."
            fi
            ;;
        *)
            handle_error "Invalid choice. Please choose either 512M, 1G, or 2G."
            ;;
    esac
}


# Function to change SSH port
change_ssh_port() {
    # Suggested ports - Commonly recommended alternatives to port 22
    suggested_ports=("2022" "2222" "2200" "8022" "9222")
    
    echo "Please select a new SSH port from the suggested options below:"
    for i in "${!suggested_ports[@]}"; do
        echo "$((i + 1))) ${suggested_ports[$i]}"
    done
    
    read -p "Enter the number corresponding to your choice (1-5) or enter a custom port: " port_choice

    if [[ $port_choice =~ ^[1-5]$ ]]; then
        new_ssh_port=${suggested_ports[$((port_choice - 1))]}
    elif [[ $port_choice =~ ^[0-9]+$ && $port_choice -ge 1024 && $port_choice -le 65535 ]]; then
        new_ssh_port=$port_choice
    else
        handle_error "Invalid choice. Please enter a valid port number."
        return 1
    fi

    # Change the SSH port in the sshd_config file
    if sudo sed -i "s/#Port 22/Port $new_ssh_port/g" /etc/ssh/sshd_config && sudo systemctl restart ssh; then
        echo -e "${GREEN}SSH port changed successfully to $new_ssh_port.${NC}"
    else
        handle_error "Failed to change SSH port."
        return 1
    fi

    # Ensure UFW is installed
    if ! command -v ufw &> /dev/null; then
        echo "UFW is not installed. Installing UFW..."
        if sudo apt-get update && sudo apt-get install ufw -y; then
            echo -e "${GREEN}UFW installed successfully.${NC}"
        else
            handle_error "Failed to install UFW."
            return 1
        fi
    else
        echo -e "${GREEN}UFW is already installed.${NC}"
    fi

    # Enable UFW if not already enabled
    if sudo ufw status | grep -q "Status: inactive"; then
        echo "UFW is not active. Enabling UFW..."
        if sudo ufw enable; then
            echo -e "${GREEN}UFW enabled successfully.${NC}"
        else
            handle_error "Failed to enable UFW."
            return 1
        fi
    else
        echo -e "${GREEN}UFW is already active.${NC}"
    fi

    # Add rate-limited rule for the new SSH port
    echo "Adding UFW rule for SSH port $new_ssh_port with rate limiting..."
    if sudo ufw limit "$new_ssh_port"/tcp; then
        echo -e "${GREEN}UFW rule added successfully for port $new_ssh_port with rate limiting.${NC}"
    else
        handle_error "Failed to add UFW rule for SSH port $new_ssh_port."
        return 1
    fi
}



# Function to add a cron job to reboot the system every 2 days
schedule_reboot() {
    if (crontab -l ; echo "0 0 */2 * * sudo /sbin/reboot") | crontab -; then
        echo -e "${GREEN}Scheduled system reboot every 2 days.${NC}"
    else
        handle_error "Failed to schedule system reboot."
    fi
}

# Function to optimize VPS for x-ui proxy
optimize_vps_for_x_ui_proxy() {
    if sudo nano /etc/sysctl.conf && cat <<EOF >> /etc/sysctl.conf
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
net.ipv4.tcp_sack=1

# Enable timestamps as defined in RFC1323.
net.ipv4.tcp_timestamps = 1

# Increase TCP max buffer size
net.ipv4.tcp_mem = 16777216 16777216 16777216

# Security Enhancements
#net.ipv4.conf.default.rp_filter = 1
# Optimize ARP Cache
net.ipv4.neigh.default.gc_stale_time = 120
# Increase Maximum Port Range
net.ipv4.ip_local_port_range = 1024 65000
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
#net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 300


net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
vm.swappiness=65
# Memory Management for 512mb ram 512swap 5to10% total ram
vm.dirty_ratio = 5
vm.dirty_background_ratio = 3

EOF
     sudo sysctl -p; then
        echo -e "${GREEN}VPS optimized for x-ui proxy successfully.${NC}"
    else
        handle_error "Failed to optimize VPS for x-ui proxy."
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
            *) handle_error "Invalid choice. Please enter a number between 0 and 4." ;;
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
            handle_error "Failed to add port $port."
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
            handle_error "Failed to delete port $port."
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
                handle_error "Failed to enable UFW."
            fi
            ;;
        disable)
            if sudo ufw disable; then
                echo -e "${GREEN}UFW disabled successfully.${NC}"
            else
                handle_error "Failed to disable UFW."
            fi
            ;;
        *)
            handle_error "Invalid choice. Please enter 'enable' or 'disable'."
            ;;
    esac
}

# Function to display menu
display_menu() {
    echo -e "${LGREEN}========== Menu ==========${NC}"
    echo -e " ${YELLOW}1.${NC} Update system"
    echo -e " ${YELLOW}2.${NC} Install utilities (sudo and wget)"
    echo -e " ${YELLOW}3.${NC} Install Nginx and obtain SSL certificates"
    echo -e " ${YELLOW}4.${NC} Manage Nginx"
    echo -e " ${YELLOW}5.${NC} Configure Nginx for wildcard SSL"
    echo -e " ${YELLOW}6.${NC} Install x-ui"
    echo -e " ${YELLOW}7.${NC} Install Telegram MTProto proxy"
    echo -e " ${YELLOW}8.${NC} Install OpenVPN and stunnel"
    echo -e " ${YELLOW}9.${NC} Install fail2ban"
    echo -e " ${YELLOW}10.${NC} Create swap file"
    echo -e " ${YELLOW}11.${NC} Change SSH port"
    echo -e " ${YELLOW}12.${NC} Schedule system reboot every 2 days"
    echo -e " ${YELLOW}13.${NC} Optimize VPS for x-ui proxy"
    echo -e " ${YELLOW}14.${NC} Firewall Management"
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
        4) manage_nginx ;;
        5) configure_nginx_wildcard_ssl ;;
        6) install_x_ui ;;
        7) install_telegram_proxy ;;
        8) install_openvpn ;;
        9) install_fail2ban ;;
        10) create_swap ;;
        11) change_ssh_port ;;
        12) schedule_reboot ;;
        13) optimize_vps_for_x_ui_proxy ;;
        14) firewall_management ;;
        0) echo -e "${LGREEN}Exiting...${NC}"; break ;;
        *) handle_error "Invalid choice. Please enter a number between 0 and 14." ;;
    esac
done
