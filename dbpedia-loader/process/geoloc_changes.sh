#!/usr/bin/env bash
. ../virtuoso_fct.sh --source-only
limit=500000;

echo "=============> GEOLOC CHANGES NEW 6"

nb_blank=0;
echo "=============> NB TODO : $nb_todo";
resp_base=$(run_virtuoso_cmd "SPARQL \
SELECT count(DISTINCT ?s) FROM <http://fr.dbpedia.org/graph/dbpedia_generic_geo-coordinates> WHERE {\
?s ?p ?o. \
};");

nb_base=$(get_answer_nb "$resp_base");
echo "TO DO $resp_base";
while [ $nb_base -ne $nb_blank ];
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
     
     resp_georelated2=$(run_virtuoso_cmd "SPARQL SELECT COUNT(DISTINCT ?s) FROM <http://fr.dbpedia.org/graph/dbpedia_generic_geo-coordinates> WHERE {?s dbo:relatedPlaces ?o. } ;");
     nb_blank=$(get_answer_nb "$resp_georelated2");
     echo "=============>  $nb_blank ?";
done

