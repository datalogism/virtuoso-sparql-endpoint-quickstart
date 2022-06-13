. ../virtuoso_fct.sh --source-only

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
        resp=$(run_virtuoso_cmd "SPARQL\
        SELECT COUNT(?d) FROM <${DOMAIN}/graph/metadata> WHERE {\
        ?s prov:wasGeneratedAtTime ?d.\
        FILTER(?s = <${DOMAIN}/graph/${final_name}> )\
        } ;") 
        nb=$(echo $resp | awk '{print $4}')
        if [ "$nb" -eq "0" ];then
        
        ###################  SPARQL - INSERT DATE PUBLICATION
           run_virtuoso_cmd "SPARQL \
           INSERT INTO <${DOMAIN}/graph/metadata> {  <${DOMAIN}/graph/${final_name}> prov:wasGeneratedAtTime '${date}'^^xsd:date .\
           <${DOMAIN}/graph/${final_name}>  schema:datePublished '${date}'^^xsd:date .\
           };"
        fi
        ###################  SPARQL - INSERT DUMP FILE NAME
        run_virtuoso_cmd "SPARQL \
        INSERT INTO <${DOMAIN}/graph/metadata> {  <${DOMAIN}/graph/${final_name}> void:dataDump <http://prod-dbpedia.inria.fr/dumps/lastUpdate/$fn> };"
        fi
    fi;
done

## CREATE SUBGRAPHS
run_virtuoso_cmd "DB.DBA.RDF_GRAPH_GROUP_CREATE ('${DOMAIN}',1);"
run_virtuoso_cmd "DB.DBA.RDF_GRAPH_GROUP_INS ('${DOMAIN}','${DOMAIN}/graph/metadata');"


echo "[INFO] ADD META DATA"
run_virtuoso_cmd "DB.DBA.TTLP_MT (file_to_string_output ('${STORE_DATA_DIR}/meta_base/dbpedia_fr-metadata.ttl'), '', '${DOMAIN}/graph/metadata');" 
