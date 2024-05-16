{ pkgs, lib, inputs, config, ... }: {
  programs.htop = {
    enable = true;
    settings = {
      fields = with config.lib.htop.fields; [
        PID
        STATE
        USER
        PERCENT_CPU
        PERCENT_MEM
        COMM
      ];
      hide_kernel_threads = 0;
      hide_userland_threads = 0;
      shadow_other_users = 0;
      show_thread_names = 0;
      show_program_path = 0;
      highlight_base_name = 1;
      highlight_deleted_exe = 1;
      highlight_megabytes = 1;
      highlight_threads = 1;
      highlight_changes = 0;
      highlight_changes_delay_secs = 5;
      find_comm_in_cmdline = 1;
      strip_exe_from_cmdline = 1;
      show_merged_command = 0;
      header_margin = 1;
      screen_tabs = 1;
      detailed_cpu_time = 1;
      cpu_count_from_one = 1;
      show_cpu_usage = 1;
      show_cpu_frequency = 1;
      show_cpu_temperature = 1;
      degree_fahrenheit = 0;
      update_process_names = 1;
      account_guest_in_cpu_meter = 1;
      enable_mouse = 1;
      delay = 15;
      hide_function_bar = 0;
      header_layout = "four_25_25_25_25";
      column_meters_0 = "Hostname Uptime DiskIO";
      column_meter_modes_0 = "2 2 2";
      column_meters_1 = "LeftCPUs2";
      column_meter_modes_1 = 1;
      column_meters_2 = "RightCPUs2";
      column_meter_modes_2 = 1;
      column_meters_3 = "Memory LoadAverage NetworkIO";
      column_meter_modes_3 = "2 2 2";
      tree_view = 1;
      sort_key = 46;
      sort_direction = -1;
      tree_sort_direction = 1;
      tree_view_always_by_pid = 1;
      all_branches_collapsed = 0;
    };
  };

}
