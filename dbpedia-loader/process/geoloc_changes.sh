#!/usr/bin/env bash
. ../virtuoso_fct.sh --source-only
limit=500000;

echo "=============> GEOLOC CHANGES NEW 8"

nb_blank=0;
resp_base=$(run_virtuoso_cmd "SPARQL SELECT COUNT(?s) FROM <http://fr.dbpedia.org/graph/dbpedia_generic_geo-coordinates> WHERE { ?s ?p ?o. FILTER( !isBlank(?s) )  . FILTER( !isBlank(?o) ) };");

nb_blank=$(get_answer_nb "$resp_base");
echo "TO DO $nb_blank";

while [ $nb_blank -ne 0 ];
    do

 ################### SPARQL - ADD BLANK NODE FOR EACH RELATED PLACE
     resp_update=$(run_virtuoso_cmd "SPARQL \
     WITH <http://fr.dbpedia.org/graph/dbpedia_generic_geo-coordinates> \
     DELETE {  ?s ?p ?o. } \
     INSERT { ?s dbo:relatedPlaces [ ?p ?o ] . } \
     WHERE { \
      SELECT ?s ?p ?o \
      FROM <http://fr.dbpedia.org/graph/dbpedia_generic_geo-coordinates> \
      WHERE { \
       ?s ?p ?o. \
       FILTER( !isBlank(?s) ). FILTER( !isBlank(?o) ) \
      } LIMIT $limit \
     } ;");
     
     resp_georelated2=$(run_virtuoso_cmd "SPARQL SELECT COUNT(?s) FROM <http://fr.dbpedia.org/graph/dbpedia_generic_geo-coordinates> WHERE { ?s ?p ?o. FILTER( !isBlank(?s) )  . FILTER( !isBlank(?o) ) };");
     nb_blank=$(get_answer_nb "$resp_georelated2");
     echo "=============>  $nb_blank ?";
done

