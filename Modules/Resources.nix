# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      resources
    ];

    programs.dconf.profiles.user.databases = [
      {
        lockAll = true;

        settings = {
          "org/gnome/Resources" = {
            apps-show-combined-memory = true;
            apps-show-cpu = true;
            apps-show-decoder = true;
            apps-show-drive-read-speed = true;
            apps-show-drive-read-total = true;
            apps-show-drive-write-speed = true;
            apps-show-drive-write-total = true;
            apps-show-encoder = true;
            apps-show-gpu = true;
            apps-show-gpu-memory = true;
            apps-show-memory = true;
            apps-show-swap = true;
            base = "Binary";
            network-bits = false;
            processes-show-combined-memory = true;
            processes-show-commandline = true;
            processes-show-cpu = true;
            processes-show-decoder = true;
            processes-show-drive-read-speed = true;
            processes-show-drive-read-total = true;
            processes-show-drive-write-speed = true;
            processes-show-drive-write-total = true;
            processes-show-encoder = true;
            processes-show-gpu = true;
            processes-show-gpu-memory = true;
            processes-show-id = true;
            processes-show-memory = true;
            processes-show-priority = true;
            processes-show-swap = true;
            processes-show-system-cpu-time = true;
            processes-show-total-cpu-time = true;
            processes-show-user = true;
            processes-show-user-cpu-time = true;
            refresh-speed = "VeryFast";
            show-graph-grids = true;
            show-logical-cpus = true;
            show-virtual-drives = true;
            show-virtual-network-interfaces = true;
            sidebar-meter-type = "Graph";
            temperature-unit = "Celsius";
          };
        };
      }
    ];
  };
}
