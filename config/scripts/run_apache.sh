#!/bin/bash
source /etc/apache2/envvars

if [ -f /var/run/apache2/apache2.pid ]; then
    apachePid=$(cat /var/run/apache2/apache2.pid)
    echo "Found file 'apache2.pid' with pid $apachePid. Let's check if there is a process belonging to it!"
    processName=$(ps -p $apachePid -o comm)

    if [ "$processName" != "apache2" ] && [ "$processName" != "/usr/sbin/apache2 -D FOREGROUND" ]; then
        echo "The found apache.pid is not belonging to an apache-process. I'm going to remove the pid-file."
        rm -f /var/run/apache2/apache2.pid
        echo "Removing of pid-file was successfull."

        echo "For cleaning-reasons I'm also killing all apache-processes."
        killall -9 apache2
        echo "Now this is a safe place again. Enjoy."
      else
        echo "The pid-file is belonging to an apache-process, so it will stay alive."
    fi

    # Disable default Apache site
    bash -c "a2dissite 000-default default-ssl"

    # Enable Existing Apache Sites
    for file in "/etc/apache2/sites-available"; do
        if [ -f "$file" ]; then
            echo "Processing $file ..."
            # Get filename without path
            fullfilename="$file"
            filename=$(basename "$fullfilename")
            # Get filename without extension
            fname="${filename%.*}"
            # Get file extension
            ext="${filename##*.}"
            # Check that file is a .conf
            if [ "$ext" == "conf" ]; then
                # Make sure the file isn't one of the defaults, which shouldn't even exist anyway, since the
                # sites-available directory should be a volume, which means only what we add should be present.
                # But first time container creation has the default site disabled, not removed, for troubleshooting.
                if [ "$fname" != "000-default" && "$fname" != "default-ssl"]; then
                    # Enable the site
                    bash -c "a2ensite $fname"
                fi
            fi
        fi
    done
fi

exec /usr/sbin/apache2 -D FOREGROUND
