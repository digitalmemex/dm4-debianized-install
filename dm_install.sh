#!/bin/bash

# Enter a valid version number, e.g. 4.8.2
DM_VERSION="$1"
if [ -z $1 ]; then
    echo "ERROR! Please enter a valid version number, e.g. 4.8 or 4.8.2."
    exit 1
fi

# Are we root?
if [ $( id -u ) != 0 ]; then
    echo "ERROR! Please run the script as root or sudo $0."
    exit 1
fi

# Variables
ZEIT=$( date +%s )
WORKDIR=/tmp/dm_installer_${ZEIT}
BINDEST=/usr/share/deepamehta
VARDEST=/var/lib/deepamehta
CACHEDIR=/var/cache/deepamehta
LOGDIR=/var/log/deepamehta
CONFDIR=/etc/deepamehta
DOCDIR=/usr/share/doc/deepamehta

LINKURL="http://download.deepamehta.de/deepamehta-${DM_VERSION}.zip"
DEBURL="http://download.deepamehta.de/debian/dm-deb.zip"
ZIPFILE="${WORKDIR}/deepamehta-${DM_VERSION}.zip"
FILEDIR="${WORKDIR}/deepamehta-${DM_VERSION}"

if [ ! -d ${WORKDIR} ]; then
    mkdir -p ${WORKDIR}
fi

# install jre
if [ -z "$( dpkg-query -s 'default-jre-headless' | grep Status | grep "install ok installed" )" ]; then
    apt-get install default-jre-headless
fi

# Fetch and unpack DeepaMehta
wget -q ${LINKURL} -O ${ZIPFILE}
if [ "$(  file -b ${ZIPFILE} )" == "empty" ]; then
    echo "ERROR! ${ZIPFILE} is emtpy."
    exit 1
elif [ "$(  file -b ${ZIPFILE} | grep "Zip archive data" )" != "" ]; then
    unzip -qq ${ZIPFILE} -d ${WORKDIR}
fi

# Fetch and unpack Debian Scripts
wget -q ${DEBURL} -O ${WORKDIR}/dm-deb.zip
if [ "$(  file -b ${WORKDIR}/dm-deb.zip )" == "empty" ]; then
    echo "ERROR! ${WORKDIR}/dm-deb.zip is emtpy."
    exit 1
elif [ "$(  file -b ${WORKDIR}/dm-deb.zip | grep "Zip archive data" )" != "" ]; then
    unzip -qq ${WORKDIR}/dm-deb.zip -d ${WORKDIR}
fi

# Remove Gogo-shell files
rm ${FILEDIR}/bundle/org.apache.felix.gogo.*

# Create destination directories and move the files
if [ ! -d ${CONFDIR} ]; then
    mkdir -p ${CONFDIR}
else
    mv ${CONFDIR} ${CONFDIR}.${ZEIT}.bak
    mkdir -p ${CONFDIR}
fi
if [ ! -d ${BINDEST} ]; then
    mkdir -p ${BINDEST}
    mkdir ${BINDEST}/bin
    mkdir ${BINDEST}/bundle
    mkdir ${BINDEST}/bundle-deploy
else
    mv ${BINDEST} ${BINDEST}.${ZEIT}.bak
    mkdir -p ${BINDEST}
    mkdir ${BINDEST}/bin
    mkdir ${BINDEST}/bundle
    mkdir ${BINDEST}/bundle-deploy
fi
if [ ! -d ${VARDEST} ]; then
    mkdir -p ${VARDEST}
    mkdir ${VARDEST}/deepamehta-db
    mkdir ${VARDEST}/deepamehta-filedir
else
    mv ${VARDEST} ${VARDEST}.${ZEIT}.bak
    mkdir -p ${VARDEST}
    mkdir ${VARDEST}/deepamehta-db
    mkdir ${VARDEST}/deepamehta-filedir
fi
if [ ! -d ${CACHEDIR} ]; then
    mkdir -p ${CACHEDIR}
else
    rm -r ${CACHEDIR}
    mkdir -p ${CACHEDIR}
fi
if [ ! -d ${LOGDIR} ]; then
    mkdir -p ${LOGDIR}
fi
if [ ! -d ${DOCDIR} ]; then
    mkdir -p ${DOCDIR}
fi

mv ${FILEDIR}/bundle/deepamehta-* ${BINDEST}/bundle-deploy/
mv ${FILEDIR}/bundle/dm4* ${BINDEST}/bundle-deploy/
mv ${FILEDIR}/bundle/* ${BINDEST}/
mv ${FILEDIR}/bin/* ${BINDEST}/
mv ${FILEDIR}/bundle-deploy/* ${BINDEST}/bundle-deploy/

mv ${WORKDIR}/debian/default /etc/default/deepamehta
mv ${WORKDIR}/debian/initd /etc/init.d/deepamehta
mv ${WORKDIR}/debian/apache24 ${DOCDIR}/
mv ${WORKDIR}/debian/logrotate /etc/logrotate.d/deepamehta
mv ${WORKDIR}/debian/start ${BINDEST}/deepamehta.sh

# Config files could be derived from originals with sed at some point
mv ${WORKDIR}/debian/deepamehta.conf ${CONFDIR}/
mv ${WORKDIR}/debian/deepamehta-logging.conf ${CONFDIR}/

# Clean up
rm -r ${FILEDIR}/bundle-deploy
rm -r ${FILEDIR}/bundle-dev
rm -r ${FILEDIR}/conf
rm ${FILEDIR}/deepamehta-*

# Move License and Readme to Docs
mv ${FILEDIR}/* ${DOCDIR}/

# Remove Workdir
rm -r ${WORKDIR}

# Create system user
useradd -s /usr/sbin/nologin -r -M -d ${VARDEST} deepamehta

# Set owner and access rights
chown -R deepamehta:root ${LOGDIR}
chmod -R 770 ${LOGDIR}

chown -R deepamehta:deepamehta ${CACHEDIR}
chmod -R 770 ${CACHEDIR}

chown -R deepamehta:deepamehta ${VARDEST}
chmod -R 770 ${VARDEST}

chown -R root:root ${BINDEST}
chmod 555 ${BINDEST}
chmod 444 ${BINDEST}/bundle/*
chmod 444 ${BINDEST}/bundle-deploy/*

chown -R root:deepamehta ${CONFDIR}
chmod 550 ${CONFDIR}

chmod 755 /etc/init.d/deepamehta
chmod 755 /usr/share/deepamehta/deepamehta.sh

# Update rc.d links
cd /etc/init.d/
update-rc.d deepamehta defaults

# Inform the admin
echo ""
echo "DeepaMehta ${DM_VERSION} was installed successfuly."
echo "Please adjust /etc/deepamehta/deepamehta.conf to your needs."
echo "Don't forget to enable DeepaMehta in /etc/default/deepamehta before you start it!"

#EOF
