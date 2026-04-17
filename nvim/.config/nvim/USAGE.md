# Neovim — Usage Guide

Personal cheatsheet for this config. Organised so you can scan it.

Leader is `Space`. `;` works as `:` in normal mode.

---

## 1. Quick reference — leader keys

| Key | Action |
|---|---|
| `<leader>f` | Fuzzy find files |
| `<leader>e` | File browser (Helix-style, single layer) |
| `<leader>p` | Project picker |
| `<leader>g` | Live grep across project |
| `<leader>b` | Buffer picker |
| `<leader>/` | Fuzzy search in current buffer |
| `<leader>sh` / `sk` / `sc` | Help tags / keymaps / commands |
| `<leader>q` | Close current split |
| `<leader>s` | Substitute word under cursor (pre-fills) |
| `<leader>w` | Toggle line wrap |
| `<leader>rn` | LSP rename |
| `<leader>ca` | LSP code action |
| `<leader>1..9` | Jump to buffer by position |

---

## 2. Buffers & tabs

Buffer list shows at the top (lualine tabline). Each open file is a buffer.

| Key | Action |
|---|---|
| `<C-Tab>` | Next buffer |
| `<S-Tab>` | Previous buffer |
| `<C-w>` | Close current buffer (quits nvim if last one) |
| `<leader>1..9` | Jump to Nth buffer |
| `<leader>b` | Fuzzy-find a buffer |

`:bdelete` removes a buffer. `:%bd|e#|bd#` closes all buffers except current.

Splits: `:vsplit` / `:split`, navigate with `<C-w>h/j/k/l`. Resize with `<C-w>=`.

---

## 3. File navigation

### `<leader>f` — fuzzy files
Type fragments of the path. Subsequence match — `uscfg` would find `user_config.lua`.

### `<leader>e` — file browser
Opens current file's directory. `../` goes up. Single-level, Helix-style.
- `<CR>` on a file → open it
- `<CR>` on a dir → enter it
- Inside the browser, keybinds (`i` insert-mode, default telescope):
  - `<C-j>/<C-k>` — move selection
  - `<Esc>` — close

### `<leader>p` — projects
Manually curated list. Commands (in command mode):
- `:ProjectAdd` — add cwd
- `:ProjectAdd ~/.config/hypr` — add explicit path
- `:ProjectRemove` — picker to remove
- `:ProjectList` — list all

Switching a project: `%bd!`s open buffers, `cd`s to the project, opens an empty buffer.

### Grep & search
- `<leader>g` — project-wide live grep (requires `ripgrep`)
- `<leader>/` — fuzzy search in current buffer
- `/pattern` — native search. `n` next, `N` previous (both center the result on screen)

---

## 4. Completion (blink.cmp) — VS2026-style

| Key | Action |
|---|---|
| Type normally | Menu appears but **nothing is selected or inserted** |
| `<Tab>` | Accept the hovered suggestion |
| `<Up>` / `<Down>` | Navigate suggestions |
| `<CR>` | **Newline only** — never accepts |
| `<C-Space>` | Manually open menu |
| `<C-k>` | Show / hide documentation popup |
| `<C-e>` | Dismiss menu |

Fuzzy matching is subsequence-based. Typing `km.seti` can match `km.IsKeySet()` even though "seti" isn't a literal substring — blink scores characters present in order.

---

## 5. LSP

Installed servers: `lua_ls`, `clangd`. Add more by editing `servers = {}` in `lua/plugins/lsp.lua` — Mason auto-installs them.

| Key | Action |
|---|---|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | List references |
| `gi` | Go to implementation |
| `K` | Hover docs |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `[d` / `]d` | Prev / next diagnostic |

Diagnostics show in the signcolumn and as virtual text. `:Mason` opens the LSP/tool installer UI.

---

## 6. Treesitter scope motions — the big one

You don't select with Shift+arrows. You compose a **verb** with a **text object**.

Text objects come from **mini.ai** (treesitter-powered).

