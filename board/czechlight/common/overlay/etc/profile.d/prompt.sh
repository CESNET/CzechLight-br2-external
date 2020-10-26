if [ "`id -u`" -eq 0 ]; then
    export PS1='\u@\e[93m\h\e[39m \w \# '
else
    export PS1='\u@\e[93m\h\e[39m \w \$ '
fi
