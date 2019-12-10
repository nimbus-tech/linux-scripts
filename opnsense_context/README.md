# OPNsense Contextualization for OpenNebula

The Contextualization script will pick up network interfaces defined in OpenNebula and automatically populate the IP Addresses for the configured interfaces.

## Script installation

- Copy script from OneDrive:/Nimbus Tech-Team – Documents/Nimbus General/OpenNebula Contextualization/OpenNebula-OPNsense Context.sh
- Rename script file to 01-vmcontext and copy to OPNsense VM in /usr/local/opnsense/rc.syshook.d/early folder
- Make script executable



### OpenNebula Contextualization script notes

- OpenNebula will populate the context parameters in a file called “context.sh” and place it in a virtual CDROM image

- CDROM image is typically mounted (Storage – Context)

- On VM boot, the contextualization script will execute. See script flowchart below.


### Removal of network interfaces from OPNsense VM

Option 1 – Modification of config file before NIC removal in OpenNebula

- Edit /conf/config.xml and delete the NIC definition.
- Shutdown OPNsense VM
- Detach NIC in OpenNebula
- Boot OPNsense VM

Option 2 – Modification of config file after NIC removal in OpenNebula

i.e. we have detached the NIC in OpenNebula without removing it from OPNsense

- Edit /conf/config.xml and delete the NIC definition

- Delete /root/context.sh file

- Reboot OPNsense VM
