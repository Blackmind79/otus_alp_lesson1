#!/usr/bin/env bash

set euo -pipefail

# Link: https://kernel.ubuntu.com/mainline/
# for Mainline kernel version could be lower than latest at kernel.org because of tests failures
KERNEL='6.18.1'
DOWNLOAD_DIR="/home/${USER}/Downloads/mainline"

sudo apt update && sudo apt upgrade -y && sudo apt install -y wget

mkdir -p "${DOWNLOAD_DIR}" && cd "${DOWNLOAD_DIR}"

# get list of deb files
[ -f "${DOWNLOAD_DIR}/CHECKSUMS" ] || wget "https://kernel.ubuntu.com/mainline/v${KERNEL}/amd64/CHECKSUMS" --directory-prefix="${DOWNLOAD_DIR}"

# extract from CHECKSUMS file and download .deb files
grep -oP '(?<=\s)[^ ]+\.deb' "${DOWNLOAD_DIR}/CHECKSUMS" | while read file; do \
    echo "Downloading ${file}"; \
    [ -f "${DOWNLOAD_DIR}/CHECKSUMS" ] || wget "https://kernel.ubuntu.com/mainline/v${KERNEL}/amd64/${file}" --directory-prefix="${DOWNLOAD_DIR}"; \
done

# must be installed at order:
sudo apt install -y "${DOWNLOAD_DIR}"/linux-headers-*_amd64.deb
sudo apt install -y "${DOWNLOAD_DIR}"/linux-headers-*_all.deb
sudo apt install -y "${DOWNLOAD_DIR}"/linux-image-unsigned-*_amd64.deb
sudo apt install -y "${DOWNLOAD_DIR}"/linux-modules-*_amd64.deb

# --------------------------------------------------------------------
# show kernel before reboot
echo "Current kernel: $(uname -r). Check kernel version after reboot: uname -r"

# Apply updates and restart:
sudo update-grub
sudo reboot now