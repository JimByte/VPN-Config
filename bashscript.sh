# Check OS and set the release variable
if [[ -f /etc/os-release ]]; then
    source /etc/os-release  # Source the os-release file to get OS details
    release=$ID  # Set the release variable to the OS ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release  # Source the os-release file if located in /usr/lib
    release=$ID  # Set the release variable to the OS ID
else
    echo "Failed to check the system OS!" >&2  # Output an error message if OS detection fails
    exit 1  # Exit the script with status 1
fi

echo "The OS release is: $release"  # Print the detected OS release

# Package installation based on the detected OS
case "${release}" in
    centos | fedora | almalinux)
        yum upgrade && yum install -y -q net-tools  # Upgrade packages and install net-tools for CentOS, Fedora, and AlmaLinux
        ;;
    arch | manjaro)
        pacman -Sy --noconfirm net-tools inetutils  # Synchronize package databases and install net-tools and inetutils for Arch and Manjaro
        ;;
    *)
        apt update && apt install -y -q net-tools iptables-persistent  # Update package lists and install net-tools and iptables-persistent for other distributions
        ;;
esac

# Restore iptables rules
iptables-restore < ./iptableslist.txt  # Restore IPv4 iptables rules from file
iptables-save > /etc/iptables/rules.v4  # Save the current IPv4 iptables rules
ip6tables-save > /etc/iptables/rules.v6  # Save the current IPv6 iptables rules
echo "Restore iptables rules done" 

# Enable IP forwarding
sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf  # Uncomment the net.ipv4.ip_forward line in sysctl.conf
sysctl -p  # Apply the changes in sysctl.conf
