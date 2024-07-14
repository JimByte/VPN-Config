#!/bin/bash

# Check OS and set the release variable
if [[ -f /etc/os-release ]]; then
    # Source the os-release file to get OS details
    source /etc/os-release
    release=$ID  # Set the release variable to the OS ID
elif [[ -f /usr/lib/os-release ]]; then
    # Source the os-release file if located in /usr/lib
    source /usr/lib/os-release
    release=$ID  # Set the release variable to the OS ID
else
    # Output an error message if OS detection fails
    echo "Failed to check the system OS!" >&2
    exit 1  # Exit the script with status 1
fi

# Print the detected OS release
echo "The OS release is: $release"

# Package installation based on the detected OS
case "${release}" in
    centos | fedora | almalinux)
        # Upgrade packages and install net-tools for CentOS, Fedora, and AlmaLinux
        yum upgrade && yum install -y -q net-tools iptables-services
        # Enable and start iptables service
        systemctl enable iptables
        systemctl start iptables
        ;;
    arch | manjaro)
        # Synchronize package databases and install net-tools and inetutils for Arch and Manjaro
        pacman -Sy --noconfirm net-tools inetutils iptables
        # Enable and start iptables service
        systemctl enable iptables
        systemctl start iptables
        ;;
    *)
        # Update package lists and install net-tools and iptables-persistent for other distributions
        apt update && apt install -y -q net-tools iptables iptables-persistent
        # Enable and start iptables service
        systemctl enable netfilter-persistent
        systemctl start netfilter-persistent
        ;;
esac

# Restore iptables rules from a file
iptables-restore < ./iptableslist.txt

# Save the current IPv4 iptables rules
iptables-save > /etc/iptables/rules.v4

# Save the current IPv6 iptables rules
ip6tables-save > /etc/iptables/rules.v6

# Output message indicating the iptables rules have been restored
echo "Restore iptables rules done"

# Enable IP forwarding
# Uncomment the net.ipv4.ip_forward line in sysctl.conf
sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# Apply the changes in sysctl.conf
sysctl -p

# Output message indicating IP forwarding has been enabled
echo "IP forwarding enabled"
