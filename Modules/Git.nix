# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    programs.git = {
      enable = true;
      package = (
        pkgs.gitFull.override {
          guiSupport = true;
          sendEmailSupport = true;
          svnSupport = true;
          withLibsecret = true;
          withManual = true;
          withpcre2 = true;
          withSsh = config.home-manager.users.normal.programs.ssh.enable;
        }
      );

      lfs = {
        enable = true;
        package = pkgs.git-lfs;

        enablePureSSHTransfer = config.home-manager.users.normal.programs.ssh.enable;
      };

      prompt.enable = true;
    };

    environment.systemPackages = with pkgs; [
      git-big-picture
      git-filter-repo
      git-open
      git-repo
      gitlogue
      gource
      ugit
    ];

    home-manager.sharedModules = [
      {
        programs.mcp.servers.mcp-server-git = {
          enabled = true;

          command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
        };
      }
    ];
  };
}
