{ pkgs, lib, config, ... }:

  {
    dotenv.disableHint = true;

    # add NodeJs just in case you want to use it
    languages.javascript = {
      enable = true;
      package = pkgs.nodejs_latest;
    };

    # Configure php and add some basic php.ini settings to it
    languages.php = {
      enable = true;
      version = "8.4";
      extensions = [];

      ini = ''
        memory_limit = 512M
      '';

      # Configure php fpm pools for future use
      fpm.pools.web = {
        settings = {
          "pm" = "dynamic";
          "pm.max_children" = 5;
          "pm.start_servers" = 2;
          "pm.min_spare_servers" = 1;
          "pm.max_spare_servers" = 5;
        };
      };
    };

    services.caddy.enable = true;

    # add our virtual host like in the course
    services.caddy.virtualHosts."http://todo.local:8000" = {
      extraConfig = ''
        root * public
        php_fastcgi unix/${config.languages.php.fpm.pools.web.socket}{
            trusted_proxies private_ranges
        }
        file_server
        encode

        encode zstd gzip
      '';
    };

    # add mysql
    services.mysql = {
      enable = true;
      package = pkgs.mysql80;
      initialDatabases = [{ name = "todo"; }];

      ensureUsers = [
        {
          name = "todo";
          password = "todo";
          ensurePermissions = {
            "phpiggy.*" = "ALL PRIVILEGES";
          };
        }
      ];

      # some recommended settings which mysql should have set
      settings = {
        mysqld = {
          group_concat_max_len = 320000;
          log_bin_trust_function_creators = 1;
          sql_mode = "STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION";
        };
      };
    };
  }