### Text objects (compose with any verb)

| Inside | Around | What |
|---|---|---|
| `if` | `af` | Function |
| `ic` | `ac` | Class |
| `ia` | `aa` | Argument |
| `il` | `al` | Loop body |
| `ii` | `ai` | Conditional (if/else) |

### Verbs

| Verb | Effect |
|---|---|
| `y` | Yank (copy) |
| `d` | Delete (goes to black-hole — no clipboard clobber) |
| `c` | Change (delete + insert) |
| `v` | Visual select |
| `gc` | Toggle comment |

### Recipes

```
yaf     copy entire function
daf     delete entire function
gcaf    comment out entire function
vaf     select function (then do whatever)
cif     delete function body, enter insert
gcic    comment out class body
dai     delete an if/else block
yaa     copy an argument
```

Works identically for Lua (`function ... end`), C++ (`{...}`), Python, Rust — treesitter handles the language.

### Bracketed navigation (mini.bracketed)

| Key | Jump |
|---|---|
| `]t` / `[t` | Next / prev treesitter node |
| `]d` / `[d` | Next / prev diagnostic |
| `]q` / `[q` | Next / prev quickfix entry |
| `]b` / `[b` | Next / prev buffer |
| `]i` / `[i` | Next / prev indent block |
| `]j` / `[j` | Forward / back in jumplist |
| `]o` / `[o` | Next / prev in oldfiles |

Language-specific: most filetypes ship `]m` / `[m` (next/prev method start) via built-in ftplugins — works for C++ out of the box.

---

## 7. Surround (nvim-surround) — change brackets/quotes without retyping

### Add surround
```
ysiw"           foo       → "foo"
ysiw)           foo       → (foo)
ys$)            foo bar   → (foo bar)      (to end of line)
yss"            hello     → "hello"         (whole line)
```

### Change surround
```
cs"'           "foo"      → 'foo'
cs")           "foo"      → (foo)
cs]{           [foo]      → { foo }
```

### Delete surround
```
ds"            "foo"      → foo
ds)            (foo bar)  → foo bar
```

