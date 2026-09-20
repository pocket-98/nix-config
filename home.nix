{ lib, config, pkgs, inputs, ... }:
let
  rcloneRemote = "gdrive";
  rcloneMount = "/mnt/gdrive";
  techLabScript = "${config.home.homeDirectory}/TechLabLocal/watcher.sh";
  hermesHome = "${config.home.homeDirectory}/hermes";
in
{
  home.stateVersion = "26.05";
  home.packages = with pkgs; [
    rclone
    pandoc
    pi-coding-agent
  ];

  home.username = "pocket";
  home.homeDirectory = "/home/pocket";
  home.sessionVariables = {
    EDITOR = "vim";
    GDK_SCALE = "2";
    GDK_DPI_SCALE = "0.5";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
  };

  xresources.properties = {
    "Xft.dpi" = "192";
  };
  #dconf.settings = {
  #  "org/cinnamon/desktop/interface" = {
  #    scaling-factor = lib.hm.gvariant.mkUint32 2;
  #    text-scaling-factor = 1.5;
  #  };
  #  "org.cinnamon.desktop.wm.preferences" = {
  #    titlebar-font = "Ubuntu Medium 14";
  #  };
  #  "org/cinnamon/settings-daemon/plugins/xsettings" = {
  #    overrides = "[{'Gdk/WindowScalingFactor',<2>}]";
  #  };
  #};

  programs.home-manager.enable = true;

  home.file.".vim/tmp/.keep".text = "";

  programs.bash = {
    enable = true;
    initExtra = ''
      # include .profile
      [[ -f ~/.profile ]] && . ~/.profile
    '';
  };

  programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      jellybeans-vim
    ];
    extraConfig = ''
      set nocompatible
      set backupdir=~/.vim/tmp/
      set directory=~/.vim/tmp/
      syntax on
      colorscheme jellybeans
      set t_Co=256
      highlight ExtraWhitespace ctermbg=green guibg=green
      match ExtraWhitespace /\s\+$/
      set autochdir
      set mouse=a
      set showmode
      set showcmd
      set cursorline
      "set rulerformat=%(%5l,%-6(%c%)\ %P%)
      "set ruler
      set autoindent
      set smartindent
      set tabstop=4
      set shiftwidth=4
      set expandtab
      set smartcase
      set ignorecase
      inoremap jj <ESC>
      "map <CR> o<Esc>
      command SudoW :execute ':silent w !sudo tee % > /dev/null' | :edit!
      command Xclip :execute ':silent w !xclip -selection c'
      if has("multi_byte")
          set encoding=utf-8
          setglobal fileencoding=utf-8
          "setglobal bomb
          set fileencodings=ucs-bom,utf-8,latin1
          if &termencoding == ""
              let &termencoding = &encoding
          endif
      endif
      " switch buffers with \1 \2 \3 \4 \5 \b
      nnoremap <Leader>b :bn<CR>
      nnoremap <Leader>1 :b1<CR>
      nnoremap <Leader>2 :b2<CR>
      nnoremap <Leader>3 :b3<CR>
      nnoremap <Leader>4 :b4<CR>
      nnoremap <Leader>5 :b5<CR>
      " be able to do `di$` delete inner dollar signs
      xnoremap i$ :<C-u> normal! T$vt$<CR>
      onoremap i$ :normal vi$<CR>
      xnoremap a$ :<C-u> normal!F$vf$<CR>
      onoremap a$ :normal va$<CR>
    '';
  };

  # ssh
  systemd.user.tmpfiles.rules = [
    "L+ %h/.ssh/keys/git - - - - %h/secrets/ssh-git"
    "L+ %h/.ssh/keys/git.pub - - - - %h/secrets/ssh-git.pub"
    "L+ %h/.ssh/keys/acekodi - - - - %h/secrets/ssh-acekodi"
    "L+ %h/.ssh/keys/acekodi.pub - - - - %h/secrets/ssh-acekodi.pub"
    "C %h/.ssh/authorized_keys - - - - %h/.ssh/authorized_keys.gen"
  ];
  home.file.".ssh/authorized_keys.gen".text = lib.concatStrings [
    (builtins.readFile "${config.home.homeDirectory}/secrets/ssh-aiclassmate.pub")
    "\n"
    (builtins.readFile "${config.home.homeDirectory}/secrets/ssh-acekodi.pub")
    "\n"
  ];
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "github.com" = {
        user = "git";
        identityFile = "~/.ssh/keys/git";
      };
      "loshad los*" = {
        hostname = "ssh.sausage.house";
        port = 22;
        user = "pavan";
        identityFile = "~/.ssh/keys/acekodi";
      };
      "acekodi ace* ko*" = {
        hostname = "100.77.56.31";
        port = 22;
        user = "pocket";
        identityFile = "~/.ssh/keys/acekodi";
      };
      "kelley-ai-classmate ke*" = {
        hostname = "100.69.251.16";
        port = 22;
        user = "pocket";
        identityFile = "~/.ssh/keys/acekodi";
      };
      "sausalito-ai-classmate sa*" = {
        hostname = "100.83.187.72";
        port = 22;
        user = "pocket";
        identityFile = "~/.ssh/keys/acekodi";
      };
    };
  };

  # git
  programs.git = {
    enable = true;
    settings = {
      user.name = "pocket-98";
      user.email = "dayalpavan@gmail.com";
      init.defaultBranch = "main";
    };
  };

  # pi
  programs.pi-coding-agent = {
    enable = true;
    #rules = ''Be concise.'';
    #skills = [ ./skills/my-skill ];
    settings = {
      defaultProvider = "google";
      #defaultModel = "gemini-3.5-flash";
      defaultModel = "gemma-4-31b-it";
      defaultThinkingLevel = "medium";
    };
    context = ''
      # AGENTS.md
      You are a graduate student writing code to help do complex tasks.
    '';
    models.providers = {
      "custom" = {
        baseUrl = "https://generativelanguage.googleapis.com/v1beta";
        api = "google-generative-ai";
        apiKey = "${builtins.readFile "${config.home.homeDirectory}/secrets/gemini-apikey"}";
        models = [
          {
            id = "gemma-4-31b-it";
            name = "Gemma 4 31B";
            contextWindow = 262144;
            maxOutputTokens = 32768;
            reasoning =  true;
            input =  [ "text" "image" ];
            stream = true;
          }
          {
            id = "gemini-3.5-flash";
            name = "Gemini 3.5 Flash";
            contextWindow = 1048576;
            maxOutputTokens = 65536;
            reasoning =  true;
            input =  [ "text" "image" ];
            stream = true;
          }
        ];
      };
    };
  };

}
