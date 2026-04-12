function fish_prompt
    set -l user_color  "89B4FA"  # blue   — user
    set -l path_color  "A6E3A1"  # green  — path
    set -l git_color   "F38BA8"  # red    — git branch
    set -l dirty_color "FAB387"  # peach  — dirty marker

    set -l user (whoami)
    set -l path (prompt_pwd)

    set -l git_info ""
    if command -sq git; and git rev-parse --is-inside-work-tree &>/dev/null
        set -l branch (git symbolic-ref --short HEAD 2>/dev/null; or git rev-parse --short HEAD 2>/dev/null)
        set -l dirty ""
        if not git diff --quiet 2>/dev/null; or not git diff --cached --quiet 2>/dev/null
            set dirty (set_color --bold $dirty_color)"*"(set_color normal)
        end
        set git_info " "(set_color $git_color)"($branch$dirty)"(set_color normal)
    end

    echo ""
    echo -n (set_color $user_color)$user(set_color normal)
    echo -n "  "
    echo -n (set_color $path_color)$path(set_color normal)
    echo $git_info
    echo -n (set_color $user_color)"❯"(set_color normal)" "
end
