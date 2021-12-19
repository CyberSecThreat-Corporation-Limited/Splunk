#!/bin/bash

#APP-PRD-WEB-001 host=APP-PRD-WEB-001|source=/var/log/app/httpd/www.app.example.com-443/common_log_2021-05-31###1.1.1.2 - - [31/May/2021:11:21:32 +0800] "POST /enquiry/service.htm;jsessionid=khd4E8Mlbdnju8v_zWNQJTkY.node1 HTTP/1.1" 200 89 "-" "MyTestUserAgent (F2; iOS 11.3; iPhone9,2; AppType 0; AppVersion 1.0.0)"

#read ARG1
ARG1=$1

log_header=$(echo $ARG1 | awk '{split($0,a,"###")} END{print a[1]}')
logging_device_hostname=$(echo $log_header | awk '{split($0,a," ")} END{print a[1]}')

logging_device_source=$(echo $log_header | awk '{split($0,a,"|")} END{print a[2]}')
pure_logging_device_source=$(echo $logging_device_source | awk '{split($0,a,"=")} END{print a[2]}')

raw_log=$(echo $ARG1 | awk '{split($0,a,"###")} END{print a[2]}')

DIR=$(dirname "/opt/rsyslog/"$logging_device_hostname$pure_logging_device_source)

if [[ ! -d $DIR ]]; then
	mkdir -p $DIR
fi

if [ "$logging_device_hostname" != "" ] && [ "$pure_logging_device_source" != "" ];then
 echo $raw_log >> "/opt/rsyslog/"$logging_device_hostname$pure_logging_device_source
fi