### VS-style visual wrap (added in this config)
Visual-select any text, then press `"` `'` `` ` `` `(` `[` `{` — it wraps.

```
v + e + "                selects a word, then wraps: foo → "foo"
V + j + )                selects 2 lines, wraps them in parens
```

---

## 8. Flash motion — jump anywhere in 2 keystrokes

`s` in normal mode opens Flash. Type the 2 chars of your target. Labels appear on matches — hit the label.

```
Before:           After pressing `swo` (w,o + label 'b'):
-------          -------
function       function
  local word     local [b]ord
  other.world    other.world
  return woot    return woot
```

- `s<ab>` — jump to the first 2-char match
- `s<ab><label>` — jump to the labelled match
- `S` — treesitter-scope flash (jumps to nodes, not chars)

Replaces long-range `w`/`b`/`e`/`f`/`t` motions for most cases. Still useful for same-line micro-moves.

---

## 9. Editing tricks (mapped)

| Key | Action |
|---|---|
| `<A-j>` / `<A-k>` | Move line (or selection) down / up |
| `<C-d>` / `<C-u>` | Half-page scroll, stays centered |
| `n` / `N` | Next / prev search match, stays centered |
| `J` | Join lines, cursor stays in place |
| `<` / `>` in visual | Indent, stays in visual (repeat with `>>>`) |
| `p` in visual | Paste without clobbering register |
| `;` | Enters command mode (same as `:`) |
| `F19` | Escape (CapsLock → F19 via keyd, then F19 → Esc here) |
| `<C-s>` | Save (works in n/i) |
| `<C-BS>` | Delete word backward (insert mode) |
| `<C-c>` in visual | Copy to system clipboard |
| `<Esc>` | Clear search highlight |

---

## 10. Native motions you should drill

Everything below is built into Vim. No plugin. Learn one a day for a month.

### Word & line motion

| Key | |
|---|---|
| `w` / `b` | Next / prev word start |
| `e` / `ge` | Next / prev word end |
| `0` / `^` | Start of line / first non-whitespace |
| `$` | End of line |
| `f<c>` / `F<c>` | Jump to next / prev char `<c>` on the line |
| `t<c>` / `T<c>` | Jump **before** next / prev char `<c>` |
| `%` | Jump to matching bracket or `function`/`end` (matchit) |

### File-wide motion

| Key | |
|---|---|
| `gg` / `G` | First / last line |
| `{` / `}` | Prev / next blank line (paragraph) |
| `<C-o>` / `<C-i>` | Jump **back** / **forward** in jumplist (cross-file, cross-project) |
| `<C-]>` / `<C-t>` | Jump to tag / return from tag |
| `*` / `#` | Search word under cursor forward / backward |
| `gd` | Go to local definition (LSP) |

### Text objects (combine with `d`/`y`/`c`/`v`/`gc`)

| Object | What |
|---|---|
| `iw` / `aw` | Word |
| `is` / `as` | Sentence |
| `ip` / `ap` | Paragraph |
| `i"` / `a"` | Inside / around double quotes |
| `i'` / `a'` | Single quotes |
| `` i` `` / `` a` `` | Backticks |
| `i(` / `a(` | Parens (also `ib`) |
| `i{` / `a{` | Braces (also `iB`) |
| `i[` / `a[` | Brackets |
| `i<` / `a<` | Angle brackets |
| `it` / `at` | XML/HTML tag |
| Plus all the treesitter ones: `if`, `ic`, `ia`, `il`, `ii` |

### Changes & history

| Key | |
|---|---|
| `u` / `<C-r>` | Undo / redo |
| `.` | **Repeat last change** — arguably the most powerful key in Vim |
| `gv` | Re-select last visual selection |
| `ma` … `'a` | Set mark `a` on line, jump back to it. Capital marks (`mA`) cross files |

### Registers & macros

| Key | |
|---|---|
| `"ayy` | Yank line into register `a` |
| `"ap` | Paste from register `a` |
| `qa` … `q` | Start recording macro into register `a`, stop |
| `@a` | Replay macro `a`. `5@a` replays 5 times |
| `@@` | Replay last macro |
| `"+y` / `"+p` | System clipboard yank / paste (also via `clipboard=unnamedplus`) |

### Block mode (VS column-select equivalent)

`<C-v>` enters visual block mode.

```
Goal: add `//` in front of 5 lines
<C-v>      enter block mode
5j         select 5 lines down
I// <Esc>  insert on every line

Goal: delete column 10-15 on 3 lines
<C-v>      block mode
2j         go down 2 lines
9l         across to col 10... (or use `f` / `t`)
5l         across to col 15
d          delete the rectangle
```

### Built-in goodies

| Key | |
|---|---|
| `q:` | Command history as editable buffer. Edit + `<CR>` to run. |
| `q/` | Search history as editable buffer |
| `<C-r>=` in insert | Insert result of an expression — `<C-r>=2+2<CR>` inserts `4` |
| `<C-r>+` in insert | Insert system clipboard (same as `"+p` but in insert mode) |
| `<C-r>%` in insert / cmdline | Insert current filename |
| `gf` | Open file path under cursor |
| `:term` | Terminal in a buffer. `<C-\><C-n>` exits terminal mode |
| `:Inspect` / `:InspectTree` | Native treesitter/highlight debug |

### Substitute tricks

```vim
:%s/foo/bar/g              Replace all "foo" with "bar"
:%s/\<foo\>/bar/gI         Word-boundary + case-insensitive
:'<,'>s/foo/bar/g          In visual selection only
:s//new/g                  Replace last-searched pattern (empty first field = reuse)
```

With the `<leader>s` mapping, your cursor word is prefilled for replacement — just type the new text.

### Quickfix workflow (for refactors)

```
gr                         LSP: all references (goes into quickfix-like list)
:copen                     Open quickfix window
:cdo s/old/new/g | update  Run substitute on every match, save each file
```

This is how you rename across a whole codebase without LSP rename (rare fallback).

---

## 11. Commands added by this config

| Command | Effect |
|---|---|
| `:ProjectAdd [path]` | Add directory to project list (default: cwd) |
| `:ProjectRemove [path]` | Remove from project list (picker if no arg) |
| `:ProjectList` | Print list |
| `:Mason` | Open LSP/tool installer |
| `:Lazy` | Open plugin manager UI |
| `:ConformInfo` | Formatter status for current buffer |

### Typo-fixing command abbreviations

`:W`, `:Q`, `:Wq`, `:WQ`, and `:wq` all work as if you'd typed the lowercase version. `:q` force-quits (no "unsaved changes" nag — your call).

---

## 11b. Auto-pairs & auto-end

**`nvim-autopairs`** inserts matching close brackets/quotes as you type, AND skips past an existing close if you type it.

```
type: foo(               →  foo(|)          (autopairs added `)`)
type: bar                →  foo(bar|)
type: )                  →  foo(bar)|       (skips existing `)`, no duplicate)
```

