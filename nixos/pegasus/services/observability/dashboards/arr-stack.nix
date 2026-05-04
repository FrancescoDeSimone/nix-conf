{ common }:
let
  mkStat =
    {
      title,
      expr,
      x,
      y,
      unit ? "none",
      w ? 4,
      h ? 4,
      colorMode ? "value",
    }:
    {
      inherit title;
      type = "stat";
      gridPos = {
        inherit
          h
          w
          x
          y
          ;
      };
      datasource = common.datasource;
      targets = [
        {
          inherit expr;
          instant = true;
        }
      ];
      options = {
        inherit colorMode;
        graphMode = "none";
        textMode = "value";
        reduceOptions.calcs = [ "lastNotNull" ];
      };
      fieldConfig.defaults = {
        inherit unit;
        decimals = 0;
        color.mode = "thresholds";
        thresholds = {
          mode = "absolute";
          steps = [
            {
              color = "green";
              value = null;
            }
          ];
        };
      };
    };

  mkTimeseries =
    {
      title,
      targets,
      x,
      y,
      w ? 12,
      h ? 8,
      unit ? "none",
    }:
    {
      inherit title;
      type = "timeseries";
      gridPos = {
        inherit
          h
          w
          x
          y
          ;
      };
      datasource = common.datasource;
      inherit targets;
      fieldConfig.defaults = {
        inherit unit;
        custom = {
          drawStyle = "line";
          lineWidth = 2;
          fillOpacity = 12;
        };
      };
      options.legend = {
        displayMode = "table";
        placement = "bottom";
      };
    };

  mkBarGauge =
    {
      title,
      expr,
      x,
      y,
      w ? 12,
      h ? 8,
    }:
    {
      inherit title;
      type = "bargauge";
      gridPos = {
        inherit
          h
          w
          x
          y
          ;
      };
      datasource = common.datasource;
      targets = [
        {
          inherit expr;
          instant = true;
        }
      ];
      options = {
        orientation = "horizontal";
        displayMode = "gradient";
        showUnfilled = true;
        reduceOptions = {
          calcs = [ "lastNotNull" ];
          fields = "";
          values = false;
        };
      };
      fieldConfig.defaults.color.mode = "palette-classic";
    };

  mkLabelTable =
    {
      title,
      expr,
      x,
      y,
      renameByName,
      w ? 6,
      h ? 8,
    }:
    {
      inherit title;
      type = "table";
      gridPos = {
        inherit
          h
          w
          x
          y
          ;
      };
      datasource = common.datasource;
      targets = [
        {
          inherit expr;
          instant = true;
          format = "table";
        }
      ];
      transformations = [
        {
          id = "labelsToFields";
          options.mode = "columns";
        }
        {
          id = "organize";
          options = {
            excludeByName = {
              Time = true;
              __name__ = true;
              instance = true;
              job = true;
              url = true;
            };
            inherit renameByName;
          };
        }
      ];
      fieldConfig.defaults.custom.align = "auto";
    };
