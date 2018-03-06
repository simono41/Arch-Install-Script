alias reboot="sudo systemctl reboot"
alias poweroff="sudo systemctl poweroff"
alias halt="sudo systemctl halt"
alias hibernate="sudo systemctl hibernate"
alias hybrid="sudo systemctl hybrid-sleep"
alias suspend="sudo systemctl suspend"

function fish_prompt
    powerline-shell --shell bare $status
end

# Start X at login
if status is-login
    if test -z "$DISPLAY" -a $XDG_VTNR = 1
        exec startx -- -keeptty
    end
end
