#!/bin/bash

echo "Giving ES time to start..."
until curl -sS "http://$ES_HOST:$ES_PORT/_cluster/health?wait_for_status=yellow" > /dev/null 2>&1
do
    echo "Waiting for ES to start"
    sleep 1
done
echo
echo "ES started..."

# set runtime environment variables
export MOLOCH_LOCALELASTICSEARCH=no
export MOLOCH_ELASTICSEARCH="http://"$ES_HOST":"$ES_PORT

if [ ! -f $ARKIMEDIR/etc/.initialized ]; then
    echo $ARKIME_VERSION > $ARKIMEDIR/etc/.initialized
    echo $MOLOCH_LOCALELASTICSEARCH | $ARKIMEDIR/bin/Configure
    echo INIT | $ARKIMEDIR/db/db.pl http://$ES_HOST:$ES_PORT init
    $ARKIMEDIR/bin/moloch_add_user.sh admin "Admin User" $ARKIME_ADMIN_PASSWORD --admin
else
    # possible update
    read old_ver < $ARKIMEDIR/etc/.initialized
    # detect the newer version
    newer_ver=`echo -e "$old_ver\n$ARKIME_VERSION" | sort -rV | head -n 1`
    # the old version should not be the same as the newer version
    # otherwise -> upgrade
    if [ "$old_ver" != "$newer_ver" ]; then
        echo "Upgrading ES database..."
        echo $MOLOCH_LOCALELASTICSEARCH | $ARKIMEDIR/bin/Configure
        echo UPGRADE | $ARKIMEDIR/db/db.pl http://$ES_HOST:$ES_PORT upgrade
        echo $ARKIME_VERSION > $ARKIMEDIR/etc/.initialized
    fi
fi

# start cron daemon for logrotate
service cron start

if [ "$CAPTURE" = "on" ]
then
    echo "Launch capture..."
    if [ "$VIEWER" = "on" ]
    then
        # Background execution
        exec $ARKIMEDIR/bin/moloch-capture --config $ARKIMEDIR/etc/config.ini --host $ARKIME_HOSTNAME >> $ARKIMEDIR/logs/capture.log 2>&1 &
    else
        # If only capture, foreground execution
        exec $ARKIMEDIR/bin/moloch-capture --config $ARKIMEDIR/etc/config.ini --host $ARKIME_HOSTNAME >> $ARKIMEDIR/logs/capture.log 2>&1
    fi
fi

echo "Look at log files for errors"
echo "  /data/moloch/logs/viewer.log"
echo "  /data/moloch/logs/capture.log"
echo "Visit http://127.0.0.1:8005 with your favorite browser."
echo "  user: admin"
echo "  password: $ARKIME_ADMIN_PASSWORD"

if [ "$VIEWER" = "on" ]
then
    echo "Launch viewer..."
    pushd $ARKIMEDIR/viewer
    exec $ARKIMEDIR/bin/node $ARKIMEDIR/viewer/viewer.js -c $ARKIMEDIR/etc/config.ini --host $ARKIME_HOSTNAME >> $ARKIMEDIR/logs/viewer.log 2>&1
    popd
fi
