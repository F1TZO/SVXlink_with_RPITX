#!/bin/bash

########################################################################
#                                                                      #
# Pour la detection du passage en TX et l activation de rpitx de F5OEO #
# To detect when svxlink switch to TX and active F5OEO rpitx           #
#                                                                      #
# Detection sur GPIO 20 pour lire l etat du 21 (TX de svxlink)         #
# Detection GPIO, 20 to read state of 21 (svxlink TX)                  #
# By Michel - F1TZO                                                    #
#                                                                      #
########################################################################

########################################################################
#                                                                      #
# Prerequis : rpitx est installe : voir le github de F5OEO             #
# Prerequisites : rpitx is installed : see F5OEO github                #
#                                                                      #
# Et ne pas oublier de d initialiser les GPIO dans le /etc/rc.local    #
# And don't forget to declare the GPIO init in /etc/rc.local           #
#                                                                      #
#       # svxlinkx GPIO 21:PTT - GPIO 20:read TX State                 #
#       echo "21" > /sys/class/gpio/export &                           #
#       sleep 2                                                        #
#       echo out > /sys/class/gpio/gpio21/direction                    #
#                                                                      #
#       # Read TX State                                                #
#       echo "20" > /sys/class/gpio/export &                           #
#       sleep 2                                                        #
#       echo in > /sys/class/gpio/gpio20/direction                     #
#                                                                      #
#                                                                      #
# ET NE PAS OUBLIER LE CAVALIER ENTR ENTRE LES GPIO 20 et 21           #
# donc entre les PIN 38 et 40                                          #
#                                                                      #
# AND DON T FORGET TO ADD JUMPER BETWWEN GPIO 20 and 21                #
# So between PIN 38 and 40                                             #
#                                                                      #
########################################################################


while true
do
STATE=$(cat /sys/class/gpio/gpio20/value)

if [ $STATE  -eq 1 ]; then
        echo "EN TX"
        arecord -c1 -r48000 -fS16_LE - | nc -l -u 1233  | csdr convert_i16_f | csdr gain_ff 7000 | csdr convert_f_samplerf 20833 | sudo rpitx -i - -m RF -f 145400 & export RPITX_PID=$!
        gpio -g wfi 20 both
        ASOUND_PID=$(ps ax | grep arecord | grep -v grep | awk '{ print $1 }')
        echo "ASOUNDPID="$ASOUND_PID
        echo "KILL PID : " $RPITX_PID " " $ASOUND_PID
        kill -15 $RPITX_PID $ASOUND_PID
        /root/stop_tx.sh
        sleep 0.4
        STATE=$(cat /sys/class/gpio/gpio20/value)
fi
done
