# Auto-attach to (or create) the "main" tmux session on every interactive login.
# `exec` replaces the fish process with tmux — detaching closes the terminal window.
if uwsm check may-start
  exec uwsm start hyprland.desktop
end
zoxide init fish | source

# overwrite greeting
# potentially disabling fastfetch
function fish_greeting
    fastfetch
end

alias ls='eza -al --color=always --group-directories-first --icons' # preferred listing
alias la='eza -a --color=always --group-directories-first --icons' # all files and dirs
alias ll='eza -l --color=always --group-directories-first --icons' # long format
alias lt='eza -aT --color=always --group-directories-first --icons' # tree listing
alias l.="eza -a | grep -e '^\.'" # show only dotfiles

# Common use
alias grubup="sudo grub-mkconfig -o /boot/grub/grub.cfg"
alias fixpacman="sudo rm /var/lib/pacman/db.lck"
alias tarnow='tar -acf '
alias untar='tar -zxvf '
alias wget='wget -c '
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias hw='hwinfo --short' # Hardware Info
alias big="expac -H M '%m\t%n' | sort -h | nl" # Sort installed packages according to size in MB
alias gitpkg='pacman -Q | grep -i "\-git" | wc -l' # List amount of -git packages
alias update='sudo pacman -Syu'


# Help people new to Arch
alias apt='man pacman'
alias apt-get='man pacman'
alias please='sudo'
alias tb='nc termbin.com 9999'

# Cleanup orphaned packages
alias cleanup='sudo pacman -Rns (pacman -Qtdq)'

# Get the error messages from journalctl
alias jctl="journalctl -p 3 -xb"

# Recent installed packages
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"

alias cls=clear
alias co='codium 0.'

bind \co 'nvim .; commandline -f repaint'
bind \ce 'thunar . >/dev/null 2>&1 &; disown; commandline -f repaint'
bind \CO 'sudo -E nvim .; commandline -f repaint'



# History
set -U fish_history 10000

#Greeting
set fish_greeting

# Zoxide

set -Ux EDITOR nvim
set -Ua fish_user_paths ~/.local/bin ~/dotfiles/bin

# Editor
# Aliases
abbr -a vim nvim
abbr -a cd z
abbr -a spS "sudo pacman -S"
abbr -a spSs "sudo pacman -Ss"
abbr -a pS "paru -S"
abbr -a pSs "paru -Ss"
abbr -a hconf "$EDITOR $HOME/.config/hypr/hyprland.conf"
abbr -a mfish "$EDITOR $HOME/.config/fish/config.fish"
abbr -a rfish "source $HOME/.config/fish/config.fish"
