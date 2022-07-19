#!/usr/bin/env bash

. ./virtuoso_fct.sh --source-only

#### PROCESS COMMANDS 
if [ -z ${PROCESS_STRUCTURE+x} ]; then PROCESS_STRUCTURE=1; fi
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
echo "> PROCESS_STRUCTURE : ${PROCESS_STRUCTURE}";
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
if [ $PROCESS_STRUCTURE == 1 ] ; then
   echo ">>> PROCESS_STRUCTURE unabled"
   /bin/bash ./process/structure_process.sh
else
   echo ">>> PROCESS_STRUCTURE disabled"
fi

############## VIRTUOSO CONFIG
echo "[INFO] Setting 'dbp_decode_iri' registry entry to 'on'"
run_virtuoso_cmd "registry_set ('dbp_decode_iri', 'on');"
echo "[INFO] Setting dynamic !!!!"
run_virtuoso_cmd "registry_set ('dbp_DynamicLocal', 'on');"
run_virtuoso_cmd "registry_set ('dbp_lhost', ':8890');"
run_virtuoso_cmd "registry_set ('dbp_vhost', '${DOMAIN}');"
echo "[INFO] Setting 'dbp_domain' registry entry to ${DOMAIN}"
run_virtuoso_cmd "registry_set ('dbp_domain', '${DOMAIN}');"
echo "[INFO] Setting 'dbp_graph' registry entry to ${DOMAIN}"
run_virtuoso_cmd "registry_set ('dbp_graph', '${DOMAIN}');"
echo "[INFO] Setting 'dbp_lang' registry entry to ${DBP_LANG}"
run_virtuoso_cmd "registry_set ('dbp_lang', '${DBP_LANG}');"
echo "[INFO] Setting 'dbp_category' registry entry to ${DBP_CATEGORY}"
run_virtuoso_cmd "registry_set ('dbp_category', '${DBP_CATEGORY}');"

################ INSTALL LAST DBPEDIA VAD
echo "[INFO] Installing VAD package 'dbpedia_dav.vad'"
run_virtuoso_cmd "vad_install('/opt/virtuoso-opensource/vad/dbpedia_dav.vad', 0);"
echo "[INFO] Installing VAD package 'fct_dav.vad'"
run_virtuoso_cmd "vad_install('/opt/virtuoso-opensource/vad/fct_dav.vad', 0);"

##### HERE WE CHANGE THE DEFAULT BEHAVIOR OF THE DESCRIBE
# see https://community.openlinksw.com/t/how-to-change-default-describe-mode-in-faceted-browser/1691/3
run_virtuoso_cmd "INSERT INTO DB.DBA.SYS_SPARQL_HOST VALUES ('*',null,null,null,'DEFINE sql:describe-mode \"CBD\"');"

#### DATA IMPORT PLACE

echo "[INFO] deactivating auto-indexing"
run_virtuoso_cmd "DB.DBA.VT_BATCH_UPDATE ('DB.DBA.RDF_OBJ', 'ON', NULL);"

echo '[INFO] Starting load process...';

load_cmds=`cat <<EOF
log_enable(2);
checkpoint_interval(-1);
set isolation = 'uncommitted';
rdf_loader_run();
log_enable(1);
checkpoint_interval(60);
EOF`
run_virtuoso_cmd "$load_cmds";

run_virtuoso_cmd "log_enable(2)";
run_virtuoso_cmd "checkpoint_interval(-1)";


############## CHANGE GEOLOC COORD FROM TRIPLE TO BLANK NODE
if [ $PROCESS_GEOLOC == 1 ] ; then
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
if [ $PROCESS_STATS == 1 ] ; then
   echo ">>> PROCESS_STATS unabled"
   /bin/bash ./process/dumps_export.sh
else
   echo ">>> PROCESS_STATS disabled"
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
