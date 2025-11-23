# Installation Guide

The installation section is based on https://wiki.archlinux.org/title/installation_guide.
This document is licensed under the terms of the [GNU Free Documentation License 1.3 or later](https://www.gnu.org/copyleft/fdl.html).

## Dual-Booting: Pre-Installation

To set up dual-booting, install Windows in UEFI mode.
When creating partitions, make sure that the ESP partition is some 512 MiB in size to avoid issues when installing grub!
The steps are:

1. When partitioning during the Windows installation, remove all partitions
2. Click “New” and “Apply” on the empty space
3. Remove all but the “Recovery” partition (Windows 10 only)
4. Press “Shift + F10”, enter `diskpart.exe`, and perform the following steps, where `<n>` is the index of the disk to install on as determined using `list disk`:
   ```cmd
   list disk
   select disk <n>
   create partition efi size=512
   format quick fs=fat32 label=System
   exit
   ```
5. Enter `exit`
6. Click “Refresh”
7. Select the empty space and click “New” and “Apply” once more

In the following, `/dev/nvme0n1` is assumed to be the device on which Windows is installed, with four partitions already created by Windows.
In this configuration, `/dev/nvme0n1p1` is the EFI partition.

## Installation

_Contrary to the Arch Linux Installation Guide, this document treats everything done while the live image is booted as the “Installation” and everything done when the installed system is booted as “Post-Installation”._

### Set the Keyboard Layout

```sh
loadkeys de-latin1
```

### Verify the Boot Mode

Check that the boot mode is 64-bit UEFI by checking that the output of the following is `64`:

```sh
cat /sys/firmware/efi/fw_platform_size
```

### Connect to Wi-Fi

Enter the interactive prompt by executing `iwctl` and enter the following there, where `<station>` is the name of the chosen device (as listed by `device list`) and `<ssid>` is the SSID of the network connect to (as listed by `get-networks`):

```sh
device list
station <station> scan
station <station> get-networks
station <station> connect <ssid>
station <station> show
```

Verify the connection to the internet by executing `ping archlinux.org`.

### Update the System Clock

```sh
timedatectl
```

### Partitioning and Formatting

Print the available devices using `fdisk`:

```sh
fdisk -l
```

Create the necessary partitions interactively using `cfdisk`, assuming that `/dev/nvme0n1` is the device to install Arch Linux on:

```sh
cfdisk /dev/nvme0n1
```

Format the partition to install Arch Linux on, which is assumed to be `/dev/nvme0n1p5`:

```sh
mkfs.ext4 /dev/nvme0n1p5
```

### Mount the File Systems

Mount the root volume and the EFI system partition:

```sh
mount /dev/nvme0n1p5 /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
```

### Update the Mirrors

Update the mirrors in `/etc/pacman.d/mirrorlist`:

```sh
reflector --save /etc/pacman.d/mirrorlist --country Austria,France,Germany,Poland --protocol https --sort rate --latest 8
```

### Install Essential Packages

Use `pacstrap` to install essential packages to the mounted root volume:

```sh
pacstrap -K /mnt base bluez-utils efibootmgr fish gdm gnome gnome-tweaks grub htop linux linux-firmware ntfs-3g man-db man-pages nano networkmanager openssh os-prober pipewire pipewire-pulse rsync sudo texinfo wget wireless_tools wpa_supplicant
```

On a system with an NVIDIA GPU, install the following additional packages:

```sh
pacstrap -K /mnt nvidia nvidia-settings nvidia-utils
```

### Generate the `fstab` File

```sh
genfstab -U /mnt >>/mnt/etc/fstab
```

### Change Root into the New System

```sh
arch-chroot /mnt
```

### Switch to `fish`

`fish` is friendlier and more interactive 😉

```sh
fish
```

### Time

Set the time and adjust system time:

```sh
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc
```

### Localization

First, edit `/etc/locale.gen` to uncomment `en_US.UTF-8 UTF-8` and `en_GB.UTF-8 UTF-8`.
Then, generate and configure the localization:

```sh
locale-gen
echo "LANG=en_GB.UTF-8" >>/etc/locale.conf
echo "KEYMAP=de-latin1" >>/etc/vconsole.conf
```

### Network Configuration

Create the hostname file:

```sh
echo <hostname> >>/etc/hostname
```

### Root Password

```sh
passwd
```

### Boot Loader

**This is only required when dual-booting!**

```sh
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
```

To add a GRUB entry for Windows, first determine the UUID of the EFI partition (again assumed to be `/dev/nvme0n1p1`):

```sh
blkid /dev/nvme0n1p1
```

With this information, add a GRUB entry to `/etc/grub.d/40_custom`, where `<uuid>` is the UUID determined in the previous step:

```
menuentry "Windows 10" --class windows --class os {
  search --no-floppy --set=root --fs-uuid <uuid>
  chainloader (${root})/EFI/Microsoft/Boot/bootmgfw.efi
}
```

Lastly, generate the GRUB configuration:

```sh
grub-mkconfig -o /boot/grub/grub.cfg
```

### Install microcode updates

- On an AMD system, execute `pacman -S amd-ucode`.
- On an Intel system, execute `pacman -S intel-ucode`.

### Display Manager

Enable the GNOME Display Manager:

```sh
systemctl enable gdm
```

### Networking

Enable NetworkManager:

```sh
systemctl enable NetworkManager
```

### Bluetooth

Enable Bluetooth:

```sh
systemctl enable bluetooth
```

### User Management

```sh
useradd -m -s /bin/fish $USER
passwd $USER
usermod -aG wheel $USER
sed -i '/^root ALL=(ALL:ALL) ALL/a $USER ALL=(ALL:ALL) ALL' /etc/sudoers
```

### Default Editor

Set `nano` as the default editor:

```sh
echo 'EDITOR=/bin/nano' >>/etc/environment
```

### Apple Magic Keyboard

Make function keys the default on the Apple Magic Keyboard:

```sh
echo "options hid_apple fnmode=2" >>/etc/modprobe.d/hid_apple.conf
```

## Post-Installation

### Terminal

Install `kitty`, my preferred terminal emulator:

```sh
sudo pacman -S kitty
```

Install `yazi`, my preferred terminal file manager, and add the `yy` function to the `fish` configuration:

```sh
sudo pacman -S yazi zoxide
rsync --progress ~/projects/archlinux-config/conf/config.fish ~/.config/fish/config.fish
```

### `multilib`

Uncomment the `multilib` section in `/etc/pacman.conf`.

### SSH

SSH configuration in different scenarios is covered in [SSH.md](SSH.md).

### Git Credentials

Build and set up the `libsecret` credential helper:

```sh
cd /usr/share/git/credential/libsecret/
sudo make
git config --global credential.helper /usr/share/git/credential/libsecret/git-credential-libsecret
```

### Folders

Create basic folders:

```sh
mkdir ~/aur ~/projects
```

### This Repository

Clone this repository, as some commands copy config files from the [`conf`](conf/) sub-folder:

```sh
cd ~/projects
git clone git@github.com:KurtBoehm/archlinux-config.git
```

### Basic Development Tools

Tools that are often required when building packages:

```sh
sudo pacman -S cmake extra-cmake-modules fakeroot gcc git gomake meson ninja nodejs npm patch python vala ruby rubygems
```

### Package Management

Install `yay` manually:

```sh
cd ~/aur/
git clone https://aur.archlinux.org/yay.git
cd ~/aur/yay
makepkg -si
```

Install `pamac` using `yay`:

```sh
yay -S pamac-aur polkit-gnome
```

### Fonts

Install packaged fonts:

```sh
sudo pacman -S adobe-source-sans-fonts adobe-source-serif-fonts noto-fonts noto-fonts-emoji otf-cascadia-code otf-openmoji ttf-jetbrains-mono ttf-ubuntu-font-family
```

Install Iosevka Mono/Quasi from [`latex-fonts`](https://github.com/KurtBoehm/latex-fonts):

```sh
cd ~/projects
git clone git@github.com:KurtBoehm/latex-fonts.git
cd ~/projects/latex-fonts/iosevka-mono
rsync --progress *.ttf ~/.local/share/fonts/IosevkaMono
cd ~/projects/latex-fonts/iosevka-quasi
rsync --progress *.ttf ~/.local/share/fonts/IosevkaSans
fc-cache -f -v
```

Install Ubuntu Sans:

```sh
curl -s https://api.github.com/repos/canonical/Ubuntu-Sans-fonts/releases/latest | jq -r '.["assets"][0]["browser_download_url"]' | wget -qi -
unzip (curl -s https://api.github.com/repos/canonical/Ubuntu-Sans-fonts/releases/latest | jq -r '.["assets"][0]["name"]')
rm UbuntuSans-fonts-*.zip
cd UbuntuSans-fonts-*/otf
rsync --progress *.otf ~/.local/share/fonts/UbuntuSans
fc-cache -f -v
cd ../..
rm -rf __MACOSX/ UbuntuSans-fonts-*/
```

Install Ubuntu Sans Mono:

```sh
curl -s https://api.github.com/repos/canonical/Ubuntu-Sans-Mono-fonts/releases/latest | jq -r '.["assets"][0]["browser_download_url"]' | wget -qi -
unzip (curl -s https://api.github.com/repos/canonical/Ubuntu-Sans-Mono-fonts/releases/latest | jq -r '.["assets"][0]["name"]')
rm UbuntuSansMono-fonts-*.zip
cd UbuntuSansMono-fonts-*/otf
rsync --progress *.otf ~/.local/share/fonts/UbuntuSansMono
fc-cache -f -v
cd ../..
rm -rf __MACOSX/ UbuntuSansMono-fonts-*/
```

Set the default font (so that `kitty` does not use a rubbish font in the title bar):

```sh
cp ~/projects/archlinux-config/conf/fonts.conf ~/.config/fontconfig/
```

### GNOME

Install GNOME tools:

```sh
sudo pacman -S dconf-editor gnome-browser-connector gnome-firmware gvfs-smb seahorse
```

Install the `adw` GTK theme and the MoreWaita icon theme:

```sh
yay -S adw-gtk-theme morewaita-icon-theme
```

### Qt

Install Qt 5 and 6 Settings:

```sh
sudo pacman -S qt5ct qt6ct
```

Add the following line to `/etc/environment`:

```sh
QT_QPA_PLATFORMTHEME=qt5ct
```

### Web Tools

Install Firefox, Thunderbird, and OpenVPN:

```sh
sudo pacman -S firefox networkmanager-openvpn openvpn thunderbird
```

### Development Tools

Install other compilers etc., mostly to support additional programming languages:

```sh
sudo pacman -S clang gcc-fortran jdk-openjdk julia rustup
```

Set up Rust’s default stable release:

```sh
rustup default stable
```

Configure `clangd` to disable unsupported options, enable strict include checking, etc.:

```sh
rsync --progress ~/projects/archlinux-config/conf/clangd.yaml ~/.config/clangd/config.yaml
```

Install development tools:

```sh
sudo pacman -S antlr4 boost doxygen gdb glfw-wayland graphviz openimageio openmp openmpi ospray p7zip paraview perf sshfs tbb textpieces unrar
yay -S hotspot speedcrunch
```

Install Python libraries:

```sh
sudo pacman -S python-argcomplete python-colorama python-h5py python-matplotlib python-pandas python-pip python-sympy python-secretstorage python-tqdm
pip3 install pandas-stubs --break-system-packages
```

Set up OpenMPI to disable CUDA:

```sh
mkdir ~/.openmpi/
echo "opal_warn_on_missing_libcuda = 0" >~/.openmpi/mca-params.conf
```

Install Compiler Explorer:

```sh
cd ~/projects/
git clone --recurse-submodules https://github.com/compiler-explorer/compiler-explorer.git
cd ~/projects/compiler-explorer/
make
```

Install Code – OSS, a good selection of extensions, and a reasonable starting configuration:

```sh
sudo pacman -S code
for EXTENSION in njpwerner.autodocstring \
                 detachhead.basedpyright \
                 mads-hartmann.bash-ide-vscode \
                 alefragnani.Bookmarks \
                 akiramiyakoda.cppincludeguard \
                 llvm-vs-code-extensions.vscode-clangd \
                 cschlosser.doxdocgen \
                 tamasfe.even-better-toml \
                 bmalehorn.vscode-fish \
                 ms-vscode.hexeditor \
                 ms-python.isort \
                 Orta.vscode-jest \
                 redhat.java \
                 dirk-thomas.vscode-lark \
                 James-Yu.latex-workshop \
                 valentjn.vscode-ltex \
                 mesonbuild.mesonbuild \
                 Decodetalkers.neocmakelsp-vscode \
                 KurtBoehm.picta-vscode-theme \
                 esbenp.prettier-vscode \
                 ms-python.python \
                 mechatroner.rainbow-csv \
                 charliermarsh.ruff \
                 rust-lang.rust-analyzer \
                 jock.svg \
                 Gruntfuggly.todo-tree \
                 13xforever.language-x86-64-assembly \
                 redhat.vscode-yaml
  code --install-extension $EXTENSION
end
rsync --progress ~/projects/archlinux-config/conf/settings.json "~/.config/Code - OSS/User/settings.json"
```

Install Electron configuration files for Wayland:

```sh
rsync --progress ~/projects/archlinux-config/conf/electron-flags.conf ~/.config/electron37-flags.conf
rsync --progress ~/projects/archlinux-config/conf/electron-flags.conf ~/.config/electron38-flags.conf
```

### Document Tools

Install TeX Live and Biber:

```sh
sudo pacman -S texlive texlive-lang biber
```

Install Zathura including MuPDF support:

```sh
zathura zathura-pdf-mupdf
```

Install other document tools:

```sh
sudo pacman -S img2pdf libreoffice-fresh pandoc
```

### Media Tools

Install some media tools, including Inkscape and VLC:

```sh
sudo pacman -S gst-libav inkscape vlc
```

### System Administration

Install Resources, a nice resource monitor utility:

```sh
sudo pacman -S resources
```

Install and set up Samba:

```sh
sudo pacman -S samba
cd /etc/samba
sudo wget -O smb.conf "https://git.samba.org/samba.git/?p=samba.git;a=blob_plain;f=examples/smb.conf.default;hb=HEAD"
systemctl enable smb
systemctl start smb
```

Fix the default NTFS mount options by adding the following lines to `/etc/udisks2/mount_options.conf`:

```ini
[defaults]
ntfs_defaults=uid=$UID,gid=$GID,noatime
```

Install printer support:

```sh
sudo pacman -S cups python-pysmbc system-config-printer
systemctl start cups
systemctl enable cups
```

Now printers (including ones using SMB) can be added using GUI tools, not just CUPS’s web interface.
For instance, at TU Clausthal, there are `smb://print.rz.tu-clausthal.de/ifm-r202-mfp-color-a3` and `smb://print.rz.tu-clausthal.de/ifm-r303-mfp-color-a3` (both Ricoh IM C3500).

Install `cpupower-gui` to control CPU performance settings:

```sh
yay -S cpupower-gui
```

### NVIDIA on Wayland

_These steps may no longer be necessary on newer Linux versions._

1. In `/etc/mkinitcpio.conf`, replace `MODULES=()` with `MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)`
2. Run `sudo mkinitcpio -P`, potentially removing the fallback `initramfs` to make space
3. In `/etc/default/grub`, set `GRUB_CMDLINE_LINUX_DEFAULT` to `loglevel=3 quiet nvidia_drm.modeset=1`
4. Run `sudo grub-mkconfig -o /boot/grub/grub.cfg`
5. Run `sudo ln -s /dev/null /etc/udev/rules.d/61-gdm.rules` to disable GDM’s rules for Wayland availability
