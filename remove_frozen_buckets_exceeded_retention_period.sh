#!/bin/bash

[ "$#" -ne 2 ] && echo "Usage: <frozen_path> <Retention in seconds from now>" && exit 1

frozen_path="$1"
retention_in_seconds="$2"

Current_TimeStamp=`date +%s`
let Target_Remove_Frozen_TimeStamp=$Current_TimeStamp-$retention_in_seconds
#let Target_Remove_Frozen_TimeStamp=$Current_TimeStamp-39744000
#echo $Target_Remove_Frozen_TimeStamp
if [ -d $frozen_path/ ];then
        cd $frozen_path/
        find . -type d -regextype posix-extended -regex ".*?[rd]b_[0-9]{10}_[0-9]{10}_[0-9]{1,10}$" -print0 | while read -d $'\0' frozen_bucket_dir
        do
                unset StartTime_TimeStamp
                let StartTime_TimeStamp=`echo "$frozen_bucket_dir" | cut -f 3 -d '_'`
                unset EndTime_TimeStamp
                let EndTime_TimeStamp=`echo "$frozen_bucket_dir" | cut -f 2 -d '_'`
                if [ $EndTime_TimeStamp -lt $Target_Remove_Frozen_TimeStamp ];then
                        unset StartTime
                        StartTime=`date -d @$StartTime_TimeStamp`
                        unset EndTime
                        EndTime=`date -d @$EndTime_TimeStamp`
                                                
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

                        if [ "$IsFrozenDir" -eq 1 ];then
                                #echo "`date` : $frozen_bucket_dir $StartTime $EndTime will be removed" >> $SPLUNK_HOME/var/log/del_frozen.log
                                /bin/rm -rf $frozen_bucket_dir
                        fi
                fi
        done
else
        echo "$frozen_path does not exists!!"
fi