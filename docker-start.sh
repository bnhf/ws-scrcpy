#!/bin/bash

#androids=( $TUNER1_IP $TUNER2_IP $TUNER3_IP $TUNER4_IP )

# Make tuner hostnames without local domain name resolvable in Alpine containers by adding each to /etc/hosts
fixTunerDNS() {

  local androids=($@)
  local resolvFile=/etc/resolv.conf
  local hostsFile=/etc/hosts
  local localDomain=$(awk '/search/ {print $2}' $resolvFile)
  local ipv4Pattern='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
  local hostnamePattern='^[a-zA-Z0-9_-]+$'
    
  for android in "${androids[@]}"
    do
      local tunerNoPort="${android%%:*}"
      
      if [[ -n $$android ]]; then
        if [[ $tunerNoPort =~ $ipv4Pattern ]]; then
          break
        elif [[ $tunerNoPort =~ $hostnamePattern ]]; then
          tunerIP=$(dig +short $tunerNoPort.$localDomain)
          echo "$tunerIP $tunerNoPort" >> $hostsFile
        fi
      fi
  done
}

# Make encoder hostnames without local domain name resolvable in Alpine containers by adding each to /etc/hosts
fixEncoderDNS() {

  local encoders=($@)
  local resolvFile=/etc/resolv.conf
  local hostsFile=/etc/hosts
  local localDomain=$(awk '/search/ {print $2}' $resolvFile)
  local ipv4Pattern='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
  local hostnamePattern='^[a-zA-Z0-9_-]+$'
      
  for encoder in "${encoders[@]}"
    do
      local encoderNoURL=$(echo "$encoder" | sed -n 's|^.*://\([^/]*\)/.*|\1|p')
            
      if [[ -n $encoder ]]; then
        if [[ $encoderNoURL =~ $ipv4Pattern ]]; then
          break
        elif [[ $encoderNoURL =~ $hostnamePattern ]]; then
          encoderIP=$(dig +short $encoderNoURL.$localDomain)
          echo "$encoderIP $encoderNoURL" >> $hostsFile          
        fi
      fi
  done

  awk '!a[$0]++' $hostsFile
}

# List currently connected adb devices and then connect to each indivdually
adbConnections() {

  local androids=($@)
  adb devices

  for android in "${androids[@]}"
    do
      if [[ -n $android ]]; then
        adb connect $android
      fi
  done
}

# Check if a given script is already present in the appropriate scripts directory, and if not, copy it
checkScripts() {

  local scripts=($@)
  mkdir -p ./scripts/onn/youtubetv ./$STREAMER_APP
  #scripts=( prebmitune.sh bmitune.sh stopbmitune.sh isconnected.sh keep_alive.sh reboot.sh )
  
  for script in "${scripts[@]}"
    do
      if [ ! -f /opt/scripts/onn/youtubetv/$script ] && [ -f /tmp/scripts/onn/youtubetv/$script ] || [[ $UPDATE_SCRIPTS == "true" ]]; then
        cp /tmp/scripts/onn/youtubetv/$script ./scripts/onn/youtubetv \
        && chmod +x ./scripts/onn/youtubetv/$script \
        && echo "No existing ./scripts/onn/youtubetv/$script found or UPDATE_SCRIPTS set to true"
      else
        if [ -f /tmp/scripts/onn/youtubetv/$script ]; then
          echo "Existing ./scripts/onn/youtubetv/$script found, and will be preserved"
        fi
      fi

      if [ ! -f /opt/$STREAMER_APP/$script ] && [ -f /tmp/$STREAMER_APP/$script ] || [[ $UPDATE_SCRIPTS == "true" ]]; then
        cp /tmp/$STREAMER_APP/$script ./$STREAMER_APP \
        && chmod +x ./$STREAMER_APP/$script \
        && echo "No existing ./$STREAMER_APP/$script found or UPDATE_SCRIPTS set to true"
      else
        if [ -f /tmp/$STREAMER_APP/$script ]; then
          echo "Existing ./$STREAMER_APP/$script found, and will be preserved"
        fi
      fi
  done
}

# Check if a given M3U file is already present in the M3U directory, and if not, copy it
checkM3Us() {

  local m3us=($@)
  mkdir -p ./m3u
  #m3us=( directv.m3u foo-fighters.m3u hulu.m3u youtubetv.m3u )

  for m3u in "${m3us[@]}"
    do
      if [ ! -f /opt/m3u/$m3u ] || [[ $UPDATE_M3US == "true" ]]; then
        cp /tmp/m3u/$m3u ./m3u \
        && echo "No existing $m3u found or UPDATE_M3US set to true"
      else
        echo "Existing $m3u found, and will be preserved"
      fi
  done
}

# Fix hostanme resolution, connect adb devices, copy scripts and M3U files as needed, start ws-scrcpy and ah4c
main() {

  fixTunerDNS $TUNER1_IP $TUNER2_IP $TUNER3_IP $TUNER4_IP
  fixEncoderDNS $ENCODER1_URL $ENCODER2_URL $ENCODER3_URL $ENCODER4_URL
  adbConnections $TUNER1_IP $TUNER2_IP $TUNER3_IP $TUNER4_IP
  checkScripts prebmitune.sh bmitune.sh stopbmitune.sh isconnected.sh keep_alive.sh reboot.sh
  checkM3Us directv.m3u foo-fighters.m3u hulu.m3u youtubetv.m3u sling.m3u
  npm start --prefix ws-scrcpy &
  ./ah4c
}

main