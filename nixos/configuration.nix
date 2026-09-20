{ config, pkgs, inputs, ... }:

let
  myKodi = pkgs.kodi-wayland.passthru.withPackages (kp: with kp; [
    youtube
    libretro
    joystick
    inputstream-adaptive
  ]);
in
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    useDHCP = false;
    hostName = "acekodi";
    wireless.enable = true;
    wireless.networks = {
      "Poundshaggers Refugees - 2.4".psk = pkgs.lib.strings.trim (builtins.readFile
        "/home/pocket/secrets/wifi-poundshaggers"
      );
    };
    interfaces.wlp2s0 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "10.0.0.44";
        prefixLength = 24;
      }];
    };
    defaultGateway = "10.0.0.1";
    nameservers = [ "1.0.0.1" "1.1.1.1" ];
  };
  networking.networkmanager.enable = false;

  time.timeZone = "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  #services.xserver.enable = true;
  #services.displayManager.autoLogin = {
  #  enable = true;
  #  user = "kodi";
  #  #user = "pocket";
  #};
  #services.xserver.dpi = 192;

  # Cinnamon
  #services.xserver.displayManager.lightdm.greeters.slick  = {
  #  enable = true;
  #  font = {
  #    name = "Sans 14";
  #    package = pkgs.dejavu_fonts;
  #  };
  #};
  #services.xserver.desktopManager.cinnamon.enable = true;

  # Kodi
  #services.xserver.desktopManager.kodi = {
  #  enable = true;
  #  package = (pkgs.kodi.withPackages (kp: with kp; [
  #    kp.joystick
  #    kp.youtube
  #    kp.invidious
  #  ]));
  #};
  #services.xserver.displayManager.lightdm.greeter.enable = false;
  users.extraUsers.kodi = {
    isNormalUser = true;
    extraGroups = [ ];
  };
  systemd.services.kodi.environment = {
    KODI_AE_SINK = "PIPEWIRE";
  };
  services.cage = {
    enable = true;
    user = "kodi";
    program = "${myKodi}/bin/kodi-standalone";
    extraArguments = [ "-s" ];
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  hardware.bluetooth.enable = true;

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  hardware.enableAllFirmware = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  systemd.tmpfiles.rules = [
    "d /mnt 0777 root root -"
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  users.users."pocket" = {
    isNormalUser = true;
    description = "pocket";
    extraGroups = [ "wheel" ];
  };

  environment.variables = {
    EDITOR = "vim";
    GDK_SCALE = "2";
    GDK_DPI_SCALE = "0.5";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
  };

  environment.systemPackages = with pkgs; [
    gnumake
    lsb-release
    dbus
    htop
    tmux
    vim
    git
    wget
    at
    zip
    unzip
    gnupg
    pinentry-tty
    home-manager
    lame
    fdk-aac-encoder
    flac
    vorbis-tools
    opus-tools
    ffmpeg
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
  ];

  #sops.defaultSopsFile = "/etc/nixos/secrets.yaml";
  #sops.gnupg.home = "/home/pocket/.gnupg";

  # programs.mtr.enable = true;

  programs.firefox.enable = true;

  programs.bash = {
    enable = true;
    completion.enable = true;
  };

  # gpg
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-tty;
    enableSSHSupport = true;
  };

  services.openssh.enable = true;

  services.tailscale = {
    enable = true;
    authKeyFile = "/home/pocket/secrets/tailscale-authkey";
  };

  programs.tmux = {
    enable = true;
    clock24 = true;
    extraConfig = ''
      set-option -g repeat-time 100
      set-option -g mouse on
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
    '';
  };

  # hermes
  #services.hermes-agent = {
  #  enable = true;
  #  config = {
  #    model.default = "openai/gpt-4o";
  #  };
  #  environmentFiles = [ "/home/pocket/secrets/hermes-env" ];
  #  documents = {
  #    "SOUL.md" = ''
  #      # SOUL.md
  #      You are a graduate student that works with non-profits in the medical field in a class about developing new technologies and planning the integration of these new technologies into a community or organization. You are in a group project with other students where you will collaborate on planning and finishing tasks.
  #    '';
  #    "AGENTS.md" = ''
  #      # AGENTS.md
  #      Read SOUL.md first. Then help the user.
  #    '';
  #    "USER.md" = ''
  #      # USER.md
  #      Name: Classmate
  #    '';
  #  };
  #  skills = {};
  #  mcpServers = {};
  #  extraPackages = with pkgs; [
  #    jq
  #    ripgrep
  #    fd
  #    curl
  #  ];
  #};

  networking.firewall.allowedTCPPorts = [
    22
    8080
  ];
  networking.firewall.allowedUDPPorts = [
    config.services.tailscale.port
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

}
