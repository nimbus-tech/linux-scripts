# PFsense Contextualization for OpenNebula  

The Contextualization script will pick up network interfaces defined in OpenNebula and automatically populate the IP Addresses for the configured interfaces.

## Script installation

- Copy script from OneDrive:/Nimbus Tech-Team – Documents/Nimbus General/OpenNebula Contextualization/OpenNebula-PFsense Context.sh
- Rename script file to vmcontext and copy to PFsense VM in /usr/bin folder
- Make script executable
- Edit /conf/config.xml and add the following line before </system>
                      <earlyshellcmd>/usr/bin/vmcontext</earlyshellcmd>



## OpenNebula Contextualization script notes

- OpenNebula will populate the context parameters in a file called “context.sh” and place it in a virtual CDROM image
- CDROM image is typically mounted (Storage – Context)
- On VM boot, the contextualization script will execute. See script flowchart below.


### Removal of network interfaces from PFsense VM

When virtual network interfaces are removed from the PFsense VM, during the PFsense boot, the system will complain about Network interface mismatch (pictured below).


We’ll have to perform the following steps :-

- Press Control-C to exit the configurator
- Hit enter to get to shell 
- Type “mount -uw /” to remount the root filesystem as read-write
- Delete the /tmp/missing_interfaces file
- Run “viconfig” command and delete the detached network interface from the configuration file.
- Reboot the VM
