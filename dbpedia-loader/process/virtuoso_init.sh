#!/usr/bin/env bash
. ../virtuoso_fct.sh --source-only

echo " >>>>>> structure_process : last fix 06/06/2022"
pat1='.*\.(nt|nq|owl|rdf|trig|ttl|xml|gz|bz2)$' # IF ENDING BY ACCEPTED EXTENSIONS
pat2='([a-z\-]+)_'
pat3='.*\.bz2$'
pat4='metadata'

for entry in "${DATA_DIR}"/*
do
  echo "$entry";
  level1="";
  level2="";
  level3="";
  if [[ $entry =~ $pat1 ]]
  then
    fn=${entry##*/} # GET FILE NAME ONLY
    echo "$fn"
    if [[ $entry =~ $pat2 ]]; then
        level1="${BASH_REMATCH[1]}";
        entry1=$(echo $entry | sed "s+${BASH_REMATCH[0]}++g");
        if [[ $entry1 =~ $pat2 ]]; then
         level2="${BASH_REMATCH[1]}";
         entry2=$(echo $entry1 | sed "s+${BASH_REMATCH[0]}++g");

            if [[ $entry2  =~ $pat2 ]]; then
            level3="${BASH_REMATCH[1]}";
            fi;
        fi;
    fi;
  fi
  if [[ $level1 != "" ]] && [[ $level2 != "" ]] && [[ $level3 != "" ]]; then
     echo "found pattern so construct graph name";
     if [[ $level1 == "vehnem" ]] && [[ $level2 == "replaced-iris" ]]; then
        level1="dbpedia";
     fi
     if [[ $level1 == "vehnem" ]] && [[ $level2 == "yago" ]]; then
        level1="outlinks";
     fi
     if [[ $level1 == "ontologies" ]]; then
        level1="dbpedia";
        level2="ontology";
        level3="";
     fi

     if [[ "$level1" != "" ]]; then
             final_name="${level1}";
     fi
     if [[ "$level2" != "" ]]; then
             final_name="${level1}_${level2}";
     fi
     if [[ "$level3" != "" ]]; then
             final_name="${level1}_${level2}_${level3}";
     fi
     echo "> final name is : ${final_name}"
     
     run_virtuoso_cmd "DB.DBA.RDF_GRAPH_GROUP_INS ('${DOMAIN}','${DOMAIN}/graph/${final_name}');"
     run_virtuoso_cmd "ld_dir ('${STORE_DATA_DIR}', '${fn}', '${DOMAIN}/graph/${final_name}');"
     
    if  [[ $entry =~ $pat3 ]] &&  [[ ! $entry =~ $pat4 ]]; then
        # count nb lines and get date of prod
     
        date=$(echo $entry  | grep -Eo '[[:digit:]]{4}.[[:digit:]]{2}.[[:digit:]]{2}');  
        ################### SPARQL - GET NUMBER OF DATASET FROM DATE IF SUM NEEDED
        resp=$(run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#>  PREFIX prov: <http://www.w3.org/ns/prov#> \
        SELECT COUNT(?d) FROM <${DOMAIN}/graph/metadata> WHERE {\
        ?s prov:wasGeneratedAtTime ?d.\
        FILTER(?s = <${DOMAIN}/graph/${final_name}> )\
        } ;") 
           
        nb=$(get_answer_nb "$resp");
        if [ "$nb" -eq "0" ];then
        
        ###################  SPARQL - INSERT DATE PUBLICATION
           run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#>  PREFIX prov: <http://www.w3.org/ns/prov#> PREFIX schema: <http://schema.org/> \
           INSERT INTO <${DOMAIN}/graph/metadata> {  <${DOMAIN}/graph/${final_name}> prov:wasGeneratedAtTime '${date}'^^xsd:date .\
           <${DOMAIN}/graph/${final_name}>  schema:datePublished '${date}'^^xsd:date .\
           };"
        fi
        ###################  SPARQL - INSERT DUMP FILE NAME
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#>  PREFIX prov: <http://www.w3.org/ns/prov#> \
        INSERT INTO <${DOMAIN}/graph/metadata> {  <${DOMAIN}/graph/${final_name}> void:dataDump <http://prod-dbpedia.inria.fr/dumps/lastUpdate/$fn> };"
        fi
    fi;
done

## CLEAN METADATA GRAPH
resp=$(run_virtuoso_cmd "SPARQL DROP GRAPH <${DOMAIN}/graph/metadata>;");
## CREATE SUBGRAPHS
run_virtuoso_cmd "DB.DBA.RDF_GRAPH_GROUP_CREATE ('${DOMAIN}',1);"
run_virtuoso_cmd "DB.DBA.RDF_GRAPH_GROUP_INS ('${DOMAIN}','${DOMAIN}/graph/metadata');"


echo "[INFO] ADD META DATA"
run_virtuoso_cmd "DB.DBA.TTLP_MT (file_to_string_output ('${STORE_DATA_DIR}/meta_base/dbpedia_fr-metadata.ttl'), '', '${DOMAIN}/graph/metadata');" 


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


run_virtuoso_cmd "${proc_dump}";
