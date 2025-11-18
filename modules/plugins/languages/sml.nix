{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (builtins) attrNames;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.types) enum;
  inherit (lib.nvim.types) deprecatedSingleOrListOf;
  inherit (lib.nvim.attrsets) mapListToAttrs;
  inherit (lib.generators) mkLuaInline;

  cfg = config.vim.languages.sml;

  defaultServers = ["millet"];
  servers = {
    millet = {
      enable = true;
      cmd = [(getExe pkgs.millet)];
      filetypes = ["sml"];
      root_dir =
        mkLuaInline /* lua */ ''
          function(bufnr, on_dir)
            local fname = vim.api.nvim_buf_get_name(bufnr)
            on_dir(util.root_pattern('millet.toml', '*.cm', '*.mlb', '.git', '*.sml')(fname))
          end
        '';
      settings = {};
    };
  };

  defaultFormat = ["smlfmt"];
  formats = {
    smlfmt = {
      command = getExe pkgs.smlfmt;
    };
  };

in {
  options.vim.languages.sml = {
    enable = mkEnableOption "Standard ML language support";

    # treesitter = {
    #   enable = mkEnableOption "Standard ML treesitter" // {default = config.vim.languages.enableTreesitter;};
    #
    #   package = mkOption {
    #     type = package;
    #     TODO: this doesn't exist
    #     get the sml grammar into nixpkgs
    #     default = pkgs.vimPlugins.nvim-treesitter.builtGrammars.sml;
    #     description = "Standard ML treesitter grammar to use";
    #   };
    # };

    lsp = {
      enable = mkEnableOption "Standard ML LSP support" // {default = config.vim.lsp.enable;};

      servers = mkOption {
        type = deprecatedSingleOrListOf "vim.language.sml.lsp.servers" (enum (attrNames servers));
        default = defaultServers;
        description = "Standard ML LSP server to use";
      };
    };

    format = {
      enable = mkEnableOption "Standard ML formatting" // {default = config.vim.languages.enableFormat;};

      type = mkOption {
        type = deprecatedSingleOrListOf "vim.language.sml.format.type" (enum (attrNames formats));
        default = defaultFormat;
        description = "Standard ML formatter to use";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # (mkIf cfg.treesitter.enable {
    #   vim.treesitter.enable = true;
    #   vim.treesitter.grammars = [cfg.treesitter.package];
    # })

    (mkIf cfg.lsp.enable {
      vim.lsp.servers =
        mapListToAttrs (n: {
          name = n;
          value = servers.${n};
        })
        cfg.lsp.servers;
    })

    (mkIf cfg.format.enable {
      vim.formatter.conform-nvim = {
        enable = true;
        setupOpts = {
          formatters_by_ft.sml = cfg.format.type;
          formatters =
            mapListToAttrs (name: {
              inherit name;
              value = formats.${name};
            })
            cfg.format.type;
        };
      };
    })
  ]);
}
