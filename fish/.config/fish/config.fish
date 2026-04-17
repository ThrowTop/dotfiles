# ── Environment ─────────────────────────────────────────────────
set -gx EDITOR nvim
fish_add_path ~/.local/bin ~/dotfiles/bin

# ── Greeting ────────────────────────────────────────────────────
function fish_greeting
    fastfetch
end

# ── Zoxide ──────────────────────────────────────────────────────
zoxide init fish | source

# ── Abbreviations ───────────────────────────────────────────────
# Editors / renames
abbr -a vim nvim
abbr -a cd z
abbr -a hx helix
abbr -a cls clear
abbr -a co 'codium .'
abbr -a please sudo
abbr -a apt 'man pacman'
abbr -a apt-get 'man pacman'
abbr -a tb 'nc termbin.com 9999'

# Navigation
abbr -a ..     'cd ..'
abbr -a ...    'cd ../..'
abbr -a ....   'cd ../../..'
abbr -a .....  'cd ../../../..'
abbr -a ...... 'cd ../../../../..'

# Pacman / paru
abbr -a spS       'sudo pacman -S'
abbr -a spSs      'sudo pacman -Ss'
abbr -a pS        'paru -S'
abbr -a pSs       'paru -Ss'
abbr -a update    'sudo pacman -Syu'
abbr -a cleanup   'sudo pacman -Rns (pacman -Qtdq)'
abbr -a fixpacman 'sudo rm /var/lib/pacman/db.lck'
abbr -a gitpkg    'pacman -Q | grep -i "\-git" | wc -l'
abbr -a big       "expac -H M '%m\t%n' | sort -h | nl"
abbr -a rip       "expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"

# System / inspection
abbr -a jctl    'journalctl -p 3 -xb'
abbr -a hw      'hwinfo --short'
abbr -a grubup  'sudo grub-mkconfig -o /boot/grub/grub.cfg'
abbr -a psmem   'ps auxf | sort -nr -k 4'
abbr -a psmem10 'ps auxf | sort -nr -k 4 | head -10'

# Archive helpers
abbr -a tarnow 'tar -acf'
abbr -a untar  'tar -zxvf'
abbr -a wget   'wget -c'

# Git
abbr -a gfu 'git fetch; and git reset --hard @{u}'

# Config edit
abbr -a hconf "$EDITOR $HOME/.config/hypr/hyprland.conf"
abbr -a mfish "$EDITOR $HOME/.config/fish/config.fish"
abbr -a rfish 'source $HOME/.config/fish/config.fish'

# ── Aliases (flag-bundled; frequent use → keep expansion hidden) ─
alias ls 'eza -al --color=always --group-directories-first --icons'
alias la 'eza -a  --color=always --group-directories-first --icons'
alias ll 'eza -l  --color=always --group-directories-first --icons'
alias lt 'eza -aT --color=always --group-directories-first --icons'
alias l. "eza -a | grep -e '^\.'"

alias grep  'grep --color=auto'
alias fgrep 'fgrep --color=auto'
alias egrep 'egrep --color=auto'
alias dir   'dir --color=auto'
alias vdir  'vdir --color=auto'

# ── Functions ───────────────────────────────────────────────────
function marktext
    command marktext $argv >/dev/null 2>&1 &
    disown
end

# ── Key bindings ────────────────────────────────────────────────
bind \co 'nvim .; commandline -f repaint'
bind \ce 'thunar . >/dev/null 2>&1 &; disown; commandline -f repaint'
bind \CO 'sudo -E nvim .; commandline -f repaint'
bind \ct 'tmux new-session -A -s main; commandline -f repaint'
