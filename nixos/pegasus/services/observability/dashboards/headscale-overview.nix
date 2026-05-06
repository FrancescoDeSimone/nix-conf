{common}: {
  uid = "headscale-overview";
  title = "Headscale Overview";
  tags = [
    "headscale"
    "tailscale"
    "tailscale-mixin"
  ];
  timezone = "browser";
  schemaVersion = 39;
  refresh = "30s";
  panels = [
    {
      title = "Users";
      type = "stat";
      gridPos = {
        h = 4;
        w = 4;
        x = 0;
        y = 0;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "count(headscale_users_info)";
          instant = true;
        }
      ];
      options = {
        colorMode = "background";
        graphMode = "area";
        reduceOptions.calcs = ["lastNotNull"];
      };
      fieldConfig.defaults.unit = "short";
    }
    {
      title = "Nodes";
      type = "stat";
      gridPos = {
        h = 4;
        w = 4;
        x = 4;
        y = 0;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "count(headscale_nodes_info)";
          instant = true;
        }
      ];
      options = {
        colorMode = "background";
        graphMode = "area";
        reduceOptions.calcs = ["lastNotNull"];
      };
      fieldConfig.defaults.unit = "short";
    }
    {
      title = "Online Nodes";
      type = "stat";
      gridPos = {
        h = 4;
        w = 4;
        x = 8;
        y = 0;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "sum(headscale_nodes_online)";
          instant = true;
        }
      ];
      options = {
        colorMode = "background";
        graphMode = "area";
        reduceOptions.calcs = ["lastNotNull"];
      };
      fieldConfig.defaults.unit = "short";
    }
    {
      title = "API Keys";
      type = "stat";
      gridPos = {
        h = 4;
        w = 4;
        x = 12;
        y = 0;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "count(headscale_apikeys_info)";
          instant = true;
        }
      ];
      options = {
        colorMode = "background";
        graphMode = "area";
        reduceOptions.calcs = ["lastNotNull"];
      };
      fieldConfig.defaults.unit = "short";
    }
    {
      title = "Pre-auth Keys";
      type = "stat";
      gridPos = {
        h = 4;
        w = 4;
        x = 16;
        y = 0;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "count(headscale_preauthkeys_info)";
          instant = true;
        }
      ];
      options = {
        colorMode = "background";
        graphMode = "area";
        reduceOptions.calcs = ["lastNotNull"];
      };
      fieldConfig.defaults.unit = "short";
    }
    {
      title = "Database Connectivity";
      type = "stat";
      gridPos = {
        h = 4;
        w = 4;
        x = 20;
        y = 0;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "max(headscale_health_database_connectivity)";
          instant = true;
        }
      ];
      options = {
        colorMode = "background";
        graphMode = "area";
        reduceOptions.calcs = ["lastNotNull"];
      };
      fieldConfig.defaults.mappings = [
        {
          type = "value";
          options = {
            "0" = {
              text = "Down";
              color = "red";
            };
            "1" = {
              text = "Up";
              color = "green";
            };
          };
        }
      ];
      fieldConfig.defaults.unit = "bool";
    }
    {
      title = "Nodes by Register Method";
      type = "piechart";
      gridPos = {
        h = 5;
        w = 8;
        x = 0;
        y = 4;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "count(headscale_nodes_info) by (register_method)";
          instant = true;
          legendFormat = "{{register_method}}";
        }
      ];
      options = {
        displayLabels = ["percent"];
        legend = {
          displayMode = "table";
          placement = "right";
          showLegend = true;
          values = ["percent"];
        };
        tooltip = {
          mode = "multi";
          sort = "desc";
        };
      };
      fieldConfig.defaults.unit = "short";
    }
    {
      title = "Pre-auth Keys Usage";
      type = "piechart";
      gridPos = {
        h = 5;
        w = 8;
        x = 8;
        y = 4;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "count(headscale_preauthkeys_info{used=\"true\"})";
          instant = true;
          legendFormat = "Used";
        }
        {
          expr = "count(headscale_preauthkeys_info{used=\"false\"})";
          instant = true;
          legendFormat = "Unused";
        }
      ];
      options = {
        displayLabels = ["percent"];
        legend = {
          displayMode = "table";
          placement = "right";
          showLegend = true;
          values = ["percent"];
        };
        tooltip = {
          mode = "multi";
          sort = "desc";
        };
      };
      fieldConfig.defaults.unit = "short";
    }
    {
      title = "Users by Provider";
      type = "piechart";
      gridPos = {
        h = 5;
        w = 8;
        x = 16;
        y = 4;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "count(headscale_users_info) by (provider)";
          instant = true;
          legendFormat = "{{provider}}";
        }
      ];
      options = {
        displayLabels = ["percent"];
        legend = {
          displayMode = "table";
          placement = "right";
          showLegend = true;
          values = ["percent"];
        };
        tooltip = {
          mode = "multi";
          sort = "desc";
        };
      };
      fieldConfig.defaults.unit = "short";
    }
    {
      title = "Nodes Requiring Attention";
      type = "table";
      gridPos = {
        h = 7;
        w = 24;
        x = 0;
        y = 9;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "1 - max(headscale_nodes_online) by (id, name, user) > 0";
          format = "table";
          instant = true;
        }
        {
          expr = "sum(headscale_nodes_available_routes) by (id, name, user) - sum(headscale_nodes_approved_routes) by (id, name, user) > 0";
          format = "table";
          instant = true;
        }
      ];
      transformations = [
        {
          id = "merge";
        }
        {
          id = "organize";
          options = {
            excludeByName = {
              Time = true;
              __name__ = true;
            };
            renameByName = {
              "Value #A" = "Offline";
              "Value #B" = "Unapproved Routes";
              id = "ID";
              name = "Name";
              user = "User";
            };
          };
        }
      ];
      options = {
        footer = {
          enablePagination = true;
        };
        sortBy = [
          {
            desc = false;
            displayName = "Name";
          }
        ];
      };
      fieldConfig.defaults.unit = "string";
      fieldConfig.overrides = [
        {
          matcher = {
            id = "byName";
            options = "Offline";
          };
          properties = [
            {
              id = "mappings";
              value = [
                {
                  type = "value";
                  options = {
                    "0" = {
                      text = "No";
                    };
                    "1" = {
                      text = "Yes";
                    };
                  };
                }
              ];
            }
          ];
        }
        {
          matcher = {
            id = "byName";
            options = "Unapproved Routes";
          };
          properties = [
            {
              id = "mappings";
              value = [
                {
                  type = "value";
                  options = {
                    "0" = {
                      text = "No";
                    };
                    "1" = {
                      text = "Yes";
                    };
                  };
                }
              ];
            }
          ];
        }
      ];
    }
    {
      title = "Nodes";
      type = "table";
      gridPos = {
        h = 12;
        w = 24;
        x = 0;
        y = 16;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "headscale_nodes_info";
          format = "table";
          instant = true;
        }
        {
          expr = "headscale_nodes_created_timestamp * 1000";
          format = "table";
          instant = true;
        }
        {
          expr = "headscale_nodes_last_seen_timestamp * 1000";
          format = "table";
          instant = true;
        }
        {
          expr = "headscale_nodes_expiry_timestamp * 1000";
          format = "table";
          instant = true;
        }
      ];
      transformations = [
        {
          id = "merge";
        }
        {
          id = "organize";
          options = {
            excludeByName = {
              Time = true;
              __name__ = true;
              cluster = true;
              job = true;
              namespace = true;
            };
            renameByName = {
              "Value #A" = "Created";
              "Value #B" = "Last Seen";
              "Value #C" = "Expiry";
              given_name = "Given Name";
              id = "ID";
              machine_key = "Machine Key";
              name = "Name";
              node_key = "Node Key";
              register_method = "Register Method";
              user = "User";
            };
          };
        }
      ];
      options = {
        footer = {
          enablePagination = true;
        };
        sortBy = [
          {
            desc = false;
            displayName = "Name";
          }
        ];
      };
      fieldConfig.defaults.unit = "string";
      fieldConfig.overrides = [
        {
          matcher = {
            id = "byName";
            options = "Created";
          };
          properties = [
            {
              id = "unit";
              value = "dateTimeAsIso";
            }
          ];
        }
        {
          matcher = {
            id = "byName";
            options = "Last Seen";
          };
          properties = [
            {
              id = "unit";
              value = "dateTimeAsIso";
            }
          ];
        }
        {
          matcher = {
            id = "byName";
            options = "Expiry";
          };
          properties = [
            {
              id = "unit";
              value = "dateTimeAsIso";
            }
          ];
        }
      ];
    }
    {
      title = "Users";
      type = "table";
      gridPos = {
        h = 8;
        w = 24;
        x = 0;
        y = 28;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "headscale_users_info";
          format = "table";
          instant = true;
        }
      ];
      transformations = [
        {
          id = "organize";
          options = {
            excludeByName = {
              Time = true;
              __name__ = true;
              cluster = true;
              job = true;
              namespace = true;
            };
            renameByName = {
              display_name = "Display Name";
              email = "Email";
              id = "ID";
              name = "Name";
              provider = "Provider";
              provider_id = "Provider ID";
            };
          };
        }
      ];
      options = {
        footer = {
          enablePagination = true;
        };
        sortBy = [
          {
            desc = false;
            displayName = "Name";
          }
        ];
      };
      fieldConfig.defaults.unit = "string";
    }
    {
      title = "API Keys";
      type = "table";
      gridPos = {
        h = 10;
        w = 12;
        x = 0;
        y = 36;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "min(headscale_apikeys_created_timestamp * 1000) by (id, prefix)";
          format = "table";
          instant = true;
        }
        {
          expr = "min(headscale_apikeys_expiration_timestamp * 1000) by (id, prefix)";
          format = "table";
          instant = true;
        }
        {
          expr = "max(headscale_apikeys_last_seen_timestamp * 1000) by (id, prefix)";
          format = "table";
          instant = true;
        }
      ];
      transformations = [
        {
          id = "merge";
        }
        {
          id = "organize";
          options = {
            excludeByName = {
              Time = true;
              __name__ = true;
              cluster = true;
              job = true;
              namespace = true;
            };
            renameByName = {
              "Value #A" = "Created";
              "Value #B" = "Expires";
              "Value #C" = "Last Seen";
              id = "ID";
              prefix = "Prefix";
            };
          };
        }
      ];
      options = {
        footer = {
          enablePagination = true;
        };
        sortBy = [
          {
            desc = false;
            displayName = "Prefix";
          }
        ];
      };
      fieldConfig.defaults.unit = "string";
      fieldConfig.overrides = [
        {
          matcher = {
            id = "byName";
            options = "Created";
          };
          properties = [
            {
              id = "unit";
              value = "dateTimeAsIso";
            }
          ];
        }
        {
          matcher = {
            id = "byName";
            options = "Expires";
          };
          properties = [
            {
              id = "unit";
              value = "dateTimeAsIso";
            }
          ];
        }
        {
          matcher = {
            id = "byName";
            options = "Last Seen";
          };
          properties = [
            {
              id = "unit";
              value = "dateTimeAsIso";
            }
          ];
        }
      ];
    }
    {
      title = "Pre-auth Keys";
      type = "table";
      gridPos = {
        h = 10;
        w = 12;
        x = 12;
        y = 36;
      };
      datasource = common.datasource;
      targets = [
        {
          expr = "headscale_preauthkeys_info";
          format = "table";
          instant = true;
        }
        {
          expr = "min(headscale_preauthkeys_created_timestamp * 1000) by (id, user)";
          format = "table";
          instant = true;
        }
        {
          expr = "min(headscale_preauthkeys_expiration_timestamp * 1000) by (id, user)";
          format = "table";
          instant = true;
        }
      ];
      transformations = [
        {
          id = "merge";
        }
        {
          id = "organize";
          options = {
            excludeByName = {
              Time = true;
              __name__ = true;
              cluster = true;
              job = true;
              namespace = true;
            };
            renameByName = {
              "Value #B" = "Created";
              "Value #C" = "Expiration";
              acl_tags = "ACL Tags";
              ephemeral = "Ephemeral";
              id = "ID";
              reusable = "Reusable";
              used = "Used";
              user = "User";
            };
          };
        }
      ];
      options = {
        footer = {
          enablePagination = true;
        };
        sortBy = [
          {
            desc = false;
            displayName = "User";
          }
        ];
      };
      fieldConfig.defaults.unit = "string";
      fieldConfig.overrides = [
        {
          matcher = {
            id = "byName";
            options = "Created";
          };
          properties = [
            {
              id = "unit";
              value = "dateTimeAsIso";
            }
          ];
        }
        {
          matcher = {
            id = "byName";
            options = "Expiration";
          };
          properties = [
            {
              id = "unit";
              value = "dateTimeAsIso";
            }
          ];
        }
      ];
    }
  ];
}
