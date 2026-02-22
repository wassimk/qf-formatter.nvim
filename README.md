# qf-formatter.nvim

Beautiful quickfix and location list formatting with diagnostic and LSP kind icons.

<!-- TODO: add screenshot/GIF demo -->

## 📋 Requirements

- **Neovim 0.10+**
- **[Nerd Font](https://www.nerdfonts.com/)** for icon rendering

## 🛠️ Installation

Install via your preferred plugin manager. The following example uses [lazy.nvim](https://github.com/folke/lazy.nvim).

```lua
{
  'wassimk/qf-formatter.nvim',
  event = 'VeryLazy',
  opts = {}
}
```

## 💻 Features

- Formatted quickfix and location list entries: `filename │line:col│ [icon] text`
- Truncates long filenames with ellipsis
- Replaces `$HOME` with `~` in file paths
- Diagnostic icons for error, warning, info, and hint entries
- LSP kind icons (codicons) for document symbol entries
- Syntax highlighting for filenames, separators, line numbers, diagnostics, and LSP kinds

## 🔧 Configuration

The `setup()` function accepts an options table. All values are optional.

```lua
require('qf-formatter').setup({
  filename_width = 32, -- max filename column width (default: 32)
})
```

### Highlight Groups

The plugin defines highlight groups that you can customize in your colorscheme or config.

**Quickfix structure:**

| Group | Default Link | Description |
|-------|-------------|-------------|
| `Directory` | — | Filename column |
| `Delimiter` | — | `│` separators |
| `LineNr` | — | Line and column numbers |

**Diagnostic icons:**

| Group | Description |
|-------|-------------|
| `DiagnosticSignError` | Error icon |
| `DiagnosticSignWarn` | Warning icon |
| `DiagnosticSignInfo` | Info icon |
| `DiagnosticSignHint` | Hint icon |

**LSP kind icons** use the `QfFormatterKind{Name}` pattern with sensible defaults:

| Group | Default Link |
|-------|-------------|
| `QfFormatterKindClass` | `Type` |
| `QfFormatterKindConstant` | `Constant` |
| `QfFormatterKindConstructor` | `Function` |
| `QfFormatterKindEnum` | `Type` |
| `QfFormatterKindEnumMember` | `Constant` |
| `QfFormatterKindEvent` | `Special` |
| `QfFormatterKindField` | `Identifier` |
| `QfFormatterKindFile` | `Directory` |
| `QfFormatterKindFolder` | `Directory` |
| `QfFormatterKindFunction` | `Function` |
| `QfFormatterKindInterface` | `Type` |
| `QfFormatterKindKeyword` | `Keyword` |
| `QfFormatterKindMethod` | `Function` |
| `QfFormatterKindModule` | `Include` |
| `QfFormatterKindOperator` | `Operator` |
| `QfFormatterKindProperty` | `Identifier` |
| `QfFormatterKindReference` | `Identifier` |
| `QfFormatterKindSnippet` | `Special` |
| `QfFormatterKindStruct` | `Type` |
| `QfFormatterKindText` | `String` |
| `QfFormatterKindTypeParameter` | `Type` |
| `QfFormatterKindUnit` | `Number` |
| `QfFormatterKindValue` | `Number` |
| `QfFormatterKindVariable` | `Identifier` |
| `QfFormatterKindColor` | `Special` |

All `QfFormatterKind*` groups are defined with `default = true`, so any highlight set by your colorscheme takes priority. To customize a kind, override the group in your config:

```lua
vim.api.nvim_set_hl(0, 'QfFormatterKindMethod', { fg = '#82aaff' })
```

## 🔧 Development

Run tests and lint:

```shell
make test
make lint
```

Enable the local git hooks (one-time setup):

```shell
git config core.hooksPath .githooks
```

This activates a pre-commit hook that auto-generates `doc/qf-formatter.nvim.txt` from `README.md` whenever the README is staged. Requires [pandoc](https://pandoc.org/installing.html).
