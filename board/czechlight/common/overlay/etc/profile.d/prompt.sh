if [ "`id -u`" -eq 0 ]; then
    export PS1='\e[93m\h \w \#\e[39m '
else
    export PS1='\e[93m\u@\h \w \$\e[39m '
fi
