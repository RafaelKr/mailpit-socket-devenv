{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
let
  pkgs-mailpit = import inputs.nixpkgs-mailpit {
    system = pkgs.stdenv.system;
  };

  mailpitSmtpSocketPath = "${config.env.DEVENV_RUNTIME}/mp-smtp.sock";
  mailpitUiSocketPath = "${config.env.DEVENV_RUNTIME}/mp-http.sock";
in
{
  dotenv.enable = true;

  # Environment variables
  env.MAILER_DSN = lib.mkForce "sendmail://default?command=${config.services.mailpit.package}/bin/mailpit%20sendmail%20-S%20unix:${mailpitSmtpSocketPath}%20-bs";

  enterShell = ''
    test -d vendor || composer install
  '';

  services.mailpit = {
    enable = true;
    package = pkgs-mailpit.mailpit;
    smtpListenAddress = "unix:${mailpitSmtpSocketPath}:660";
    uiListenAddress = "unix:${mailpitUiSocketPath}:660";
    additionalArgs = [
      "--webroot=/mailpit/"
    ];
  };

  languages.php = {
    enable = true;

    fpm.pools.web.settings = {
      # Based on symfony-cli
      # https://github.com/symfony-cli/symfony-cli/blob/9ad7d616f77a3158f8289c23f7387aa7f590bf53/local/php/fpm.go

      "clear_env" = "no";
      "pm" = "dynamic";
      "pm.max_children" = 10;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 1;
      "pm.max_spare_servers" = 10;

      "catch_workers_output" = "yes";

      "env['LC_ALL']" = "C";
    };
  };

  services.caddy = {
    enable = true;

    virtualHosts = {
      ":8000" = {
        extraConfig = ''
          redir /mailpit /mailpit/
          handle_path /mailpit/* {
            rewrite * /mailpit{path}
            reverse_proxy unix/${mailpitUiSocketPath}
          }

          root * public

          # Be careful! The full path to a socket can have a maximum of 107 characters.
          # Everything after is sliced of.
          php_fastcgi "unix/${config.languages.php.fpm.pools.web.socket}"

          file_server

          encode zstd gzip
        '';
      };
    };
  };
}

