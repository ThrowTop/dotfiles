# Neovim — Usage Guide

Personal cheatsheet for this config. Organised so you can scan it.

Leader is `Space`. `;` works as `:` in normal mode.

---

## 1. Quick reference — leader keys

| Key | Action |
|---|---|
| `<leader>f` | Fuzzy find files |
| `<leader>e` | File browser (telescope, Helix-style single layer) |
| `<leader>E` | mini.files popup (edit filesystem as text) |
| `<leader>p` | Project picker (auto-opens file picker on switch) |
| `<leader>g` | Live grep across project |
| `<leader>b` | Buffer picker |
| `<leader>/` | Fuzzy search in current buffer |
| `<leader>sh` / `sk` / `sc` | Help tags / keymaps / commands |
| `<leader>s` | Substitute word under cursor (pre-fills) |
| `<leader>t` | Toggle bool / keyword under cursor |
| `<leader>w` | Toggle line wrap |
| `<leader>d` | Show line diagnostics (float) |
| `<leader>rn` | LSP rename |
| `<leader>ca` | LSP code action |
| `<leader>xx` / `xb` / `xs` / `xr` / `xq` | Trouble: all diag / buffer diag / symbols / LSP refs / quickfix |
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

No splits in this workflow — `<C-w>` is rebound to close-buffer. If you ever want a split, `:vsplit` / `:split` still work via command line.

---

## 3. File navigation

### `<leader>f` — fuzzy files
Type fragments of the path. Subsequence match — `uscfg` would find `user_config.lua`.

### `<leader>e` — file browser
Opens current file's directory. `../` goes up. Single-level, Helix-style.
- `<CR>` on a file → open it
- `<CR>` on a dir → enter it
- Inside the browser (insert mode, default telescope):
  - `<C-j>` / `<C-k>` — move selection
  - `<Esc>` — close

### `<leader>E` — mini.files (filesystem-as-text)
Opens a floating column showing the current directory. Navigate with `j/k` and `<CR>` (into folder) / `h` / `-` (back up). **Edit the buffer to change the filesystem:**

| Text action | Filesystem result |
|---|---|
| `dd` a line | Delete that file/folder |
| Edit the name on a line | Rename |
| Yank a line, paste in another column | Copy across directories |
| Type a new line ending in `/` | Create folder |
| Type a new line without `/` | Create file |

Nothing applies until you press `=` — you get a diff + confirm. `q` aborts.

### `<leader>p` — projects
Manually curated list. Commands (in command mode):
- `:ProjectAdd` — add cwd
- `:ProjectAdd ~/.config/hypr` — add explicit path
- `:ProjectRemove` — picker to remove
- `:ProjectList` — list all

Switching a project: closes all open buffers, `cd`s into the project, then auto-launches `<leader>f` (find files) in the new directory.

### Grep & search
- `<leader>g` — project-wide live grep (requires `ripgrep`)
- `<leader>/` — fuzzy search in current buffer
- `/pattern` — native search. `n` next, `N` previous (both center the result)

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

Fuzzy matching is subsequence-based. Typing `km.seti` can match `km.IsKeySet()` even though "seti" isn't a literal substring.

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
| `<leader>d` | Show full diagnostic float for current line |
| `[d` / `]d` | Prev / next diagnostic |

Diagnostics show with `●` prefix in virtual text, severity-sorted, rounded float borders, and the source (which LSP/linter produced it) visible. `:Mason` opens the LSP/tool installer UI.

---

## 6. Diagnostics & Trouble

Built-in diagnostics behavior is already upgraded (see §5). For bulk navigation of errors across the project, use **Trouble**:

| Key | Action |
|---|---|
| `<leader>xx` | All diagnostics (project) |
| `<leader>xb` | Current buffer diagnostics only |
| `<leader>xs` | Document symbols (outline) |
| `<leader>xr` | LSP references / definitions pane |
| `<leader>xq` | Quickfix list |

Trouble opens a bottom pane with all entries — jump between them with `j/k`, `<CR>` opens the location. Same `<leader>x*` key toggles it closed.

For single-hop diagnostic movement, stick with `]d` / `[d`.

---

## 7. Scope & structural motions — the big one

