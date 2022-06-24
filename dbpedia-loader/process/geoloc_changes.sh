#!/usr/bin/env bash
. ../virtuoso_fct.sh --source-only
limit=500000;

echo "=============> GEOLOC CHANGES NEW 5"

nb_last=0
nb_new=1
echo "=============> NB TODO : $nb_todo";
while [ $nb_new -gt $nb_last ];
    do

 ################### SPARQL - ADD BLANK NODE FOR EACH RELATED PLACE
     resp_update=$(run_virtuoso_cmd "SPARQL \
     WITH <http://fr.dbpedia.org/graph/dbpedia_generic_geo-coordinates> \
     DELETE {  ?s ?p ?o. \
     } \
     INSERT { ?s dbo:relatedPlaces [ \
        ?p ?o \
     ]. \ 
     } \
    WHERE { \
     SELECT ?s ?p ?o
     FROM <http://fr.dbpedia.org/graph/dbpedia_generic_geo-coordinates> \
     WHERE { \
     ?s ?p ?o.
     FILTER( ?p != dbo:relatedPlaces) \
     } LIMIT $limit \
     } ;");
     
     
     nb_last=$nb_new;
     echo "=============> update";
     resp_georelated2=$(run_virtuoso_cmd "SPARQL SELECT COUNT(?s) FROM <http://fr.dbpedia.org/graph/dbpedia_generic_geo-coordinates> WHERE {?s dbo:relatedPlaces ?o. } ;");
     nb_new=$(get_answer_nb "$resp_georelated2");
     echo "=============>  $nb_new > $nb_last ?";
done

