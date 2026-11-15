# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    nixpkgs.overlays = [
      (final: previous: {
        ghost-sh = previous.stdenv.mkDerivation {
          pname = "ghost-sh";
          version = "main";

          src = fetchGit {
            url = "https://github.com/h-jangra/Ghost.sh.git";
            ref = "main";
            submodules = true;
          };

          nativeBuildInputs = with previous; [
            zig.hook
          ];

          zigBuildFlags = [
            "-Doptimize=ReleaseFast"
          ];

          installPhase = ''
            runHook preInstall

            install -Dm755 zig-out/bin/ghost $out/bin/ghost
            install -Dm644 ghost.sh $out/share/ghost/ghost.sh

            substituteInPlace $out/share/ghost/ghost.sh --replace-fail '_GHOST_BIN="$(dirname "''${BASH_SOURCE[0]}")/ghost"' "_GHOST_BIN=\"$out/bin/ghost\""
            substituteInPlace $out/share/ghost/ghost.sh --replace-fail 'if ! command -v "$_GHOST_BIN" >/dev/null 2>&1 || [[ ! -t 0 || ! -t 1 || ! -r /dev/tty ]]; then' 'if false; then'

            runHook postInstall
          '';
        };
      })
    ];

    programs.bash = {
      vteIntegration = true;

      completion = {
        enable = true;
        package = pkgs.bash-completion;
      };

      enableLsColors = true;

      undistractMe = {
        enable = true;
        playSound = true;
      };

      # shellAliases = { };

      # loginShellInit = '''';
      # shellInit = '''';
      # interactiveShellInit = '''';
      # promptInit = '''';

      # logout = '''';
    };

    home-manager.sharedModules = [
      {
        programs.bash = {
          enable = true;
          package = pkgs.bashInteractive;

          enableVteIntegration = config.programs.bash.vteIntegration;
          enableCompletion = config.programs.bash.completion.enable;

          shellOptions = [
            "-extdebug"
            "autocd"
            "checkhash"
            "checkjobs"
            "checkwinsize"
            "cmdhist"
            "dotglob"
            "extglob"
            "globstar"
            "gnu_errfmt"
            "histappend"
            "lithist"
          ];

          sessionVariables = {
            HISTTIMEFORMAT = "%F %T ";
          };

          shellAliases = config.programs.bash.shellAliases;

          # profileExtra = '''';

          initExtra = ''
            export PROMPT_COMMAND="history -a"

            export _GHOST_BIN="${pkgs.ghost-sh}/bin/ghost"
            if [[ -f "${pkgs.ghost-sh}/share/ghost/ghost.sh" ]]; then
              source "${pkgs.ghost-sh}/share/ghost/ghost.sh"
            fi
          '';

          # logoutExtra = '''';
        };
      }
    ];

    environment = {
      systemPackages = with pkgs; [
        ghost-sh
      ];

      shells = [
        config.home-manager.users.normal.programs.bash.package
      ];
    };

    users.defaultUserShell = config.home-manager.users.normal.programs.bash.package;
  };
}
