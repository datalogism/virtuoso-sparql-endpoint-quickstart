#!/usr/bin/env bash

. ./virtuoso_fct.sh --source-only

#### PROCESS COMMANDS 
if [ -z ${PROCESS_INIT+x} ]; then PROCESS_INIT=1; fi
if [ -z ${PROCESS_GEOLOC+x} ]; then PROCESS_GEOLOC=1; fi
if [ -z ${PROCESS_INTERLINKSAMEAS+x} ]; then PROCESS_INTERLINKSAMEAS=1; fi
if [ -z ${PROCESS_WIKIDATA+x} ]; then PROCESS_WIKIDATA=1; fi
if [ -z ${PROCESS_MULTILANG+x} ]; then PROCESS_MULTILANG=1; fi
if [ -z ${PROCESS_STATS+x} ]; then PROCESS_STATS=1; fi
if [ -z ${PROCESS_DUMPS+x} ]; then PROCESS_DUMPS=1; fi

echo "==========================================";
echo " DBPEDIA LOADER VERSION of 19/07/2022";
echo "==========================================";
echo "------------ Current config ------------";
echo "> PROCESS_INIT: ${PROCESS_INIT}";
echo "> PROCESS_GEOLOC : ${PROCESS_GEOLOC}";
echo "> PROCESS_INTERLINKSAMEAS : ${PROCESS_INTERLINKSAMEAS}";
echo "> PROCESS_WIKIDATA : ${PROCESS_WIKIDATA}";
echo "> PROCESS_MULTILANG : ${PROCESS_MULTILANG}";
echo "> PROCESS_STATS : ${PROCESS_STATS}";
echo "> PROCESS_DUMPS : ${PROCESS_DUMPS}";
echo "==========================================";

# ADD A LOCKER FOR MONITORING THE PROCESS
touch /opt/virtuoso-opensource/database/loader_locker.lck;

if [ -f "/opt/virtuoso-opensource/database/loader_locker.lck" ]; then  
echo "/opt/virtuoso-opensource/database/loader_locker.lck exist "  
else
echo "/opt/virtuoso-opensource/database/loader_locker.lck PB"
fi  


echo "[INFO] Waiting for download to finish..."
wait_for_download

echo "will use ISQL port $STORE_ISQL_PORT to connect"
echo "[INFO] Waiting for store to come online (${STORE_CONNECTION_TIMEOUT}s)"
: ${STORE_CONNECTION_TIMEOUT:=100}
test_connection "${STORE_CONNECTION_TIMEOUT}"
if [ $? -eq 2 ]; then
   echo "[ERROR] store not reachable"
   exit 1
fi

############## CREATE NAMED GRAPH STRUCTURE AND LOAD DATA 
if [ $PROCESS_INIT == 1 ] ; then
   echo ">>> PROCESS_INIT unabled"
   /bin/bash ./process/virtuoso_init.sh
else
   echo ">>> PROCESS_INIT disabled"
fi


run_virtuoso_cmd "log_enable(2)";
run_virtuoso_cmd "checkpoint_interval(-1)";


############## CHANGE GEOLOC COORD FROM TRIPLE TO BLANK NODE
if [ $PROCESS_INIT == 1 ] ; then
   echo ">>> PROCESS_GEOLOC unabled"
   /bin/bash ./process/geoloc_changes.sh
   echo "---checkpoint"
   run_virtuoso_cmd 'checkpoint;'
else
   echo ">>> PROCESS_GEOLOC disabled"
fi

############## DUPLICATE INTERLINK AS SAMEAS
if [ $PROCESS_INTERLINKSAMEAS == 1 ] ; then
   echo ">>> PROCESS_INTERLINKSAMEAS unabled"
   /bin/bash ./process/interlink_to_sameAs.sh
   echo "---checkpoint"
   run_virtuoso_cmd 'checkpoint;'
else
   echo ">>> PROCESS_INTERLINKSAMEAS disabled"
fi

############## PROCESS WIKIDATA
if [ $PROCESS_WIKIDATA == 1 ] ; then
   echo ">>> PROCESS_WIKIDATA unabled"
   /bin/bash ./process/process_wikidata2.sh
   echo "---checkpoint"
   run_virtuoso_cmd 'checkpoint;'
else
   echo ">>> PROCESS_WIKIDATA disabled"
fi

############## MIGRATE EVERY LANGUAGES LABELS TO FR RESOURCES
if [ $PROCESS_MULTILANG == 1 ] ; then
   echo ">>> PROCESS_MULTILANG unabled"
   /bin/bash ./process/multilingual_labels2.sh
   echo "---checkpoint"
   run_virtuoso_cmd 'checkpoint;'
else
   echo ">>> PROCESS_MULTILANG disabled"
fi

############## COMPUTE STATS
if [ $PROCESS_STATS == 1 ] ; then
   echo ">>> PROCESS_STATS unabled"
   /bin/bash ./process/stats_process.sh
   echo "---checkpoint"
   run_virtuoso_cmd 'checkpoint;'
else
   echo ">>> PROCESS_STATS disabled"
fi


############## EXPORT NEW DATASETS
if [ $PROCESS_DUMPS == 1 ] ; then
   echo ">>> PROCESS_DUMPS unabled"
   /bin/bash ./process/dumps_export.sh
else
   echo ">>> PROCESS_DUMPS disabled"
fi

echo "[INFO] making checkpoint..."
run_virtuoso_cmd 'checkpoint;'
echo "[INFO] re-activating auto-indexing"
run_virtuoso_cmd "DB.DBA.RDF_OBJ_FT_RULE_ADD (null, null, 'All');"
run_virtuoso_cmd 'DB.DBA.VT_INC_INDEX_DB_DBA_RDF_OBJ ();'
echo "[INFO] making checkpoint..."
run_virtuoso_cmd 'checkpoint;'
echo "[INFO] update/filling of geo index"
run_virtuoso_cmd 'rdf_geo_fill();'
echo "[INFO] making checkpoint..."
run_virtuoso_cmd 'checkpoint;'
echo "[INFO] bulk load done; terminating loader"
echo "[INFO] update of lookup tables"
run_virtuoso_cmd 'urilbl_ac_init_db();'
run_virtuoso_cmd 's_rank();'
echo "[INFO] End of process"
rm "/opt/virtuoso-opensource/database/loader_locker.lck";
run_virtuoso_cmd 'log_enable(1)';
run_virtuoso_cmd 'checkpoint_interval(60)';
echo "[INFO] LOCKER DELETED... SEE YOU !"