You don't select with Shift+arrows. You compose a **verb** with a **text object**.

### Custom text objects (mini.ai, treesitter-powered)

| Inside | Around | What |
|---|---|---|
| `if` | `af` | Function |
| `ia` | `aa` | Argument / parameter |

### Indent scope (mini.indentscope)

| Inside | Around | What |
|---|---|---|
| `ii` | `ai` | Current indent scope (matches the gray scope line on-screen) |

`ii` / `ai` is the language-agnostic "whatever block I'm in" — covers `if`, `for`, `while`, `{}`, Python `:` blocks, anything that indents. This is typically what you want when your cursor is inside a conditional or loop. Matches the visible scope indicator 1:1.

The highlighted gray vertical line shows your current scope. `vai` selects exactly that.

### Verbs (compose with any text object)

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
vaf     select function
cif     delete function body, enter insert
yai     copy the current scope (if/for/block/whatever)
dai     delete the current scope
vii     visual-select inside the current scope
yaa     copy an argument
daa     delete an argument (handles trailing comma)
```

Works identically for Lua (`function ... end`), C++ (`{...}`), Python, Rust — treesitter and indent detection are language-agnostic.

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

## 8. Surround (nvim-surround) — change brackets/quotes without retyping

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

### VS-style visual wrap
Visual-select any text, then press `"` `'` `` ` `` `(` `[` `{` — it wraps.

```
v + e + "                selects a word, then wraps: foo → "foo"
V + j + )                selects 2 lines, wraps them in parens
```

---

## 9. Flash motion — jump anywhere in 2 keystrokes

`s` in normal/visual/operator mode opens Flash. Type the 2 chars of your target. Labels appear on matches — hit the label.

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

Replaces long-range `w`/`b`/`e`/`f`/`t` motions for most cases. (Treesitter-jump `S` was removed — conflicted with visual-mode surround.)

---

## 10. Toggle / swap under cursor

`<leader>t` cycles a pairs table based on the word under the cursor. Case-preserving: `True` → `False`, `TRUE` → `FALSE`, `true` → `false`.

Default pairs: `true/false`, `and/or`, `yes/no`, `on/off`.

Add more pairs in `lua/config/keymaps.lua` → `toggle_pairs` table. A single `{ "lhs", "rhs" }` entry covers both directions and all three casings automatically.

Adjacent built-ins:
- `<C-a>` / `<C-x>` — increment / decrement number under cursor
- `~` — toggle case of current char
- `g~iw` / `guiw` / `gUiw` — toggle / lower / upper case of word

---

## 11. Editing tricks (mapped)

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

Yanked text **flashes for 150ms** so you can see what was grabbed — useful for motions like `y3j` or `yi{`.

---

## 12. UI niceties (passive)

These work without any keypress — just by existing:

- **Scope line** — gray `│` showing your current indent scope (matches `vai`)
- **Indent guides** — `│` at each indent level (non-scope ones dimmer)
- **`cursorlineopt = "number"`** — only the current line *number* is highlighted, not the whole row background. Less visual noise.
- **Yank highlight** — see above.
- **Diagnostic virtual text** — `● message` beside the problematic line
- **telescope-ui-select** — every `vim.ui.select` prompt (code actions, `:ProjectRemove`, LSP stash pickers, any plugin that uses the generic picker API) is rendered as a telescope dropdown with fuzzy search

---

## 13. Native motions you should drill

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
| `,` | Repeat last `f`/`t` in reverse |
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
| `gf` | Open file path under cursor |

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
| `if` / `af` | Function (treesitter) |
| `ia` / `aa` | Argument (treesitter) |
| `ii` / `ai` | Indent scope |

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
| `q:` | Command history as editable buffer. Edit + `<CR>` to run |
| `q/` | Search history as editable buffer |
| `<C-r>=` in insert | Insert result of an expression — `<C-r>=2+2<CR>` inserts `4` |
| `<C-r>+` in insert | Insert system clipboard (same as `"+p` but in insert mode) |
| `<C-r>%` in insert / cmdline | Insert current filename |
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

## 14. Commands added by this config

