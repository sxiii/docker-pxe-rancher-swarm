# Ultimate auto-clustering solution
What is this about? Let's say you want to spin up a Docker home cluster with several hosts (or tens, or even hundred). 
However, you don't want to waste your time in setting up each and every host manually. 
And you still want every host to remotely (PXE) boot RancherOS (a popular Docker-based OS), as well as get unique IP for hosts via DHCP. 
Also, you want nodes to get the same hostname upon every boot.
And finally, you want the booted host to get the config you need and join Docker Swarm so you can control it from masternodes or some fancy GUI like portainer...

How to have all this... In one?

Meet DPRS: An Ultimate auto-clustering solution!

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
1. Download this repo to your PC: `git clone https://github.com/sxiii/docker-pxe-rancher-swarm/`
2. 

## File structure (aka "files to probably touch")
* `Dockerfile` - you need it to build a run the whole project
* `tftpboot/pxelinux.cfg/default` - PXE boot menu file (and cloud config address is here, too!)
* `etc/runscript.sh` - Docker start this script upon successful boot of container. The script starts Python mini http server as well as dnsmasq service. You'll need to change it if you want to give-away different DHCP addresses.
* `etc/cloud-config.yaml` - The Most Important file. The Docker nodes won't join your Swarm unless you put your token in here, along with Swarm Master controller IP, SSH Key (if you want to connect to nodes manually with your key) and, finally, MAC-to-Hostname configuration. See section "Cloud config" about this file.

## Files that you don't need to touch at all
* `etc/default/dnsmasq` - don't really know if it's needed, I've got this file from another similar project (let me know if I can remove it in the issues?)
* `etc/dnsmasq.conf` - no need to change this file (this is dnsmasq config, so we need to have it)
