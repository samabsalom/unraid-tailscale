# unraid-tailscale

This is based on https://github.com/dmacias72/unRAID-NerdPack


this should pull and run the script
```
curl -LO https://raw.githubusercontent.com/samabsalom/unraid-tailscale/main/tailscale.sh | bash
```

but i recommend 
```
git clone https://github.com/samabsalom/unraid-tailscale.git
cd unraid-tailscale
./tailscale.sh
```

you might need to
```
chmod +x tailscale.sh
```

This script 
- kills any running tailscaled instances
- downloads unraid nerdpack and then downloads the latest tailscale file for unraid into this directory 
- it uses the nerdpack slackbuild file to make a slackware file that can be installed on unraid and moves it into /boot/config folder which survives updates and allows for quick startup on machine boot
- it then creates a tailscale state file in the /boot/config folder which survives updates so you never lose tailscale settings and IP etc
- it adds lines to /boot/config/go and /boot/config/stop for clean start up and stop with the machine 
- it then adds this script to userscript plugin directory so it can be used from the gui instead of re running the command for updates or failures
- finally it runs the slackware file we made earlier and starts the tailscaled service using our persisted tailscale state file 
- when a new tailscale version is released you can either rerun the above command or run from userscripts gui
