# Ultimate auto-clustering solution
What is this about? Let's say you want to spin up a Docker home cluster with several hosts (or tens, or even hundred). 
However, you don't want to waste your time in setting up each and every host manually. 
And you still want every host to remotely (PXE) boot RancherOS (a popular Docker-based OS), as well as get unique IP for hosts via DHCP. 
Also, you want nodes to get the same hostname upon every boot.
And finally, you want the booted host to get the config you need and join Docker Swarm so you can control it from masternodes or some fancy GUI like portainer...

How to have all this... In one?

Meet DPRS: An Ultimate auto-clustering solution! (Also well known as "DevOps dream machine")

## What it does? Or what it can? What is the boot order? Help, I'm puzzled!
1. You take the docker container, configure it, and build it. With docker build. Docker container will have everything inside of it!
2. You run the docker container.
3. The running container includes everything you need to build a cluster: 
* 3.1 DHCP & PXE server (based on Alpine linux): to boot all your devices via network
* 3.2 Python-based small HTTP server that hosts RancherOS kernel (vmlinuz) and RancherOS initrd images right from same container (Rancher can be replaced with any Linux you want by switching this files)
* 3.3 Cloud-config file for RancherOS to boot, with static hostname configuration based on MAC addresses (so your nodes will have the same hostname every time)
4. It's portable: best of all, all of these steps are achieved in a single docker container! Not huring your current setup, anything! You can tune it down simply by a single Ctrl+C.
5. You start-up any amount of the machines with PXE Boot, and, violia! They all boot into Rancher with your configuration and joins your super-cool Swarm.

## Some meaningful defaults
You will need to change some things to make this work. However, there are some "meanungful defaults" that you can leave "as-is":
* By default, the image assumes that you're the host with IP 10.42.0.1 IP (This is default IP when using NetworkManager set to "Network Shared to others"). If you need to change this IP, bear in mind that there is multiple places where you need to change it (I could improve this with putting everything into just one Dockerfile ENV value, but I am too lazy at this point, open an issue if you want this).
* There is a PXE boot menu that you can edit, if you want to (or live it as-is). PXE Menu file is under `tftpboot/pxelinux.cfg/default` file.
* RancherOS kernel and initrd are downloaded each time container is build. If you don't want this, download them one-time - manually - and replace the "RUN wget"... rows with "ADD vmlinuz ..." rows.
* There is dnsmasq.conf file for obviously dnsmasq configuration, but you don't need to change it at all.

## Great, I want to begin! Teach me, how!
There might be more or less configuration that you need to do depending on your tasks. I will go through the simplest method of not changing anything except for the REQUIRED TO CHANGE parts.
1. Download this repo to your PC: `git clone https://github.com/sxiii/docker-pxe-rancher-swarm/`
2. Enter the folder: `cd docker-pxe-rancher-swarm`
3. Edit the main configuration file, which is `etc/cloud-config.yaml`. At least you should add SWARM token if you want to use Docker Swarm. You can also add your SSH key if you plan to manage some of the nodes manually, and, finally, the "MAC address to Hostname" resolution is also configured in here.
4. Either change your host IP to 10.42.0.1 (at least on the interface that you want PXE to work), OR check the "File structure" section on several places that you need to edit to change the IP range for PXE & DHCP to work.
5. Build the container: `docker build -t . dprs` - you might need sudo here. Also, the build should finish successfully without any errors.
6. Run the container: `docker run -it --rm --net=host --cap-add=NET_ADMIN dprs:latest` - you might need sudo in here, too. --net=host and --cap-add required because we're fiddling with DHCP and PXE.
7. Insert ethernet from your host to the machine you want to PXE boot or to a network switch(es), if you hasn't done that already, and then boot (or reboot) the machines. If the nodes don't have PXE boot enabled in BIOS, you'll need to go there and enable PXE boot.
8. That's it! Wait for 1 or 2 minutes, then issue `docker node ls` command to see, if the nodes had booted up rancher and joined your swarm. You can also SSH to them, if you've added your SSH key or static password in the `cloud-config.yaml` file.
9. Report success and support my work in the issues and/or by donating towards improvement of this and other projects on: https://sxiii.ru/donate

