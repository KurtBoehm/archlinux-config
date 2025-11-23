if status is-interactive
    function yy
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
            cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end
    if test "$TERM" = xterm-kitty
        function clear_all
            printf '\033c'
        end
        alias clear='clear_all'
    end
    # register-python-argcomplete --shell fish pybin | source
    # register-python-argcomplete --shell fish submission_manager | source
end

zoxide init fish | source
