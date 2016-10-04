#!/usr/bin/bash

perl ./Build.PL
perl ./Build installdeps
perl ./Build install
perl ./Build realclean

confDir="etc/emb-oled"
binDir="/usr/local/bin"
systemdServiceDir="etc/systemd/system"


mkdir -p /$confDir
if [ ! -e /$confDir/server.conf ]; #Copy file only if not present
then
    cp $confDir/server.conf /$confDir/server.conf
fi


cp scripts/oled_server $binDir/oled_server


cp $systemdServiceDir/emb-oled.service /$systemdServiceDir/emb-oled.service
systemctl daemon-reload
systemctl enable emb-oled
systemctl start emb-oled
