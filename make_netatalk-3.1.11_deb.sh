# credits to https://gist.github.com/davecoutts/8e7367bc4db8b110e586a41bfab42136
# This gist gives instructions to build a basic deb package of netatalk-3.1.11 using checkinstall on Ubuntu 18.04.
# With the idea being that you build the deb on your build server and install from the resulting deb in production.
# Given that the deb is packaged using checkinstall with basic options, think home use, not real production.

# Note that this build does not provide the spotlight feature.
# The tracker packages have been left out as the intent was to provide TimeMachine functionality only.


#------------------------------------------------------------
# STEP ONE - Make the Netatalk deb on a build machine
#------------------------------------------------------------

NETATALK_VERSION='3.1.11'
MAINTAINER='YOUR NAME \YOUR EMAIL\>'

sudo apt install --yes \
build-essential \
libevent-dev \
libssl-dev \
libgcrypt-dev \
libkrb5-dev \
libpam0g-dev \
libwrap0-dev \
libdb-dev \
libtdb-dev \
avahi-daemon \
libavahi-client-dev \
libacl1-dev \
libldap2-dev \
libcrack2-dev \
systemtap-sdt-dev \
libdbus-1-dev \
libdbus-glib-1-dev \
libglib2.0-dev


wget http://prdownloads.sourceforge.net/netatalk/netatalk-${NETATALK_VERSION}.tar.gz -P /tmp
tar -xzf /tmp/netatalk-${NETATALK_VERSION}.tar.gz -C /tmp
cd /tmp/netatalk-${NETATALK_VERSION}


./configure \
--with-init-style=debian-systemd \
--without-libevent \
--with-cracklib \
--enable-krbV-uam \
--with-pam-confdir=/etc/pam.d \
--with-dbus-daemon=/usr/bin/dbus-daemon \
--with-dbus-sysconf-dir=/etc/dbus-1/system.d

make

sudo apt install --yes checkinstall

sudo checkinstall -D \
--pkgname='netatalk' \
--pkgversion="${NETATALK_VERSION}" \
--maintainer="${MAINTAINER}" \
make install

ls -lh /tmp/netatalk*/netatalk*.deb
cp /tmp/netatalk*/netatalk*.deb $HOME
cd $HOME
sudo rm -rf /tmp/netatalk*

#------------------------------------------------------------
# STEP TWO - Install the Netatalk deb on a production server
#------------------------------------------------------------

TIMEMACHINE_PATH='/data/timemachine'
VALID_USER='YOURUSERNAME'

sudo mkdir -p $TIMEMACHINE_PATH
sudo chown -R $VALID_USER:$VALID_USER $TIMEMACHINE_PATH

# Manually install netatalk_3.1.11 dependencies. 
sudo apt install --yes \
avahi-daemon \
cracklib-runtime \
db-util \
db5.3-util \
libtdb1 \
libavahi-client3 \
libcrack2 \
libcups2 \
libpam-cracklib \
libdbus-glib-1-2

sudo dpkg -i netatalk_3.1.11-1_amd64.deb

sudo ldconfig

sudo mv /usr/local/etc/afp.conf /usr/local/etc/afp.conf.orig

echo "[Global]
mimic model = TimeCapsule6,106
log level = default:warn
log file = /var/log/afpd.log
spotlight = no

[TimeMachine]
path = ${TIMEMACHINE_PATH}
valid users = ${VALID_USER}
time machine = yes
vol size limit = 1430512" | sudo tee /usr/local/etc/afp.conf

sudo systemctl enable netatalk

sudo systemctl daemon-reload

sudo systemctl start netatalk

systemctl status avahi-daemon
systemctl status netatalk

/usr/local/sbin/netatalk -V
/usr/local/sbin/afpd -V

# EOF