| Command | Effect |
|---|---|
| `:ProjectAdd [path]` | Add directory to project list (default: cwd) |
| `:ProjectRemove [path]` | Remove from project list (picker if no arg) |
| `:ProjectList` | Print list |
| `:Mason` | Open LSP/tool installer |
| `:Lazy` | Open plugin manager UI |
| `:ConformInfo` | Formatter status for current buffer |
| `:Trouble <mode> toggle` | Toggle the Trouble pane (diagnostics, symbols, etc.) |

### Typo-fixing command abbreviations

`:W`, `:Q`, `:Wq`, `:WQ`, and `:wq` all work as if you'd typed the lowercase version. `:q` force-quits (no "unsaved changes" nag — your call).

---

## 15. Auto-pairs & auto-end

**`nvim-autopairs`** inserts matching close brackets/quotes as you type, AND skips past an existing close if you type it.

```
type: foo(               →  foo(|)          (autopairs added `)`)
type: bar                →  foo(bar|)
type: )                  →  foo(bar)|       (skips existing `)`, no duplicate)
```

**`nvim-treesitter-endwise`** auto-inserts `end` in Lua / Ruby / bash when you hit `<CR>` after `function` / `if` / `for` / `while` / `do`.

```
type: local function test()<CR>
                         →  local function test()
                                |
                            end
```

Combined:

```
type: local function test(   →   local function test(|)
type: name, count            →   local function test(name, count|)
type: )<CR>                  →   local function test(name, count)
                                     |        ← cursor here, indented
                                 end
```

---

## 16. Format on save (Lua)

- `stylua` must be on your PATH
- Config at `~/.config/stylua/stylua.toml` (160-col line width, `collapse_simple_statement = "FunctionOnly"`)
- Save triggers it automatically
- C++ formatting: clangd handles it on save via LSP

To disable temporarily: comment out the `format_on_save = {...}` block in `lua/plugins/format.lua`.

---

## 17. Tradeoffs you've opted into (worth knowing)

- **`s` is now Flash.** Native `s` (substitute character — equivalent to `cl`) is gone. You can still do `cl` explicitly, or `xi`.
- **`;` is now `:`.** Native `;` (repeat last f/F/t/T forward) is gone. Use `,` for reverse-repeat, or re-remap.
- **`d` uses black-hole register.** Deleted text doesn't go to your clipboard. If you ever need it to, use `"+d` or `"ad` etc.
- **`<C-w>` closes the buffer**, not window-prefix. You don't use splits, so no loss. Insert-mode `<C-w>` (delete word back) still works.
- **Mouse scroll is inverted** and clicks do nothing — trackpad feels natural, no accidental cursor jumps.
- **No swap / backup / undofile.** If you crash mid-edit, unsaved changes are gone. `:q` doesn't prompt — it force-quits. Undo does not persist across sessions.

---

## 18. File layout of the config

```
init.lua                         leader + module loads
lua/config/options.lua           vim options, diagnostic config, yank-highlight autocmd
lua/config/keymaps.lua           all custom keymaps + toggle-bool function
lua/config/lazy.lua              lazy.nvim bootstrap + UI muting
lua/plugins/colorscheme.lua      onedark
lua/plugins/treesitter.lua       treesitter + textobjects queries + endwise
lua/plugins/lsp.lua              mason + vim.lsp.config
lua/plugins/completion.lua       blink.cmp
lua/plugins/telescope.lua        find files / file browser / pickers / ui-select
lua/plugins/statusline.lua       lualine + tabline + gitsigns + which-key + indent guides
lua/plugins/motion.lua           flash + mini.ai + mini.indentscope + mini.bracketed + surround + autopairs
lua/plugins/ui.lua               trouble + mini.files
lua/plugins/format.lua           conform.nvim (stylua on save)
lua/projects.lua                 custom projects module
```

To **add an LSP server**: add a key to the `servers` table in `lua/plugins/lsp.lua`. Mason installs + enables.

To **add a plugin**: drop a new file in `lua/plugins/` returning a lazy spec. That's it.

To **add a toggle pair**: append `{ "foo", "bar" }` to `toggle_pairs` in `lua/config/keymaps.lua`. Case-preserving, bidirectional.
