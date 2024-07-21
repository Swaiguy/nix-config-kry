## ADAPT UUID PATHS ~ CHANGE UUID TO CURRENT CONFIG
#
#
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Use the EFI boot loader.
  boot.loader.efi.canTouchEfiVariables = true;
  # depending on how you configured your disk mounts, change this to /boot or /boot/efi.
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.systemd-boot.enable = true;

  # boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"]; # kvm virtualization support
  boot.extraModprobeConfig = "options kvm_intel nested=1"; # for intel cpu
  boot.kernelParams = ["nvidia.NVreg_PreserveVideoMemoryAllocations=1"];
  boot.extraModulePackages = [];
  # clear /tmp on boot to get a stateless /tmp directory.
  boot.tmp.cleanOnBoot = true;

  # Enable binfmt emulation of aarch64-linux, this is required for cross compilation.
  boot.binfmt.emulatedSystems = ["aarch64-linux" "riscv64-linux"];
  # supported file systems, so we can mount any removable disks with these filesystems
  boot.supportedFilesystems = [
    "ext4"
    "btrfs"
    "xfs"
    "ntfs"
    "fat"
    "vfat"
    "exfat"
  ];

  boot.initrd = {
    # unlocked luks devices via a keyfile or prompt a passphrase.
    luks.devices."crypted-nixos" = {
      # NOTE: DO NOT use device name here(like /dev/sda, /dev/nvme0n1p2, etc), use UUID instead.
      # https://github.com/ryan4yin/nix-config/issues/43
      device = "/dev/disk/by-uuid/0ac66d30-10e4-4b7f-8b14-249ea0fffdb6";
      # the keyfile(or device partition) that should be used as the decryption key for the encrypted device.
      # if not specified, you will be prompted for a passphrase instead.
      #keyFile = "/root-part.key";

      # whether to allow TRIM requests to the underlying device.
      # it's less secure, but faster.
      allowDiscards = true;
      # Whether to bypass dm-crypt’s internal read and write workqueues.
      # Enabling this should improve performance on SSDs;
      # https://wiki.archlinux.org/index.php/Dm-crypt/Specialties#Disable_workqueue_for_increased_solid_state_drive_(SSD)_performance
      bypassWorkqueues = true;
    };
  };

  fileSystems."/btr_pool" = {
    device = "/dev/disk/by-uuid/4d858c31-8ad4-47e5-be9f-ba8d23b963e6";
    fsType = "btrfs";
    # btrfs's top-level subvolume, internally has an id 5
    # we can access all other subvolumes from this subvolume.
    options = ["subvolid=5"];
  };

  # equal to `mount -t tmpfs tmpfs /`
  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    # set mode to 755, otherwise systemd will set it to 777, which cause problems.
    # relatime: Update inode access times relative to modify or change time.
    options = ["relatime" "mode=755"];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/4d858c31-8ad4-47e5-be9f-ba8d23b963e6";
    fsType = "btrfs";
    options = ["subvol=@nix" "noatime" "compress-force=zstd:1"];
  };

  # for guix store, which use `/gnu/store` as its store directory.
  fileSystems."/gnu" = {
    device = "/dev/disk/by-uuid/4d858c31-8ad4-47e5-be9f-ba8d23b963e6";
    fsType = "btrfs";
    options = ["subvol=@guix" "noatime" "compress-force=zstd:1"];
  };

  fileSystems."/persistent" = {
    device = "/dev/disk/by-uuid/4d858c31-8ad4-47e5-be9f-ba8d23b963e6";
    fsType = "btrfs";
    options = ["subvol=@persistent" "compress-force=zstd:1"];
    # impermanence's data is required for booting.
    neededForBoot = true;
  };

  fileSystems."/snapshots" = {
    device = "/dev/disk/by-uuid/4d858c31-8ad4-47e5-be9f-ba8d23b963e6";
    fsType = "btrfs";
    options = ["subvol=@snapshots" "compress-force=zstd:1"];
  };

  fileSystems."/tmp" = {
    device = "/dev/disk/by-uuid/4d858c31-8ad4-47e5-be9f-ba8d23b963e6";
    fsType = "btrfs";
    options = ["subvol=@tmp" "compress-force=zstd:1"];
  };

  # mount swap subvolume in readonly mode.
  fileSystems."/swap" = {
    device = "/dev/disk/by-uuid/4d858c31-8ad4-47e5-be9f-ba8d23b963e6";
    fsType = "btrfs";
    options = ["subvol=@swap" "ro"];
  };

  # remount swapfile in read-write mode
  fileSystems."/swap/swapfile" = {
    # the swapfile is located in /swap subvolume, so we need to mount /swap first.
    depends = ["/swap"];

    device = "/swap/swapfile";
    fsType = "none";
    options = ["bind" "rw"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/4193-6CDF";
    fsType = "vfat";
  };

  swapDevices = [
    {device = "/swap/swapfile";}
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp5s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlo1.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

