# dotfiles

## Setup

Each tool can be installed independently via `curl | bash`:

### Homebrew packages

```bash
curl -fsSL https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main/brew/setup.bash | bash
```

### Alacritty

```bash
curl -fsSL https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main/alacritty/setup.bash | bash
```

### Kitty

```bash
curl -fsSL https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main/kitty/setup.bash | bash
```

### JetBrainsMono Nerd Font

Installed or upgraded to the latest release by the kitty and alacritty setups;
it can also be run on its own.

```bash
curl -fsSL https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main/fonts/nerd-font.bash | bash
```

### STIX Two Math (Linux)

Fallback font for symbols JetBrains Mono lacks (e.g. Claude Code's `⏵`). macOS
ships the same file; the kitty and alacritty setups install it on Linux.

```bash
curl -fsSL https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main/fonts/stix-math.bash | bash
```

### Kitty terminfo

Installs the `xterm-kitty` terminfo entry so `clear`, `tput` and curses apps work
over SSH. Run it on the **remote host**, not the kitty client.

```bash
curl -fsSL https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main/kitty/terminfo.bash | bash
```

### Neovim

```bash
curl -fsSL https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main/nvim/setup.bash | bash
```

### tmux

```bash
curl -fsSL https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main/tmux/setup.bash | bash
```

### lazygit

```bash
curl -fsSL https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main/lazygit/setup.bash | bash
```

### lazydocker

```bash
curl -fsSL https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main/lazydocker/setup.bash | bash
```

### ranger

```bash
curl -fsSL https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main/ranger/setup.bash | bash
```

### zsh aliases

```bash
curl -fsSL https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main/zsh/setup.bash | bash
```

### bash aliases

```bash
curl -fsSL https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main/bash/setup.bash | bash
```

### yazi

```bash
curl -fsSL https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main/yazi/setup.bash | bash
```

### Raycast (macOS only)

```bash
curl -fsSL https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main/raycast/setup.bash | bash
```
