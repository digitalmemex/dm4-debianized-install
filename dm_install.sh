#!/bin/bash

DM_VERSION="$1"
if [ -z $1 ]; then
    echo "Please enter version number!"
    exit 1
fi

ZEIT=$( date +%s )
WORKDIR=/tmp/dm_installer_${ZEIT}
BINDEST=/usr/share/deepamehta
VARDEST=/var/lib/deepamehta
CACHEDIR=/var/cache/deepamheta
LOGDIR=/var/log/deepamehta
CONFDIR=/etc/deepamehta

LINKURL="http://download.deepamehta.de/deepamehta-${DM_VERSION}.zip"
ZIPFILE="${WORKDIR}/deepamehta-${DM_VERSION}.zip"
FILEDIR="${WORKDIR}/deepamehta-${DM_VERSION}"

# Das soll später auch auf dem DM-Download Server
DEBFILE="./dm-deb.zip"
unzip -qq ${DEBFILE} -d ${WORKDIR}


# Nicht vergessen: are we root?

if [ ! -d ${WORKDIR} ]; then
    mkdir -p ${WORKDIR}
fi

wget -q ${LINKURL} -O ${ZIPFILE}

if [ "$(  file -b ${ZIPFILE} )" == "empty" ]; then
    echo "ERROR! ${ZIPFILE} is emtpy."
    exit 1
elif [ "$(  file -b ${ZIPFILE} | grep "Zip archive data" )" != "" ]; then
    unzip -qq ${ZIPFILE} -d ${WORKDIR}
fi


# Create destination directories and move the files

mkdir -p ${BINDEST}
mkdir -p ${VARDEST}
mkdir ${VARDEST}/deepamehta-db
mkdir ${VARDEST}/deepamehta-filedir
mkdir -p ${CACHEDIR}
mkdir -p ${LOGDIR}

mv ${FILEDIR}/bin ${BINDEST}/
mv ${FILEDIR}/bundle ${BINDEST}/
mv ${FILEDIR}/bundle-deploy ${BINDEST}/
mv ${FILEDIR}/bundle ${BINDEST}/

mv ${WORKDIR}/debian/default /etc/default/deepamehta
mv ${WORKDIR}/debian/initd /etc/init.d/deepamehta
mv ${WORKDIR}/debian/apache24 /etc/apache2/sites-available/deepamehta.conf.example
mv ${WORKDIR}/debian/logrotate /etc/logrotate.d/deepamehta
mv ${WORKDIR}/debian/start ${BINDEST}/deepamehta.sh

# Config files could be derived from originals with sed at some point
mv ${WORKDIR}/debian/deepamehta.conf ${CONFDIR}/
mv ${WORKDIR}/debian/deepamehta-logging.conf ${CONFDIR}/


# Create system user

useradd -s /usr/sbin/nologin -r -M -d ${VARDEST} deepamehta


# Set owner and access rights

chown -R deepamehta:root ${LOGDIR}
chmod -R 550 ${LOGDIR}

chown -R deepamehta:deepamehta ${CACHEDIR}
chmod -R 550 ${CACHEDIR}

chown -R deepamehta:deepamehta ${VARDEST}
chmod -R 550 ${VARDEST}

chown -R root:root ${BINDEST}
chmod -R 555 ${BINDEST}

chmod 444 ${BINDEST}/bundle-deploy/*

chown -R root:deepamehta ${CONFDIR}
chmod 550 ${CONFDIR}

# Update rc.d links

update-rc.d deepamehta defaults
