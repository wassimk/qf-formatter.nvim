# Demo GIF

`qf-formatter.gif` is generated from `qf-formatter.tape` with [VHS](https://github.com/charmbracelet/vhs). Regenerate it whenever the plugin's output or the README demo should change.

## Requirements

- [VHS](https://github.com/charmbracelet/vhs#installation) (`brew install vhs`)
- Neovim >= 0.10.0
- A [Nerd Font](https://www.nerdfonts.com/font-downloads) for the icons. The tape tries MonoLisaCode, then Symbols Nerd Font Mono, then JetBrainsMono Nerd Font.
- Network access on the first run, to clone [onedark.nvim](https://github.com/navarasu/onedark.nvim) into `/tmp`

## Regenerate

From the repo root:

```shell
vhs demo/qf-formatter.tape
```

This overwrites `demo/qf-formatter.gif`. Commit it along with any tape changes.

## How it works

- `qf-formatter.tape` scripts the keystrokes. Setup runs hidden, so the GIF starts inside Neovim with the file already open.
- `init.lua` is a minimal config that loads only qf-formatter and onedark, so personal config never shows up in the demo.
- `sample/` is a small Lua project the demo runs in. Its code has real issues (an undefined global, unused locals) that the staged diagnostics point at.
- No language server is needed. `init.lua` stages diagnostics on the sample files, and maps `gO` to fill the location list with `[Kind] name` entries, the same format the LSP client produces for document symbols.
- The statusline is plain because the default one shows diagnostic counts with icons.
- VHS renders in a browser terminal (xterm.js), which draws Nerd Font icons wider than one cell, so they overlap the space after them. `init.lua` adds one extra space after each icon for the recording only. The rest of the plugin's output is unchanged.
- Steps wait on screen text (`Wait+Screen`), so if the plugin's behavior changes the render fails instead of recording a broken demo.