No need to leave insert mode to step past a close bracket — just type the close character and it jumps.

**`nvim-treesitter-endwise`** auto-inserts `end` in Lua / Ruby / bash when you hit `<CR>` after `function` / `if` / `for` / `while` / `do`.

```
type: local function test()<CR>
                         →  local function test()
                                |
                            end
```

Combined workflow:

```
type: local function test(   →   local function test(|)
type: name, count            →   local function test(name, count|)
type: )<CR>                  →   local function test(name, count)
                                     |        ← cursor here, indented
                                 end
```

---

## 12. Format on save (Lua)

- `stylua` must be on your PATH
- Config at `~/.config/stylua/stylua.toml` (160-col line width, `collapse_simple_statement = "FunctionOnly"` — keeps one-statement callbacks on a single line)
- Save triggers it automatically
- C++ formatting: clangd handles it on save via LSP

To disable temporarily: `:FormatDisable` … actually, there's no such command added. Just comment out the `format_on_save = {...}` block in `lua/plugins/format.lua` if you need it off.

---

## 13. Tradeoffs you've opted into (worth knowing)

- **`s` is now Flash.** Native `s` (substitute character — equivalent to `cl`) is gone. You can still do `cl` explicitly, or `xi`.
- **`;` is now `:`.** Native `;` (repeat last f/F/t/T forward) is gone. Use `,` for reverse-repeat, or re-remap.
- **`d` uses black-hole register.** Deleted text doesn't go to your clipboard. If you ever need it to, use `"+d` or `"ad` etc.
- **Mouse scroll is inverted** and clicks do nothing — trackpad feels natural, no accidental cursor jumps.
- **No swap / backup / undofile.** If you crash mid-edit, unsaved changes are gone. `:q` doesn't prompt — it force-quits.

---

## 14. File layout of the config

```
init.lua                         leader + module loads
lua/config/options.lua           vim options (indent, search, UI, mouse)
lua/config/keymaps.lua           all custom keymaps
lua/config/lazy.lua              lazy.nvim bootstrap + UI muting
lua/plugins/colorscheme.lua      onedark
lua/plugins/treesitter.lua       + textobjects (scope motions)
lua/plugins/lsp.lua              mason + vim.lsp.config (add servers here)
lua/plugins/completion.lua       blink.cmp
lua/plugins/telescope.lua        find files / file browser / pickers
lua/plugins/statusline.lua       lualine + tabline + gitsigns + which-key + indent-blankline
lua/plugins/motion.lua           flash + nvim-surround
lua/plugins/format.lua           conform.nvim (stylua on save)
lua/projects.lua                 custom projects module
```

To **add an LSP server**: add a key to the `servers` table in `lua/plugins/lsp.lua`. Mason installs + enables.

To **add a plugin**: drop a new file in `lua/plugins/` returning a lazy spec. That's it.
