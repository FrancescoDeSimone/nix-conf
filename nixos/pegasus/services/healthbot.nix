{
  pkgs,
  config,
  ...
}: {
  systemd.services.healthbot = {
    description = "Healthbot — Telegram scale/food photo log";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target" "ollama.service"];
    wants = ["network-online.target" "ollama.service"];

    serviceConfig = {
      ExecStart = "${pkgs.healthbot}/bin/healthbot";
      DynamicUser = true;
      StateDirectory = "healthbot";
      # `BOT_TOKEN` comes from the agenix secret `telegram-healthbot`
      # (`secrets/telegram-healthbot.age`); systemd reads the root-only 0400 file
      # before dropping privileges to the DynamicUser.
      #
      # Point the bot at a hosted model instead of the local CPU Ollama by
      # switching these two variables to the 9router gateway, e.g.
      #   VISION_BASE_URL=http://127.0.0.1:20128/v1
      #   VISION_MODEL=gc/gemini-2.5-flash
      # plus `VISION_API_KEY` (a 9router key) in the EnvironmentFile.
      # `ALLOWED_CHAT_IDS` is the group's chat id — send `/id` to the bot to read
      # it, then fill it in and rebuild.
      EnvironmentFile = config.age.secrets."telegram-healthbot".path;
      Environment = [
        "STATE_DIR=/var/lib/healthbot"
        "TZ=Europe/Berlin"
        "VISION_BASE_URL=http://127.0.0.1:${toString config.my.services.ollama.port}/v1"
        "VISION_MODEL=gemma3:latest"
        "ALLOWED_CHAT_IDS="
      ];
      Restart = "on-failure";
      RestartSec = 10;

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
    };
  };
}
