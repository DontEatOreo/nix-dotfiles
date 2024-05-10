{pkgs, ...}: {
  nix = {
    package = pkgs.nix;
    # Garbage Collection
    gc = {
      automatic = true;
      interval.Day = 7;
      options = "--delete-older-than 7d";
    };
    # auto-optimise-store = true
    extraOptions = ''
      experimental-features = nix-command flakes
      builders-use-substitutes = true
      build-use-substitutes = true
    '';
    settings = {
      trusted-users = [
        "root"
        "nyx"
        "anon"
      ];
      # Trust Devenv Shell
      trusted-substituters = [
        "https://devenv.cachix.org"
      ];
      trusted-public-keys = [
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      ];
    };

    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "192.168.88.248";
        system = "x86_64-linux";
        protocol = "ssh";
        sshUser = "nyx";
        sshKey = "/Users/anon/.ssh/id_rsa";
        maxJobs = 1;
        speedFactor = 2;
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      }
      {
        hostName = "192.168.0.102";
        system = "x86_64-linux";
        protocol = "ssh";
        sshUser = "nyx";
        sshKey = "/Users/anon/.ssh/id_rsa";
        maxJobs = 1;
        speedFactor = 2;
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      }
    ];
  };
}