in
{
  uid = "arr-stack";
  title = "Arr Stack";
  tags = [
    "arr"
    "media"
    "servarr"
    "prowlarr"
  ];
  timezone = "browser";
  schemaVersion = 39;
  version = 1;
  refresh = "30s";
  time = {
    from = "now-24h";
    to = "now";
  };
  panels = [
    {
      type = "row";
      title = "Overview";
      gridPos = {
        h = 1;
        w = 24;
        x = 0;
        y = 0;
      };
    }
    (mkStat {
      title = "Sonarr Series";
      expr = "sum(sonarr_series_total)";
      x = 0;
      y = 1;
    })
    (mkStat {
      title = "Missing Episodes";
      expr = "sum(sonarr_episode_missing_total)";
      x = 4;
      y = 1;
    })
    (mkStat {
      title = "Radarr Movies";
      expr = "sum(radarr_movie_total)";
      x = 8;
      y = 1;
    })
    (mkStat {
      title = "Wanted Movies";
      expr = "sum(radarr_movie_wanted_total)";
      x = 12;
      y = 1;
    })
    (mkStat {
      title = "Lidarr Artists";
      expr = "sum(lidarr_artists_total)";
      x = 16;
      y = 1;
    })
    (mkStat {
      title = "Prowlarr Indexers";
      expr = "sum(prowlarr_indexer_total)";
      x = 20;
      y = 1;
    })
    {
      type = "row";
      title = "Sonarr";
      gridPos = {
        h = 1;
        w = 24;
        x = 0;
        y = 5;
      };
    }
    (mkTimeseries {
      title = "Series and Episode Health";
      x = 0;
      y = 6;
      targets = [
        {
          expr = "sum(sonarr_series_total)";
          legendFormat = "Series";
        }
        {
          expr = "sum(sonarr_series_downloaded_total)";
          legendFormat = "Downloaded Series";
        }
        {
          expr = "sum(sonarr_episode_missing_total)";
          legendFormat = "Missing Episodes";
        }
        {
          expr = "sum(sonarr_episode_cutoff_unmet_total)";
          legendFormat = "Cutoff Unmet";
        }
      ];
    })
    (mkBarGauge {
      title = "Episode Quality Mix";
      expr = ''sum by (quality) (sonarr_episode_quality_total)'';
      x = 12;
      y = 6;
    })
    {
      type = "row";
      title = "Radarr";
      gridPos = {
        h = 1;
        w = 24;
        x = 0;
        y = 14;
      };
    }
    (mkTimeseries {
      title = "Movie Inventory";
      x = 0;
      y = 15;
      targets = [
        {
          expr = "sum(radarr_movie_total)";
          legendFormat = "Movies";
        }
        {
          expr = "sum(radarr_movie_downloaded_total)";
          legendFormat = "Downloaded";
        }
        {
          expr = "sum(radarr_movie_wanted_total)";
          legendFormat = "Wanted";
        }
        {
          expr = "sum(radarr_movie_missing_total)";
          legendFormat = "Missing";
        }
      ];
    })
    (mkBarGauge {
      title = "Movie Quality Mix";
      expr = ''sum by (quality) (radarr_movie_quality_total)'';
      x = 12;
      y = 15;
      w = 6;
    })
    (mkLabelTable {
      title = "Top Movie Tags";
      expr = ''topk(15, sum by (tag) (radarr_movie_tag_total))'';
      x = 18;
      y = 15;
      w = 6;
      renameByName = {
        tag = "Tag";
        Value = "Movies";
      };
    })
    {
      type = "row";
      title = "Lidarr";
      gridPos = {
        h = 1;
        w = 24;
        x = 0;
        y = 23;
      };
    }
    (mkTimeseries {
      title = "Music Library";
      x = 0;
      y = 24;
      targets = [
        {
          expr = "sum(lidarr_artists_total)";
          legendFormat = "Artists";
        }
        {
          expr = "sum(lidarr_albums_total)";
          legendFormat = "Albums";
        }
        {
          expr = "sum(lidarr_albums_missing_total)";
          legendFormat = "Missing Albums";
        }
        {
          expr = "sum(lidarr_songs_downloaded_total)";
          legendFormat = "Downloaded Songs";
        }
      ];
    })
    (mkBarGauge {
      title = "Song Quality Mix";
      expr = ''sum by (quality) (lidarr_songs_quality_total)'';
      x = 12;
      y = 24;
      w = 6;
    })
    (mkLabelTable {
      title = "Top Genres";
      expr = ''topk(12, (sum by (genre) (lidarr_artists_genres_total)) + (sum by (genre) (lidarr_albums_genres_total)))'';
      x = 18;
      y = 24;
      w = 6;
      renameByName = {
        genre = "Genre";
        Value = "Count";
      };
    })
    {
      type = "row";
      title = "Prowlarr";
      gridPos = {
        h = 1;
        w = 24;
        x = 0;
        y = 32;
      };
    }
    (mkStat {
      title = "Enabled Indexers";
      expr = "sum(prowlarr_indexer_enabled_total)";
      x = 0;
      y = 33;
    })
    (mkStat {
      title = "Unavailable Indexers";
      expr = ''count(prowlarr_indexer_unavailable) or vector(0)'';
      x = 4;
      y = 33;
    })
    (mkStat {
      title = "Avg Response";
      expr = "avg(prowlarr_indexer_average_response_time_ms)";
      x = 8;
      y = 33;
      unit = "ms";
    })
    (mkStat {
      title = "Tracked User Agents";
      expr = "sum(prowlarr_user_agent_total)";
      x = 12;
      y = 33;
    })
    (mkStat {
      title = "Nearest VIP Expiry";
      expr = "min(prowlarr_indexer_vip_expires_in_seconds)";
      x = 16;
      y = 33;
      unit = "s";
    })
    (mkStat {
      title = "Total Grabs";
      expr = "sum(prowlarr_indexer_grabs_total)";
      x = 20;
      y = 33;
    })
    (mkLabelTable {
      title = "Indexer Response Times";
      expr = ''topk(15, sort_desc(prowlarr_indexer_average_response_time_ms))'';
      x = 0;
      y = 37;
      w = 12;
      renameByName = {
        indexer = "Indexer";
        Value = "Response ms";
      };
    })
    (mkLabelTable {
      title = "Indexer Failed Queries";
      expr = ''topk(15, sort_desc(prowlarr_indexer_failed_queries_total))'';
      x = 12;
      y = 37;
      w = 12;
      renameByName = {
        indexer = "Indexer";
        Value = "Failed Queries";
      };
    })
  ];
}
