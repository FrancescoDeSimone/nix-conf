{
  lib,
  python3Packages,
  fetchFromGitHub,
}: let
  buildPythonPackage = python3Packages.buildPythonPackage;
in
  buildPythonPackage {
    pname = "lidarr-youtube-downloader";
    version = "0.3.37";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "dmzoneill";
      repo = "lidarr-youtube-downloader";
      rev = "v0.3.37";
      sha256 = "sha256-Cje78NGx+R9ZQKu9h5OY2egfCgu1GAxYi6WP4uBDXHY=";
    };

    build-system = with python3Packages; [setuptools];

    postPatch = ''
      mv lidarr_youtube_downloader/lyd-unmapped.py lidarr_youtube_downloader/lyd_unmapped.py
      rm -f setup.py

      cat > pyproject.toml << 'EOF'
      [build-system]
      requires = ["setuptools>=45"]
      build-backend = "setuptools.build_meta"

      [project]
      name = "lidarr-youtube-downloader"
      version = "0.3.37"
      requires-python = ">=3.10"

      [project.scripts]
      lyd = "lidarr_youtube_downloader.lyd:app"
      lyd-unmapped = "lidarr_youtube_downloader.lyd_unmapped:app"

      [tool.setuptools.package-data]
      "*" = ["view/*"]
      EOF
    '';

    dependencies = with python3Packages; [
      requests
      youtube-search-python
      eyed3
      typer
      yt-dlp
    ];

    meta = with lib; {
      description = "Find and download missing Lidarr tracks from YouTube";
      homepage = "https://github.com/dmzoneill/lidarr-youtube-downloader";
      license = licenses.asl20;
    };
  }