## File structure (aka "files to probably touch")
* `Dockerfile` - you need it to build a run the whole project (you can leave this file as-is if you're happy with defaults)
* `tftpboot/pxelinux.cfg/default` - PXE boot menu file (and cloud config address is here, too)
* `etc/runscript.sh` - Docker start this script upon successful boot of container. The script starts Python mini http server as well as dnsmasq service. You'll need to change it if you want to give-away different DHCP addresses.
* `etc/cloud-config.yaml` - The Most Important file. The Docker nodes won't join your Swarm unless you put your token in here, along with Swarm Master controller IP, SSH Key (if you want to connect to nodes manually with your key) and, finally, MAC-to-Hostname configuration. See section "Cloud config" about this file.

## Files that you don't need to touch at all
* `etc/default/dnsmasq` - don't really know if it's needed, I've got this file from another similar project (let me know if I can remove it in the issues?)
* `etc/dnsmasq.conf` - no need to change this file (this is dnsmasq config, so we need to have it)

## Q: Can I Boot distro "X" (Arch, Ubuntu, Debian, Fedora, YouNameIt)?
A: Yes you can. You can even boot non-linux'es. And even have a PXE boot menu with different OSes! This can be achieved in a simple way: replace the "RUN wget..." lines (in the bottom of `Dockerfile`) with according "vmlinuz" and "initrd" full-URL paths to similar files for your distribution. You can, as well, edit the PXE menu (but you don't have to!), at `tftpboot/pxelinux.cfg/default`, to match your distro name (or maybe to make a multi-distro boot menu).

## Q: Can I change the DHCP IP range?
A: Of course. You will need to change it in multiple places (at least on the current DPRS version) - check out the "files to probably touch" section for details on that. The DHCP range is in the `runscript.sh` file, however, the "master-boot" machine (10.42.0.1) is in other files, so you'll need to change them as well.

## Q: How to add my own Mac-to-Hostname labels?
A: Open `etc/cloud-config.yaml` file. Find a row that says `case $mac in`. After this row, you will see this: `b4:b5:2f:32:73:08) echo "hp-elitebook-8570p" ;;`. Copy-paste this MAC and Host address number of times equal unique Mac addresses you have (or, equal to actual number of hosts). Then, replace the MAC addresses according to your hardware, as well as hostnames. That's it. Rebuild the container, start it, and restart the machines, that's it!

## Q: How to add my SSH keys to the auto-provisioned hosts?
A: Open `etc/cloud-config.yaml` file. Find a row that says `ssh_authorized_keys:`. After this row, you will see this: ` - ssh-rsa AAAA{==INSERT==YOUR=SSH==KEY==HERE==}`. Replace the "AAA..." with your SSH key. That's it. Rebuild the container, start it, and restart the machines, that's it!

## Q: What "runcmd" section in the cloud-config.yaml file does?
A: This command is run upon the hosts provisioning. Basically it just takes your mac address and compares with the addresses from the list. If it founds according hostname, it sets it. If not, it sets hostname as "unknownhost". That's it!

## Q: What "write_files" section in the cloud-config.yaml file does?
A: This command creates files in the filesystem of provisioned hosts. My source creates two files: one (/etc/rc.local) to actually join the Docker Swarm after system boots and starts Docker. The other, `/etc/acpi/suspend.sh` file in the `acpid` is important for the laptops: with this file, laptops WILL NOT SUSPEND UPON THE LID CLOSING. If you want them to suspend, remove lines from `  - container: acpid` all the way down to `exit 0` lines.

## Q: How can I manually edit "Parameter X" of Rancher OS?
A: Please check out RancherOS official documentation page here: https://rancher.com/docs/os/v1.x/en/

## Q: I have another question or problem, something don't work, how can I contact you?
A: The best way is thought github's issues. Create an issue, describe your problem and then wait for me or someone else to answer. You can find my contact details as well in github and on my website https://sxiii.ru

## Q: I have a feature request or I already improved something, what can I do?
A: For feature request, please open an issue, and describe what do you want. For improving, please do a pull-request right away, and explain your improvement in the comment. I will review it and accept, as soon as possible. You can contact me as well through my website https://sxiii.ru
