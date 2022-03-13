#! /bin/bash

cd `dirname $0`
ROOT_PATH=`pwd`"/"

MAIN_PATH=$ROOT_PATH'qiandao_data/'
CONFIG_PATH=$MAIN_PATH'config/'
TEMP_PATH=$MAIN_PATH'temp/'
COOKIES_PATH=$CONFIG_PATH'cookies/'

BARK_STATUS_ON=1
BARK_STATUS_OFF=0
BARK_STATUS_NOW=$BARK_STATUS_ON
BARK_PATH=$CONFIG_PATH'bark/'
BARK_FILE=$BARK_PATH'bark.txt'
BARK_GROUP_NAME='%E8%87%AA%E5%8A%A8%E7%AD%BE%E5%88%B0'

LOG_PATH=$MAIN_PATH'logs/'
MAIN_LOG_PATH=$LOG_PATH'main/'
LOG_MAX_LINE_COUNT=10000
LOG_TYPE_MAIN=0
LOG_TYPE_BAIDU=1
LOG_LEVEL_INFO='INFO'
LOG_LEVEL_WARN='WARN'
LOG_LEVEL_ERROR='ERROR'

if [ ! -d $MAIN_PATH ];then
  mkdir $MAIN_PATH
fi
if [ ! -d $CONFIG_PATH ];then
  mkdir $CONFIG_PATH
fi
if [ ! -d $TEMP_PATH ];then
  mkdir $TEMP_PATH
fi
if [ ! -d $LOG_PATH ];then
  mkdir $LOG_PATH
fi

if [ ! -d $COOKIES_PATH ];then
  mkdir $COOKIES_PATH
fi
if [ ! -d $BARK_PATH ];then
  mkdir $BARK_PATH
fi
if [ ! -d $MAIN_LOG_PATH ];then
  mkdir $MAIN_LOG_PATH
fi

