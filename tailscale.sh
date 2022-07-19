#!/bin/bash
#description=this kills tailscale, redownloads and installs the latets version and then runs tailscale again - you should only need to run tailscale up once 
#backgroundOnly=true 

killall tailscaled
/usr/sbin/tailscaled --cleanup

VERSION=$(curl --silent "https://api.github.com/repos/tailscale/tailscale/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^.//') 
DIR=/boot/config/tailscale
USERSCRIPT=/boot/config/plugins/user.scripts/scripts/tailscale
USERSCRIPTFILE=/boot/config/plugins/user.scripts/scripts/tailscale/script
PLACEHOLDER="#TAILSCALE"
GODIR=/boot/config/go
STOPDIR=/boot/config/stop
SLACKBUILD=unRAID-NerdPack/source/SlackBuild/tailscale

echo "Create TS directory"
if [ ! -d $DIR ]; then
  echo make "$DIR" dir
  mkdir -p $DIR; 
fi

echo "remove any old config and pull a fresh template copy from git"
rm -rf /root/unRAID-NerdPack
git clone https://github.com/dmacias72/unRAID-NerdPack/ /root/unRAID-NerdPack

echo "update the tailscale package to be used with slackbuild"
wget https://pkgs.tailscale.com/stable/tailscale_"$VERSION"_amd64.tgz -P /root/$SLACKBUILD

echo "update the slackware config"
echo "set latest version number which is ${VERSION}"
sed -i "s/1.4.4/$VERSION/g" /root/$SLACKBUILD/tailscale.SlackBuild
echo "set the directory to slackbuild from"
sed -i 's#$(pwd)#/root/unRAID-NerdPack/source/SlackBuild/tailscale#g' /root/$SLACKBUILD/tailscale.SlackBuild

echo "make the txz file!"
/root/$SLACKBUILD/tailscale.SlackBuild

echo "move it into position"
mv "/tmp/tailscale-${VERSION}_amd64-x86_64-1_SBo.txz" "${DIR}/tailscale-${VERSION}_amd64.txz"

echo "removing unneeded files"
rm -rf /root/unRAID-NerdPack

echo "Check/create the tailscaled.state in boot DIR to persist settings"
if [[ ! -e $DIR/tailscaled.state ]]; then
    echo "create taislcale.state"
    touch $DIR/tailscaled.state
fi

echo "if there is no tailscale config in the GO file then create it"
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

echo "create stop file if one doesnt exist"
if [[ ! -e $STOPDIR ]]; then
    echo "make $STOPDIR" 
    touch $STOPDIR
    echo "#!/bin/bash" >> $STOPDIR
    chmod +x $STOPDIR
fi

echo "if there is no tailscale config in the STOP file then create it"
if grep -Fxq "$PLACEHOLDER" $STOPDIR
then
    echo "doing nothing to stop file"
else
    echo "adding to stop file"
    echo "#TAILSCALE" >> $STOPDIR
    echo "killall tailscaled" >> $STOPDIR
    echo "/usr/sbin/tailscaled --cleanup" >> $STOPDIR    
fi

echo "Create userscript directory"
if [ ! -d $USERSCRIPT ]; then
  echo make "$USERSCRIPT" dir
  mkdir -p $USERSCRIPT; 
fi

echo "add script to userscript plugin DIR for easy rerun"
if [[ -e $USERSCRIPTFILE ]]; then
    rm $USERSCRIPTFILE
fi
echo "make $USERSCRIPTFILE" 
curl -LJ https://raw.githubusercontent.com/samabsalom/unraid-tailscale/main/tailscale.sh -o $USERSCRIPTFILE
chmod +x $USERSCRIPTFILE

echo " install and run tailscaled"
echo "dont forget tailscale up"
installpkg $DIR/tailscale-${VERSION}_amd64.txz
/usr/sbin/tailscaled --state=$DIR/tailscaled.state --statedir=$DIR &
