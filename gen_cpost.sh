#!/bin/bash

DATUM=`date +"%Y%m%d_%H%M%S"`
FILENAME=OSMCZ_CPOST_$DATUM
USERNAME="osm.gpsfreemaps.net"
SERVER="osm.gpsfreemaps.net"
DESTPATH="/srv/www/gpsfreemaps.net/osm/www/cpost_gpi"

#DEFAULT SCRIPT VARS

#UPLOAD GPI to remote server ?
UPLOAD=1

#CLEANING DOWNLOADED / CREATED FILES
CLEANUP=1

#ALERT to POIS - BEEP BEEP GPSr
ALERTS=1

#POI CATEGORY NAME in GPSr
CATEGORY="OSMCZ_CPOST"

#Distance when GPSr DO BEEP BEEP ? [m]
PROXIMITY=100
CURL_VERSION=`curl -V | head -n1 | cut -d" " -f2`


gen_depo () {
  while read line;
  do
    PSC=$(echo "$line" | cut -f1 -d" ") && DEPO=`echo -ne $line | cut -d " " -f2-`
    echo "url = http://josm.poloha.net/cz_pbox/depo.php?id=${PSC}&filter=Partial&export=gpx";\
    echo "output = \"./schranky_gpi/${PSC} - $DEPO/${PSC}_P.gpx\"";\
    echo "url = http://josm.poloha.net/cz_pbox/depo.php?id=${PSC}&filter=Missing&export=gpx";\
    echo "output = \"./schranky_gpi/${PSC} - $DEPO/${PSC}_M.gpx\"";\
  done < depa.txt > depa_url.txt
}


if [ ! -f  depa.md5sum ]; then
  gen_depo
  md5sum depa.txt > depa.md5sum
fi

DEPA_MD5=`cat depa.md5sum 2>/dev/null`


DEPA_TXT=`md5sum depa.txt`
if [ "$DEPA_MD5" == "$DEPA_TXT" ]; then
  echo "Depa jsou aktualni, netreba update"
else
  gen_depo
  md5sum depa.txt > depa.md5sum
fi

#Kompatibilni vsude ale pomale
#curl --create-dirs -K depa_url.txt

#CURL 7.68 +
curl --parallel --parallel-immediate --parallel-max 10 --create-dirs -K depa_url.txt

echo "-w" > gpsbabel_batch
echo "-i gpx" >> gpsbabel_batch
find ./schranky_gpi/*/*.gpx -size +1c -exec echo -ne "-f \"{}\" " \; >> gpsbabel_batch
gpsbabel -D9 -b gpsbabel_batch -o garmin_gpi,alerts=${ALERTS},category=${CATEGORY},descr,proximity=${PROXIMITY},unique=1 -F "$FILENAME.gpi"

scp -C $FILENAME.gpi ${USERNAME}@${SERVER}:${DESTPATH}/archiv
scp -C $FILENAME.gpi ${USERNAME}@${SERVER}:${DESTPATH}/OSMCZ_CPOST_LATEST.gpi

#cleanup
if [ "$CLEANUP" -eq 1 ] ; then
  rm -rf schranky_gpi/ $FILENAME.gpi
fi