function log() {
    # $1: log type
    # $2: log level
    # %3: log content
    if [ 3 -gt $# ]
    then
        echo "WARN parameter not correct in log function!"
        return;
    fi
    log_path=''
    log_file=''
    if [ $1 == $LOG_TYPE_BAIDU"," ]
    then
        log_path=$BAIDU_LOG_PATH
    elif [ $1 == $LOG_TYPE_MAIN"," ]
    then
        log_path=$MAIN_LOG_PATH
    else
        echo "WARN log type not correct in log function!"
        return;
    fi

    log_file=$log_path"log.out"

    if [ ! -e $log_file ];then
        touch $log_file
    fi
    local curtime
    curtime=`date +"%Y-%m-%d_%H:%M:%S"`
    local cursize
    cursize=`cat $log_file | wc -c`
    if [ $LOG_MAX_LINE_COUNT -lt $cursize ];then
        mv $log_file $log_path$curtime".log"
        touch $log_file
    fi
    # echo "$curtime $2 $3"
    echo "$curtime $2 $3" | tee -a $log_file
}   

if [ ! -f $BARK_FILE ];then
    BARK_STATUS_NOW=$BARK_STATUS_OFF
    log $LOG_TYPE_MAIN, $LOG_LEVEL_WARN, "找不到Bark配置，本次签到关闭Bark功能"
fi

function bark() {
    # $1: bark title
    # $2: bark content
    if [ "$BARK_STATUS_NOW" == "$BARK_STATUS_ON" ]
    then
        BARK_URL=`cat $BARK_FILE`
        title=`echo $1`
        title=${title%,*}
        content=`echo $2`
        group_name=`echo $BARK_GROUP_NAME`
        BARK_URL=${BARK_URL}$title"/"$content"?group=$group_name"
        # echo $BARK_URL
        bark_result=`curl $BARK_URL -s`
        log $LOG_TYPE_MAIN, $LOG_LEVEL_INFO, "BARK推送成功，服务器返回结果：$bark_result，推送内容：$*"
    fi
}


# -------------------------------
# Title: Baidu Tieba
# Auther: Rian Ng
# Data: 2021.08.24
# -------------------------------

BAIDU_TEMP_PATH=$TEMP_PATH'baidu/'
BAIDU_LOG_PATH=$LOG_PATH'baidu/'
BAIDU_COOKIE_FILE=$COOKIES_PATH'baidu.txt'

if [ ! -d $BAIDU_TEMP_PATH ];then
    mkdir $BAIDU_TEMP_PATH
fi
if [ ! -d $BAIDU_LOG_PATH ];then
    mkdir $BAIDU_LOG_PATH
fi
if [ ! -f $BAIDU_COOKIE_FILE ];then
    log $LOG_TYPE_BAIDU, $LOG_LEVEL_ERROR, "找不到Cookie文件，退出本次签到"
    exit 1
fi

GET_BARS_URL='http://tieba.baidu.com/f/like/mylike'
SIGN_URL='http://tieba.baidu.com/sign/add'
COOKIE=`cat $BAIDU_COOKIE_FILE`
SIGN_RESULT_CODE_SUCCESS=0
SIGN_RESULT_CODE_HAS_DONE=1101

log $LOG_TYPE_BAIDU, $LOG_LEVEL_INFO, "正在开始签到"
log $LOG_TYPE_BAIDU, $LOG_LEVEL_INFO, "正在获取关注列表"

bar_original_data=`curl $GET_BARS_URL -H "Cookie:$COOKIE" -H "DNT:1" -H "Accept-Language:zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7" -H "User-Agent:LogStatistic" -H "Accept:text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9" -H "Connection:keep-alive" -H "Host:tieba.baidu.com" -H "Upgrade-Insecure-Requests:1" -s |iconv -f gb2312 -t utf-8//TRANSLIT`

echo $bar_original_data |grep -Eo 'href="/f\?kw=[^"]+" title="([^"]+)"' > ${BAIDU_TEMP_PATH}bar_data.txt
echo $bar_original_data |grep -Eo 'href="/f/like/mylike\?&pn=[^"]' > ${BAIDU_TEMP_PATH}bar_pages.txt

bar_last_page=`cat ${BAIDU_TEMP_PATH}bar_pages.txt`
bar_last_page=${bar_last_page##*=}

for i in `seq 2 $bar_last_page`
do
    bar_original_data=`curl $GET_BARS_URL"?&pn=$i" -H "Cookie:$COOKIE" -H "DNT:1" -H "Accept-Language:zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7" -H "User-Agent:LogStatistic" -H "Accept:text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9" -H "Connection:keep-alive" -H "Host:tieba.baidu.com" -H "Upgrade-Insecure-Requests:1" -s |iconv -f gb2312 -t utf-8//TRANSLIT`
    echo $bar_original_data |grep -Eo 'href="/f\?kw=[^"]+" title="([^"]+)"' >> ${BAIDU_TEMP_PATH}bar_data.txt
    
done


sign_count=0
sign_fail_count=0
log_content=''
while read bar_data
do  
    let sign_count+=1
    bar_kw=`echo $bar_data |grep -Eo '=[^"]+'`
    bar_kw=`echo ${bar_kw#*=}`
    bar_title=`echo $bar_data |grep -Eo 'title="[^"]+'`
    bar_title=${bar_title#*\"}
    bar_sign_url=$SIGN_URL
    bar_sign_data="ie=utf-8&kw=$bar_title"

    bar_sign_result=`curl -d "$bar_sign_data"  $bar_sign_url -X POST -H "Cookie:$COOKIE" -H "DNT:1" -H "Accept-Language:zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7" -H "User-Agent:LogStatistic" -H "Accept:application/json, text/javascript, */*; q=0.01" -H "Connection:keep-alive" -H "Host:tieba.baidu.com" -H "Upgrade-Insecure-Requests:1" -s |iconv -f gb2312 -t utf-8//TRANSLIT`

    bar_sign_result=`echo -e $bar_sign_result`
    # echo $bar_sign_result

    bar_sign_result_code=${bar_sign_result#*:}
    bar_sign_result_code=${bar_sign_result_code%%,*}
    # echo $bar_sign_result

    if (("${bar_sign_result_code}" == "${SIGN_RESULT_CODE_HAS_DONE}")); then
        log $LOG_TYPE_BAIDU, $LOG_LEVEL_INFO, $bar_title" 已签到"
    elif (("${bar_sign_result_code}" == "${SIGN_RESULT_CODE_SUCCESS}")); then
        log $LOG_TYPE_BAIDU, $LOG_LEVEL_INFO, $bar_title" 签到完成"
    else
        let sign_fail_count+=1
        log $LOG_TYPE_BAIDU, $LOG_LEVEL_WARN, $bar_title" 签到失败 "$bar_sign_data" "$bar_sign_result
    fi
    
done < ${BAIDU_TEMP_PATH}bar_data.txt


log $LOG_TYPE_BAIDU, $LOG_LEVEL_INFO, "共签到 $sign_count 个，签到失败 $sign_fail_count 个"


# bark "签到统计", "百度贴吧：共签到$sign_count个，签到失败$sign_fail_count个。\n\n`date +"%Y-%m-%d_%H:%M:%S"`"
bark "%E7%AD%BE%E5%88%B0%E7%BB%9F%E8%AE%A1", "%E7%99%BE%E5%BA%A6%E8%B4%B4%E5%90%A7%EF%BC%9A%E5%85%B1%E7%AD%BE%E5%88%B0$sign_count%E4%B8%AA%EF%BC%8C%E7%AD%BE%E5%88%B0%E5%A4%B1%E8%B4%A5$sign_fail_count%E4%B8%AA%E3%80%82%0A%0A`date +"%Y-%m-%d_%H:%M:%S"`"
