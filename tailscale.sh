#!/bin/bash
killall tailscaled
/usr/sbin/tailscaled --cleanup

VERSION=$(curl --silent "https://api.github.com/repos/tailscale/tailscale/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^.//') 
DIR=/boot/config/tailscale
USERSCRIPT=/boot/config/plugins/user.scripts/scripts
PLACEHOLDER="#TAILSCALE"
GODIR=/boot/config/go
STOPDIR=/boot/config/stop
SLACKBUILD=unRAID-NerdPack/source/SlackBuild/tailscale

#Create TS directory and download the latest version into it
if [ ! -d $DIR ]; then
  echo make "$DIR" dir
  mkdir -p $DIR; 
fi

echo "remove any old config and pull a fresh template copy from git"
rm -rf /root/unRAID-NerdPack
git clone https://github.com/dmacias72/unRAID-NerdPack/ /root/unRAID-NerdPack
echo "update the tailscale package for slackbuild"
wget https://pkgs.tailscale.com/stable/tailscale_"$VERSION"_amd64.tgz -P /root/$SLACKBUILD
echo "update the slackware config"
sed -i "s/1.4.4/$VERSION/g" /root/$SLACKBUILD/tailscale.SlackBuild
sed -i 's#$(pwd)#/root/unRAID-NerdPack/source/SlackBuild/tailscale#g' /root/$SLACKBUILD/tailscale.SlackBuild
echo "make the txz file!"
/root/$SLACKBUILD/tailscale.SlackBuild
echo "shift it into position"
mv "/tmp/tailscale-${VERSION}_amd64-x86_64-1_SBo.txz" "${DIR}/tailscale-${VERSION}_amd64.txz"
echo "removing uneeded files"
rm -rf /root/unRAID-NerdPack

echo "Check/create the state file to persist settings"
if [[ ! -e $DIR/tailscaled.state ]]; then
    echo "create taislcale.state"
    touch $DIR/tailscaled.state
fi

echo "if there is no tailscale config in the go file then create it"
if grep -Fxq "$PLACEHOLDER" $GODIR
then
    echo "updating version number only as config exists"
    sed -i "/installpkg/ c\installpkg ${DIR}/tailscale-${VERSION}_amd64.txz" $GODIR
else
    echo "adding to go file"
    echo "#TAILSCALE" >> $GODIR
    echo "installpkg ${DIR}/tailscale-${VERSION}_amd64.txz" >> $GODIR
    echo "/usr/sbin/tailscaled --state=$DIR/tailscaled.state --statedir=$DIR &" >> $GODIR    
fi

echo "as above but for stop"
if [[ ! -e $STOPDIR ]]; then
    echo make "$STOPDIR" 
    touch $STOPDIR
    echo "#!/bin/bash" >> $STOPDIR
    chmod +x $STOPDIR
fi

if grep -Fxq "$PLACEHOLDER" $STOPDIR
then
    echo "doing nothing to stop file"
else
    echo "adding to stop file"
    echo "#TAILSCALE" >> $STOPDIR
    echo "killall tailscaled" >> $STOPDIR
    echo "/usr/sbin/tailscaled --cleanup" >> $STOPDIR    
fi


echo "run the daemon"

installpkg $DIR/tailscale-${VERSION}_amd64.txz
/usr/sbin/tailscaled --state=$DIR/tailscaled.state --statedir=$DIR &

