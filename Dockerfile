# Choose Alpine & Rancher versions here
FROM alpine:3.12.0
ENV RANCHER=v1.5.6

# Install the necessary packages
RUN apk add --no-cache --update dnsmasq wget python3 && rm -rf /var/cache/apk/*

# Install syslinux bootloader for PXE
ENV SYSLINUX_VERSION 6.03
ENV TEMP_SYSLINUX_PATH /tmp/syslinux-"$SYSLINUX_VERSION"
WORKDIR /tmp
RUN \
  mkdir -p "$TEMP_SYSLINUX_PATH" \
  && wget -q https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-"$SYSLINUX_VERSION".tar.gz \
  && tar -xzf syslinux-"$SYSLINUX_VERSION".tar.gz \
  && mkdir -p /var/lib/tftpboot \
  && cp "$TEMP_SYSLINUX_PATH"/bios/core/pxelinux.0 /var/lib/tftpboot/ \
  && cp "$TEMP_SYSLINUX_PATH"/bios/com32/libutil/libutil.c32 /var/lib/tftpboot/ \
  && cp "$TEMP_SYSLINUX_PATH"/bios/com32/elflink/ldlinux/ldlinux.c32 /var/lib/tftpboot/ \
  && cp "$TEMP_SYSLINUX_PATH"/bios/com32/menu/menu.c32 /var/lib/tftpboot/ \
  && rm -rf "$TEMP_SYSLINUX_PATH" \
  && rm /tmp/syslinux-"$SYSLINUX_VERSION".tar.gz

# Configure PXE and TFTP
COPY tftpboot/ /var/lib/tftpboot

# Configure DNSMASQ
COPY etc/ /etc

# Download Rancher Linux to PXE server folder (2 files, about 150 mb total)
RUN mkdir -p /var/lib/tftpboot/rancher
RUN wget https://github.com/rancher/os/releases/download/$RANCHER/vmlinuz -O /var/lib/tftpboot/rancher/vmlinuz
RUN wget https://github.com/rancher/os/releases/download/$RANCHER/initrd -O /var/lib/tftpboot/rancher/initrd

# DNSMASQ Statup Script
EXPOSE 8888
ENTRYPOINT ["/etc/runscript.sh"]
