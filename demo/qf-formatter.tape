# README demo for qf-formatter.nvim
#
# Render from the repo root:
#   vhs demo/qf-formatter.tape

Output demo/qf-formatter.gif

Require nvim
Require git
Require bash

Set Shell "bash"
Set FontFamily "MonoLisaCode, Symbols Nerd Font Mono, JetBrainsMono Nerd Font"
Set FontSize 15
Set Width 1000
Set Height 600
Set Padding 16
Set Theme "OneHalfDark"
Set TypingSpeed 80ms
Set CursorBlink false

# Setup: open the sample project in nvim with the minimal config
Hide
Type "cd demo/sample && nvim -u ../init.lua lua/todo/init.lua"
Enter
Wait+Screen /local M = \{\}/
Sleep 500ms
Show

Sleep 1s

# Diagnostics in the quickfix list
Type ":lua vim.diagnostic.setqflist()"
Sleep 400ms
Enter
Wait+Screen /Undefined global/
Sleep 2s

Down@500ms 1
Sleep 400ms
Enter
Sleep 1.5s

Type ":cclose"
Sleep 300ms
Enter
Sleep 800ms

# Document symbols in the location list
Type "gO"
Wait+Screen /Document Symbols/
Sleep 2s

Down@500ms 5
Sleep 400ms
Enter

# Hold on the result before looping
Sleep 3s
