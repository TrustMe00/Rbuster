#!/bin/bash
scan() {
RHOSTS=$1
# scan les ip et trouve les hotes ayant le le ports 873 et save ça dans un fichier hosts
masscan --max-rate=30000000 -p 873 --range $RHOSTS --exclude 255.255.255.255 > hosts.txt
# extrait l'ip de chaque ligne
grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" hosts.txt >> targets.txt
rm hosts.txt  2>&1
}
check_access () {
amap -C 1 -T 1 -t 1 -B $RHOST 873 > /tmp/24373ff2-6975-4b46-ba23-46c8035f5396.txt 2>&1
str="@RSYNCD"
if grep -qF "$str" /tmp/24373ff2-6975-4b46-ba23-46c8035f5396.txt;then
echo "RSYNC IS BROWSABLE!"
echo $RHOST >> targets_873.txt
else
echo "error!"
fi
}

explore() {
#RHOST=$1
#echo [+] RHOST = $1
RCMD=$(rsync --timeout=5 --password-file=pass.txt rsync://$RHOST)
share=$(echo $RCMD | cut -d" " -f1)
timeout 15 rsync --password-file=pass.txt rsync://$RHOST/ > rootfolders.txt
cat rootfolders.txt  |  cut -d ' ' -f 1  |  while read output
do
   ExploreRsync=$(rsync   --timeout=5 --password-file=pass.txt rsync://$RHOST/$output)
   ErrorExploreRsync="error"
   if [[ "$ErrorExploreRsync" == *"$ExploreRsync"* ]]; then
     echo "[ERROR] : rsync://$RHOST/$output"
   else
     echo "EXPLORING $output"
     rsync  -av --list-only   --timeout=5 --password-file=pass.txt rsync://$RHOST/$output >> $RHOST.txt
   fi  
done
}
# scan a range demo
# 168.221.0.0/16
echo "
 ######  ######                                    
 #     # #     # #    #  ####  ##### ###### #####  
 #     # #     # #    # #        #   #      #    #
 ######  ######  #    #  ####    #   #####  #    #
 #   #   #     # #    #      #   #   #      #####  
 #    #  #     # #    # #    #   #   #      #   #  
 #     # ######   ####   ####    #   ###### #    #
                                                   
"
#rm targets.txt 2>&1
#rm targets_873.txt 2>&1
PS3='Please enter your choice: '
options=("Scan to discover RSYNC servers" "Check for unauthenticated access" "Explore browsables RSYNC servers" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Scan to discover RSYNC servers")
            RHOSTS="0.0.0.0/0"
            echo "set RHOSTS => $RHOSTS"
            read -p "RHOSTS => " RHOSTS
            echo "RHOSTS => $RHOSTS"
            scan $RHOSTS
            FILE=targets.txt
            if [ -f "$FILE" ]; then
             echo "$(wc -l targets.txt)"
            else
             echo "[ERROR] - $FILE does not exist."
             exit 2
            fi
            ;;
        "Check for unauthenticated access")
            echo "you chose choice 2"
            FILE=targets.txt
            if [ -f "$FILE" ]; then
             cat targets.txt |  while read output
             do
                 RHOST=$output
                 echo "[+] RHOST = $output"
                 check_access $output
             done
            else
             echo "[ERROR] - $FILE does not exist."
             exit 2
            fi
            ;;
        "Explore browsables RSYNC servers")
            FILE=targets_873.txt
            if [ -f "$FILE" ]; then
             cat targets_873.txt |  while read output
             do
                 RHOST=$output
                 echo "[+] RHOST = $output"
                 touch pass.txt
        chmod 600 pass.txt
        echo "password" > pass.txt
                 explore $output
             done
            else
             echo "[ERROR] - $FILE does not exist."
             exit 2
            fi
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
