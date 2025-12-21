{pkgs, ...}: {
  home.packages = with pkgs; [
    valgrind
    gdb
    massif-visualizer
    heaptrack
    hotspot
    samply
    cargo-flamegraph
    cargo-expand
    rr
    linuxPackages.perf
  ];
}
