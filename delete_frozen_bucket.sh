#!/bin/bash

[ "$#" -ne 2 ] && echo "Usage: <frozen_path> <Retention in seconds from now>" && exit 1

frozen_path="$1"
retention_in_seconds="$2"

#SPLUNK_HOME=/opt/splunk
Current_TimeStamp=`date +%s`
let Target_Delete_Frozen_TimeStamp=$Current_TimeStamp-$retention_in_seconds
#let Target_Delete_Frozen_TimeStamp=$Current_TimeStamp-39744000
#echo $Target_Delete_Frozen_TimeStamp
if [ -d $frozen_path/ ];then
cd $frozen_path/
for d in */ ; do
        if [[ "$d" == rb_* ]] || [[ "$d" == db_* ]];then
        #if [[ "$d" == db_* ]];then
                #echo "$d"
                let StartTime_TimeStamp=`echo "$d" | cut -f 3 -d '_'`
                let EndTime_TimeStamp=`echo "$d" | cut -f 2 -d '_'`
                StartTime=`date -d @$StartTime_TimeStamp`
                EndTime=`date -d @$EndTime_TimeStamp`
                #echo "$d" $StartTime $EndTime
                if [ $StartTime_TimeStamp -lt $Target_Delete_Frozen_TimeStamp ];then
                        #echo "`date` : $d $StartTime $EndTime will be deleted" >> $SPLUNK_HOME/var/log/del_frozen.log
                        rm -rf $d
                fi
        fi
done
else
	echo "$frozen_path does not exists"
fi
