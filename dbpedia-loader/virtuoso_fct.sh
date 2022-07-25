#!/usr/bin/env bash

bin="isql-vt"
host="store"
port=$STORE_ISQL_PORT
user="dba"

run_virtuoso_cmd () {
 NB_TRY=3
 for i in {1..$NB_TRY}
  do
   VIRT_OUTPUT=`echo "$1" | "$bin" -H "$host" -S "$port" -U "$user" -P "$STORE_DBA_PASSWORD" 2>&1`
   VIRT_RETCODE=$?
   if [[ $VIRT_RETCODE -eq 0 ]]; then
     echo "$VIRT_OUTPUT" | tail -n+5 | perl -pe 's|^SQL> ||g'
     i=$NB_TRY
     return 0
   else
     echo -e "[ERROR] running the these commands in virtuoso:\n$1\nerror code: $VIRT_RETCODE\noutput:"
     echo "$VIRT_OUTPUT"
     #let 'ret = VIRT_RETCODE + 128'
     #return 0
   fi
  done
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
   fi
   if ! [[ $nb =~ $re ]] ; then
        nb=$(echo $resp | grep -o -P '(?<=\n\s)\d*(?=\n\s)');
   fi
   if ! [[ $nb =~ $re ]] ; then
     echo "$resp";
   fi
   echo "$nb";
}

proc_dump="CREATE PROCEDURE dump_one_graph 
  ( IN  srcgraph           VARCHAR
  , IN  out_file           VARCHAR
  , IN  file_length_limit  INTEGER  := 1000000000
  )
  {
    DECLARE  file_name     VARCHAR;
    DECLARE  env,  ses           ANY;
    DECLARE  ses_len
          ,  max_ses_len
          ,  file_len
          ,  file_idx      INTEGER;
   SET ISOLATION = 'uncommitted';
   max_ses_len  := 10000000;
   file_len     := 0;
   file_idx     := 1;
   file_name    := sprintf ('%s%06d.ttl', out_file, file_idx);
   string_to_file ( file_name || '.graph', 
                     srcgraph, 
                     -2
                   );
    string_to_file ( file_name, 
                     sprintf ( '# Dump of graph <%s>, as of %s\n@base <> .\n', 
                               srcgraph, 
                               CAST (NOW() AS VARCHAR)
                             ), 
                     -2
                   );
   env := vector (dict_new (16000), 0, '', '', '', 0, 0, 0, 0, 0);
   ses := string_output ();
   FOR (SELECT * FROM ( SPARQL DEFINE input:storage \"\" 
                         SELECT ?s ?p ?o { GRAPH `iri(?:srcgraph)` { ?s ?p ?o } } 
                       ) AS sub OPTION (LOOP)) DO
      {
        http_ttl_triple (env, \"s\", \"p\", \"o\", ses);
        ses_len := length (ses);
        IF (ses_len > max_ses_len)
          {
            file_len := file_len + ses_len;
            IF (file_len > file_length_limit)
              {
                http (' .\n', ses);
                string_to_file (file_name, ses, -1);
                gz_compress_file (file_name, file_name||'.gz');
                file_delete (file_name);
                file_len := 0;
                file_idx := file_idx + 1;
                file_name := sprintf ('%s%06d.ttl', out_file, file_idx);
                string_to_file ( file_name, 
                                 sprintf ( '# Dump of graph <%s>, as of %s (part %d)\n@base <> .\n', 
                                           srcgraph, 
                                           CAST (NOW() AS VARCHAR), 
                                           file_idx), 
                                 -2
                               );
                 env := VECTOR (dict_new (16000), 0, '', '', '', 0, 0, 0, 0, 0);
              }
            ELSE
              string_to_file (file_name, ses, -1);
            ses := string_output ();
          }
      }
    IF (LENGTH (ses))
      {
        http (' .\n', ses);
        string_to_file (file_name, ses, -1);
        gz_compress_file (file_name, file_name||'.gz');
        file_delete (file_name);
      }
  }
;";


