#!/usr/bin/env bash

set euo -pipefail

# declare kernel filename from kernel.org
KERNEL_MAJOR='6.x'
KERNEL_FN='linux-6.18.3'
DOWNLOAD_DIR="/home/${USER}/Downloads/custom"

sudo apt update && sudo apt upgrade -y

# xz-utils for tar to unpack archive
sudo apt install -y wget xz-utils

mkdir -p "${DOWNLOAD_DIR}" && cd "${DOWNLOAD_DIR}"
[ -f "${DOWNLOAD_DIR}/${KERNEL_FN}.tar.xz" ] || wget "https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_MAJOR}/${KERNEL_FN}.tar.xz" --directory-prefix="${DOWNLOAD_DIR}"
tar --xz -xvf "${KERNEL_FN}.tar.xz"

# for make system core
sudo apt install -y \
  build-essential libncurses-dev bison flex \
  libssl-dev libelf-dev dwarves bc libdwarf-dev libdw-dev \
  pahole llvm clang libbpf-dev elfutils libelf1

# cd to unpacked folder
cd "${DOWNLOAD_DIR}/${KERNEL_FN}"

# copy existing core config
cp "/boot/config-$(uname -r)" "${DOWNLOAD_DIR}/${KERNEL_FN}/.config"

# uncomment if any `make` previously run:
#sudo make clean

# Disable SecureBoot certs
scripts/config --disable CONFIG_MODULE_SIG
scripts/config --disable CONFIG_MODULE_SIG_FORCE
scripts/config --disable CONFIG_EFI_SECURE_BOOT
scripts/config --disable CONFIG_LOCK_DOWN_IN_EFI_SECURE_BOOT
scripts/config --disable CONFIG_SECURITY_LOCKDOWN_LSM
scripts/config --disable CONFIG_SECURITY_LOCKDOWN_LSM_EARLY
scripts/config --disable CONFIG_SYSTEM_TRUSTED_KEYRING
scripts/config --disable CONFIG_SYSTEM_TRUSTED_KEYS
scripts/config --disable CONFIG_SYSTEM_REVOCATION_KEYS
scripts/config --disable CONFIG_INTEGRITY
scripts/config --disable CONFIG_IMA
scripts/config --disable CONFIG_IMA_APPRAISE
scripts/config --disable CONFIG_MODULE_SIG_KEY_TYPE_RSA
scripts/config --disable CONFIG_MODULE_SIG_KEY_TYPE_ECDSA
scripts/config --undefine CONFIG_MODULE_SIG_KEY
scripts/config --undefine CONFIG_MODULE_SIG_HASH

# BTF
scripts/config --disable CONFIG_DEBUG_INFO_BTF_MODULES
scripts/config --disable CONFIG_PAHOLE_HAS_SPLIT_BTF
scripts/config --disable CONFIG_DEBUG_INFO_DWARF5
scripts/config --disable CONFIG_DEBUG_INFO_BTF_MODULES
scripts/config --disable CONFIG_CGROUP_BPF
scripts/config --disable CONFIG_BPF
scripts/config --disable CONFIG_BPF_SYSCALL
scripts/config --disable CONFIG_DEBUG_INFO_NONE
scripts/config --enable  CONFIG_DEBUG_INFO_DWARF4
scripts/config --enable  CONFIG_DEBUG_INFO_BTF


# Make core. Not interactive (defaults for all new options):
yes "" | sudo make olddefconfig
# ...interactive:
#make menuconfig

# echo to files in root custom folder
sudo make -j"$(nproc)" | tee "${DOWNLOAD_DIR}/make_report.txt"
sudo make modules_install | tee "${DOWNLOAD_DIR}/make_module_install.txt"
sudo make install | tee "${DOWNLOAD_DIR}/make_install.txt"

# --------------------------------------------------------------------
# show kernel before reboot
echo "Current kernel: $(uname -r). Check kernel version after reboot: uname -r"

sudo update-grub
sudo reboot now
