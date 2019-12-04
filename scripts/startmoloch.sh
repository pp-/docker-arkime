#!/bin/bash

echo "Giving ES time to start..."
until curl -sS "http://$ES_HOST:$ES_PORT/_cluster/health?wait_for_status=yellow"
do
    echo "Waiting for ES to start"
    sleep 1
done
echo

if [ ! -f $MOLOCHDIR/etc/.initialized ]; then
    echo $MOLOCH_VERSION > $MOLOCHDIR/etc/.initialized
    $MOLOCHDIR/bin/Configure
    echo INIT | $MOLOCHDIR/db/db.pl http://$ES_HOST:$ES_PORT init
    $MOLOCHDIR/bin/moloch_add_user.sh admin "Admin User" $MOLOCH_ADMIN_PASSWORD --admin
else
    # possible update
    read old_ver < $MOLOCHDIR/etc/.initialized
    # detect the newer version ($MOLOCH_VERSION contains the actual used version)
    newer_ver=`echo -e "$old_ver\n$MOLOCH_VERSION" | sort -rV | head -n 1`
    if [ "$MOLOCH_VERSION" = "$newer_ver" ]; then
        echo "Upgrading ES database..."
        $MOLOCHDIR/bin/Configure
        $MOLOCHDIR/db/db.pl http://$ES_HOST:$ES_PORT upgrade
        echo $MOLOCH_VERSION > $MOLOCHDIR/etc/.initialized
    fi
fi

if [ "$CAPTURE" = "on" ]
then
    echo "Launch capture..."
    if [ "$VIEWER" = "on" ]
    then
        # Background execution
        exec $MOLOCHDIR/bin/moloch-capture >> $MOLOCHDIR/logs/capture.log 2>&1 &
    else
        # If only capture, foreground execution
        exec $MOLOCHDIR/bin/moloch-capture >> $MOLOCHDIR/logs/capture.log 2>&1
    fi
fi

echo "Look at log files for errors"
echo "  /data/moloch/logs/viewer.log"
echo "  /data/moloch/logs/capture.log"
echo "Visit http://127.0.0.1:8005 with your favorite browser."
echo "  user: admin"
echo "  password: $MOLOCH_ADMIN_PASSWORD"

if [ "$VIEWER" = "on" ]
then
    echo "Launch viewer..."
    pushd $MOLOCHDIR/viewer
    exec $MOLOCHDIR/bin/node $MOLOCHDIR/viewer/viewer.js -c $MOLOCHDIR/etc/config.ini >> $MOLOCHDIR/logs/viewer.log 2>&1
    popd
fi
