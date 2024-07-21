{mysecrets, ...}: {
  ##home.file.".ssh/romantic.pub".source = "${mysecrets}/public/romantic.pub";

  programs.ssh = {
    enable = true;

    # All my ssh private key are generated by `ssh-keygen -t ed25519 -a 256 -C "xxx@xxx"`
    # Config format:
    #   Host —  given the pattern used to match against the host name given on the command line.
    #   HostName — specify nickname or abbreviation for host
    #   IdentityFile — the location of your SSH key authentication file for the account.
    # Format in details:
    #   https://www.ssh.com/academy/ssh/config
    extraConfig = ''
      # a private key that is used during authentication will be added to ssh-agent if it is running
      AddKeysToAgent yes

      Host 192.168.*
        # allow to securely use local SSH agent to authenticate on the remote machine.
        # It has the same effect as adding cli option `ssh -A user@host`
        ForwardAgent yes
        # romantic holds my homelab~
        IdentityFile /etc/agenix/ssh-key-romantic
        # Specifies that ssh should only use the identity file explicitly configured above
        # required to prevent sending default identity files first.
        IdentitiesOnly yes

      Host gtr5
        HostName 192.168.5.172
        Port 22

      Host um560
        HostName 192.168.5.173
        Port 22

      Host s500plus
        HostName 192.168.5.174
        Port 22
    '';
  };
}
