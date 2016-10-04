#!/usr/bin/bash
perl ./Build.PL
perl ./Build installdeps
perl ./Build install
perl ./Build realclean

confDir="etc/emb-oled"
mkdir -p /$confDir

if [ ! -e /$confDir/server.conf ]; #Copy file only if not present
then
    cp $confDir/server.conf /$confDir/server.conf
fi

