if [ ! -d /mnt/ramdisk ]; then
    mkdir /mnt/ramdisk
    mount -t tmpfs -o size=64M tmpfs /mnt/ramdisk
fi 

if [ -f /mnt/ramdisk/hosts ]; then
    echo > /mnt/ramdisk/hosts
fi 

cd /mnt/ramdisk
touch hosts 
cp /etc/hosts.bkp /mnt/ramdisk/hosts

# --- add hostnames from incus containers with the format 
# --- container-ip container-name.incus
incus list --format=json | jq -r '.[] | select(.state.network.eth0.addresses != null) |
  .name as $name |
  .state.network.eth0.addresses[] |
  select(.family == "inet" and .scope == "global") |
  "\(.address) \($name).lan"' >> /mnt/ramdisk/hosts

# --- mount hosts file
sudo mount --bind /mnt/ramdisk/hosts /etc/hosts
