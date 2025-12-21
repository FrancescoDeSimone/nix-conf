{ pkgs, ... }: {
  home.packages = with pkgs; [
    gcc
    clang
    cmake
    gnumake
    ninja
    pkg-config
    gdb
    lldb
    clang-tools
    cppcheck
    valgrind
  ];
}
