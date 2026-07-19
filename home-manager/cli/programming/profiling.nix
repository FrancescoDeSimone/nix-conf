{pkgs, ...}: {
  home.packages = with pkgs; [
    valgrind
    gdb
    heaptrack
    hotspot
    samply
    cargo-flamegraph
    cargo-expand
    rr
    perf
  ];
}
