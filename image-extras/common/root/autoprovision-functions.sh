#!/bin/sh

# utility functions for the various stages of autoprovisioning

# make sure that installed packages take precedence over busybox. see https://dev.openwrt.org/ticket/18523
PATH="/usr/bin:/usr/sbin:/bin:/sbin"

# these are also copy-pasted into other scripts and config files!
rootUUID=05d615b3-bef8-460c-9a23-52db8d09e000
dataUUID=05d615b3-bef8-460c-9a23-52db8d09e001
swapUUID=05d615b3-bef8-460c-9a23-52db8d09e002

ar71xx=1
if [ -e /lib/ar71xx.sh ] ; then
	. /lib/ar71xx.sh
else
	ar71xx=0
fi


# let's try some defaults...
autoprovisionUSBLed="tp-link:green:usb"
autoprovisionStatusLed="tp-link:green:qss"

if ar71xx ; then
# CUSTOMIZE
case $(ar71xx_board_name) in
"tl-wr1043nd")
        autoprovisionUSBLed="tp-link:green:usb"
        autoprovisionStatusLed="tp-link:green:qss"
	;;
"tl-mr3020")
        autoprovisionUSBLed="tp-link:green:wps"
        autoprovisionStatusLed="tp-link:green:wlan"
	;;
"tl-wr2543n")
        autoprovisionUSBLed="tp-link:green:wps"
        autoprovisionStatusLed="tp-link:green:wlan5g"
	;;
"tl-wdr4300")
        autoprovisionUSBLed="tp-link:blue:wan"
        autoprovisionStatusLed="tp-link:blue:qss"
	;;
esac
fi

log()
{
    /usr/bin/logger -t autoprov -s $*
}

setLedAttribute()
{
    [ -f "/sys/class/leds/$1/$2" ] && echo "$3" > "/sys/class/leds/$1/$2"
}

signalAutoprovisionWorking()
{
    setLedAttribute ${autoprovisionStatusLed} trigger none
    setLedAttribute ${autoprovisionStatusLed} trigger timer
    setLedAttribute ${autoprovisionStatusLed} delay_on 2000
    setLedAttribute ${autoprovisionStatusLed} delay_off 2000
}

signalAutoprovisionWaitingForUser()
{
    setLedAttribute ${autoprovisionStatusLed} trigger none
    setLedAttribute ${autoprovisionStatusLed} trigger timer
    setLedAttribute ${autoprovisionStatusLed} delay_on 200
    setLedAttribute ${autoprovisionStatusLed} delay_off 300
}

signalWaitingForPendrive()
{
    setLedAttribute ${autoprovisionUSBLed} trigger none
    setLedAttribute ${autoprovisionUSBLed} trigger timer
    setLedAttribute ${autoprovisionUSBLed} delay_on 200
    setLedAttribute ${autoprovisionUSBLed} delay_off 300
}

signalFormatting()
{
    setLedAttribute ${autoprovisionUSBLed} trigger none
    setLedAttribute ${autoprovisionUSBLed} trigger timer
    setLedAttribute ${autoprovisionUSBLed} delay_on 1000
    setLedAttribute ${autoprovisionUSBLed} delay_off 1000
}

stopSignallingAnything()
{
    # TODO this is wrong, they should be restored to their original state.
    # but then leds are only touched in the setup stage, which is ephemeral when things work as expected...
    setLedAttribute ${autoprovisionStatusLed} trigger none
    setLedAttribute ${autoprovisionUSBLed} trigger usbdev
}

setRootPassword()
{
    local password=$1
    if [ "$password" == "" ]; then
        # set and forget a random password merely to disable telnet. login will go through ssh keys.
        password=$(</dev/urandom sed 's/[^A-Za-z0-9+_]//g' | head -c 22)
    fi
    #echo "Setting root password to '"$password"'"
    log "Setting root password"
    echo -e "$password\n$password\n" | passwd root
}
