#!/bin/bash
INPUT=/tmp/menu.sh.$$

export NCURSES_NO_UTF8_ACS=1

# Storage file for displaying cal and date command output
OUTPUT=/tmp/output.sh.$$

# get text editor or fall back to vi_editor
vi_editor=${EDITOR-vi}

# trap and delete temp files
trap "rm $OUTPUT; rm $INPUT; exit" SIGHUP SIGINT SIGTERM

#Verzeichnisse einlesen
rm meikel_nodes.txt
folder=( $(find -maxdepth 1 -type d) )

for i in "${folder[@]}"; do
  IFS="_"
  set -- $i

  if [[ "$1" =~ "./.transcendence" ]]
  then
    echo "$2"  >> meikel_nodes.txt
  fi
done


# Alias fuer start   auswaehlen
declare -a array
 i=1 #Index counter for adding to array
 j=1 #Option menu value generator

 while read line
 do
    array[ $i ]=$j
    (( j++ ))
    array[ ($i + 1) ]=$line
    (( i=($i+2) ))

 done < <(cat meikel_nodes.txt)

 #Define parameters for menu
 TERMINAL=$(tty) #Gather current terminal session for appropriate redirection
 HEIGHT=20
 WIDTH=76
 CHOICE_HEIGHT=16
 BACKTITLE=""
 TITLE="Meikel's Telos Menu"
 MENU="                            Select Alias"

 #Build the menu with variables & dynamic content
 CHOICE=$(dialog --clear \
                 --backtitle "$BACKTITLE" \
                 --title "$TITLE" \
                 --menu "$MENU" \
                 $HEIGHT $WIDTH $CHOICE_HEIGHT \
                 "${array[@]}" \
                 2>&1 >$TERMINAL)

i=$CHOICE
k=$(($i+$i))
ALIAS=${array[ $k ]}


#
# Purpose - display output using msgbox
#  $1 -> set msgbox height
#  $2 -> set msgbox width
#  $3 -> set msgbox title
#
function display_output(){
        local h=${1-15}                 # box height default 10
        local w=${2-41}                 # box width default 41
        local t=${3-Output}     # box title
        dialog --backtitle "Meikel's Telos Menu" --title "${t}" --clear --msgbox "$(<$OUTPUT)" ${h} ${w}
}
#

#
# Purpose - display current system date & time
#
function show_date(){
        echo "Today is $(date) @ $(hostname -f)." >$OUTPUT
    display_output 6 60 "Date and Time"
}
#
# Purpose - display a calendar
#
function show_calendar(){
        cal >$OUTPUT
        display_output 13 25 "Calendar"
}
#
# set infinite loop
#
while true
do

### display main menu ###
dialog --clear  --help-button --backtitle "Meikel's Telos Menu 2.0.0 Beta" \
--title "[ Alias: ${ALIAS} ]" \
--menu "" 20 60 10 \
1  "show transcendence.conf" \
2  "edit transcendence.conf" \
3  "start Telos-Server" \
4  "stop  Telos-Server" \
5  "Server Masternode Status" \
6  "Server Getinfo" \
7  "Server Sync-Status" \
8  "Select another Alias" \
9  "List bin folder" \
0  "Exit" 2>"${INPUT}"

menuitem=$(<"${INPUT}")


# make decsion
case $menuitem in
        1) cd ~
           FILE=".transcendence_${ALIAS}/transcendence.conf"
           dialog --textbox "${FILE}" 0 0
           ;;
        2) cd ~
           nano ".transcendence_${ALIAS}/transcendence.conf"
        ;;
        3) cd ~
           bin/transcendenced_${ALIAS}.sh -daemon
           echo -e "Press ENTER to contiue \c"
           read input
        ;;
        4) cd ~
           bin/transcendence-cli_${ALIAS}.sh stop
           echo -e "Press ENTER to contiue \c"
           read input
        ;;
        5) echo "Masternode Status: ${ALIAS}" > /tmp/mnstatus.txt
           ~/bin/transcendence-cli_${ALIAS}.sh masternode status >> /tmp/mnstatus.txt
           dialog --textbox "/tmp/mnstatus.txt" 0 0
        ;;
        6) echo "Masternode Getinfo: ${ALIAS}" > /tmp/mnstatus.txt
           ~/bin/transcendence-cli_${ALIAS}.sh getinfo >> /tmp/mnstatus.txt
           dialog --textbox "/tmp/mnstatus.txt" 0 0
        ;;
        7)echo "Masternode Sync-Status: ${ALIAS}" > /tmp/mnstatus.txt
          ~/bin/transcendence-cli_${ALIAS}.sh mnsync status  >> /tmp/mnstatus.txt
          dialog --textbox "/tmp/mnstatus.txt" 0 0
        ;;
        8) declare -a array
           i=1 #Index counter for adding to array
           j=1 #Option menu value generator
          while read line
          do
             array[ $i ]=$j
             (( j++ ))
             array[ ($i + 1) ]=$line
             (( i=($i+2) ))
         done < <(cat meikel_nodes.txt)

         #Define parameters for menu
         TERMINAL=$(tty) #Gather current terminal session for appropriate redirection
         HEIGHT=20
         WIDTH=76
         CHOICE_HEIGHT=16
         BACKTITLE="Back_Title"
         TITLE="Dynamic Dialog"
         MENU="Choose a file:"

         #Build the menu with variables & dynamic content
         CHOICE=$(dialog --clear \
                 --backtitle "$BACKTITLE" \
                 --title "$TITLE" \
                 --menu "$MENU" \
                 $HEIGHT $WIDTH $CHOICE_HEIGHT \
                 "${array[@]}" \
                 2>&1 >$TERMINAL)
         i=$CHOICE
         k=$(($i+$i))
         ALIAS=${array[ $k ]}
         ;;
        9) dialog --title "List files of directory /bin" --msgbox "$(ls ~/bin )" 100 100

        ;;
        0) break;;
esac

done

# if temp files found, delete em
[ -f $OUTPUT ] && rm $OUTPUT
[ -f $INPUT ] && rm $INPUT

