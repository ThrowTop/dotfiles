function __nvim_cwd_hook --on-event fish_postexec
    string match -qr '^(nvim|vim)\b' -- $argv[1] || return
    set -l f ~/.local/state/nvim/nvim_project_cwd
    test -f $f || return
    set -l dir (string trim < $f)
    rm -f $f
    test -d $dir && cd $dir
end
