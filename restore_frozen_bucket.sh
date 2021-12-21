#!/bin/bash

################################################################################################################
#### Please configure the following value before use it:
#### 1. target_restore_index_list
#### 2. Request_StartTime
#### 3. Request_EndTime
#### 4. SPLUNK_DB
#### 5. index_name
#### 6. frozen_path
#### 7. thaweddb_path
################################################################################################################

target_restore_index_list=("wineventlog2" "os" "firewall" "database")

Request_StartTime="2021-12-31 09:00:00"
Request_EndTime="2021-12-31 10:00:00"
#read -p 'Please enter start time in UTC: e.g. (2021-12-31 09:00:00)' Request_StartTime
#read -p 'Please enter end time in UTC: e.g. (2021-12-31 09:00:00)' Request_EndTime
let Request_Start_TimeStamp=`date -d "$Request_StartTime" +%s`
let Request_End_TimeStamp=`date -d "$Request_EndTime" +%s`

# SPLUNK_DB is defined in $SPLUNK_HOME/etc/splunk-launch.conf
SPLUNK_DB=/opt/splunk/var/lib/splunk/

for((i=0; i<${#target_restore_index_list[@]}; i++))
do
        index_name=${target_restore_index_list[i]}
        frozen_path="$SPLUNK_DB/frozen_db/$index_name"
        thaweddb_path="$SPLUNK_DB/$index_name/thaweddb/"
        cd $frozen_path/

        find . -type d -regextype posix-extended -regex ".*?db_[0-9]{10}_[0-9]{10}_[0-9]{1,10}$" -print0 | while read -d $'\0' frozen_bucket_dir
        do
                unset StartTime_TimeStamp
                let StartTime_TimeStamp=`echo "$frozen_bucket_dir" | cut -f 3 -d '_'`
                unset EndTime_TimeStamp
                let EndTime_TimeStamp=`echo "$frozen_bucket_dir" | cut -f 2 -d '_'`
                unset Start_TimeStamp        
                Start_TimeStamp=`date -d @$StartTime_TimeStamp`
                unset End_TimeStamp
                End_TimeStamp=`date -d @$EndTime_TimeStamp`
                #echo "$frozen_bucket_dir" $Start_TimeStamp $End_TimeStamp
                
                NeedRestore=0
                if [ $Start_TimeStamp -lt $Request_Start_TimeStamp ] && [ $End_TimeStamp -gt $Request_End_TimeStamp ];then
                        NeedRestore=1
                elif [ $Start_TimeStamp -gt $Request_Start_TimeStamp ] && [ $Start_TimeStamp -lt $Request_End_TimeStamp ];then
                        NeedRestore=1
                elif [ $End_TimeStamp -gt $Request_Start_TimeStamp ] && [ $End_TimeStamp -lt $Request_End_TimeStamp ];then
                        NeedRestore=1
                fi

                # Only below pattern should exists in frozen bucket:
                #./db_1601220493_1601206411_28
                #./db_1601220493_1601206411_28/rawdata
                #./db_1601220493_1601206411_28/rawdata/journal.gz
                #./db_1601220493_1601206411_28/rawdata/82802000
                IsFrozenDir=0
                if [ `find $frozen_bucket_dir/ -type d | wc -l` -gt 1 ];then
                        unset NumberOfDirs
                        NumberOfDirs=`find $frozen_bucket_dir/* -type d | wc -l`
                        if [ $NumberOfDirs -eq 1 ];then
                                if [ -d "$frozen_bucket_dir/rawdata/" ];then
                                        unset NumberOfFiles
                                        NumberOfFiles=`find $frozen_bucket_dir/* -type f | wc -l`
                                        if [ $NumberOfFiles -eq 1 ];then
                                                if [ -f "$frozen_bucket_dir/rawdata/journal.gz" ];then
                                                        IsFrozenDir=1
                                                fi
                                        elif [ $NumberOfFiles -eq 2 ];then                                                        
                                                if [ -f "$frozen_bucket_dir/rawdata/journal.gz" ];then
                                                        unset SecondFile
                                                        SecondFile=`ls $frozen_bucket_dir/rawdata/ | grep -v journal.gz | grep -e "^[0-9]\{1,20\}$"`
                                                        if [ $SecondFile ];then
                                                                IsFrozenDir=1
                                                        fi
                                                fi
                                        fi
                                fi
                        fi
                fi

                if [[ "$NeedRestore" -eq 1 ]  && [ "$IsFrozenDir" -eq 1 ]];then
                        echo "Restoring $frozen_bucket_dir with bucket time between $StartTime and $EndTime to $thaweddb_path"
                        cp -r "$frozen_bucket_dir" $thaweddb_path
                        splunk rebuild $thaweddb_path/$frozen_bucket_dir
                fi
        done
done

cd $SPLUNK_HOME/bin/
./splunk restart
