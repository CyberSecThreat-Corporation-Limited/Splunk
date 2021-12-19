#!/bin/bash

frozen_path="/mnt/archive"
index_name="wineventlog"
# SPLUNK_DB is defined in $SPLUNK_HOME/etc/splunk-launch.conf
SPLUNK_DB=/opt/splunk/var/lib/splunk/

Request_StartTime="2021-12-31 09:00:00"
Request_EndTime="2021-12-31 10:00:00"
#read -p 'Please enter start time in UTC: e.g. (2021-12-31 09:00:00)' Request_StartTime
#read -p 'Please enter end time in UTC: e.g. (2021-12-31 09:00:00)' Request_EndTime
let Request_Start_TimeStamp=`date -d "$Request_StartTime" +%s`
let Request_End_TimeStamp=`date -d "$Request_EndTime" +%s`

echo $Request_Start_TimeStamp
echo $Request_End_TimeStamp

cd $frozen_path/
for d in */ ; do
        #if [[ "$d" == rb_* ]] || [[ "$d" == db_* ]];then
        if [[ "$d" == db_* ]];then
                #echo "$d"
                let StartTime_TimeStamp=`echo "$d" | cut -f 3 -d '_'`
                let EndTime_TimeStamp=`echo "$d" | cut -f 2 -d '_'`
                Start_TimeStamp=`date -d @$StartTime_TimeStamp`
                End_TimeStamp=`date -d @$EndTime_TimeStamp`
                #echo "$d" $Start_TimeStamp $End_TimeStamp
                
                NeedRestore=0
                if [ $Start_TimeStamp -lt $Request_Start_TimeStamp ] && [ $End_TimeStamp -gt $Request_End_TimeStamp ];then
                        NeedRestore=1
                elif [ $Start_TimeStamp -gt $Request_Start_TimeStamp ] && [ $Start_TimeStamp -lt $Request_End_TimeStamp ];then
                        NeedRestore=1
                elif [ $End_TimeStamp -gt $Request_Start_TimeStamp ] && [ $End_TimeStamp -lt $Request_End_TimeStamp ];then
                        NeedRestore=1
                fi

                if [ "$NeedRestore" -eq 1 ];then
                        echo "$d" $StartTime $EndTime
                        cp -r "$d" $SPLUNK_DB/$index_name/thaweddb/
                        splunk rebuild $SPLUNK_DB/$index_name/thaweddb/$d
                        #splunk restart
                fi
        fi
done

cd $SPLUNK_HOME/bin/
./splunk restart
