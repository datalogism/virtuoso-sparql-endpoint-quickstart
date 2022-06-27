#!/usr/bin/env bash

bin="isql-vt"
host="store"
port=$STORE_ISQL_PORT
user="dba"

run_virtuoso_cmd () {
 VIRT_OUTPUT=`echo "$1" | "$bin" -H "$host" -S "$port" -U "$user" -P "$STORE_DBA_PASSWORD" 2>&1`
 VIRT_RETCODE=$?
 if [[ $VIRT_RETCODE -eq 0 ]]; then
   echo "$VIRT_OUTPUT" | tail -n+5 | perl -pe 's|^SQL> ||g'
   return 0
 else
   echo -e "[ERROR] running the these commands in virtuoso:\n$1\nerror code: $VIRT_RETCODE\noutput:"
   echo "$VIRT_OUTPUT"
   let 'ret = VIRT_RETCODE + 128'
   return $ret
 fi
}

wait_for_download() {
  sleep 100
  while [ -f "${DATA_DIR}/download.lck" ]; do
    sleep 1
  done
}

test_connection () {
   if [[ -z $1 ]]; then
       echo "[ERROR] missing argument: retry attempts"
       exit 1
   fi

   t=$1

   run_virtuoso_cmd 'status();'
   while [[ $? -ne 0 ]] ;
   do
       echo -n "."
       sleep 1
       echo $t
       let "t=$t-1"
       if [ $t -eq 0 ]
       then
           echo "timeout"
           return 2
       fi
       run_virtuoso_cmd 'status();'
   done
}
get_answer_nb() {
   re='^[0-9]+$'
   resp=$1;
   if ! [[ $nb =~ $re ]] ; then
       nb=$(echo $resp | awk '{print $4}')
   fi       
   if ! [[ $nb =~ $re ]] ; then
        nb=$(echo $resp |  awk '{print $5}')
   fi
   if ! [[ $nb =~ $re ]] ; then
        nb=$(echo $resp | grep -o -P '(?<=_\s)\d*(?=\s)');
   else
     echo "$resp";
   fi
   echo "$nb";
}



