#!/bin/sh

approot="$(realpath "$(dirname "$0")")"
export PATH="$approot/usr/bin:$PATH"

title="Marathon Trilogy"
msg="Select a Scenario"
m1="Marathon"
m2="Marathon 2"
mi="Marathon Infinity"

which kdialog >/dev/null
if [ $? -eq 0 ]; then
    scenario="$(kdialog --title "$title" --radiolist "$msg" \
        "$m1" "$m1" off \
        "$m2" "$m2" off \
        "$mi" "$mi" off)"
else
    which zenity >/dev/null
    if [ $? -eq 0 ]; then
        scenario="$(zenity --list --title="$title" --column="$msg" "$m1" "$m2" "$mi")"
    else
        scenario="$(xmessage -title "   $msg   " -buttons "$m1,$m2,$mi" -print -nearmouse "")"
    fi
fi

if [ "x$scenario" != "x" ]; then
    echo "\`$scenario' selected"
    alephone "$approot/usr/share/Scenarios/$scenario"
fi
