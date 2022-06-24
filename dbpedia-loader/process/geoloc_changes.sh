#!/usr/bin/env bash
. ../virtuoso_fct.sh --source-only
limit=500000;

echo "=============> GEOLOC CHANGES NEW 3"

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
         <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ?type; \
         <http://www.georss.org/georss/point> ?point; \
         <http://www.w3.org/2003/01/geo/wgs84_pos#lat> ?lat; \
         <http://www.w3.org/2003/01/geo/wgs84_pos#long> ?long; \
         <http://www.w3.org/2003/01/geo/wgs84_pos#geometry> ?geo; \
     ]. \ 
     } \
    WHERE { \
     SELECT ?s ?p ?o ?type ?geo ?lat ?long ?point \
     FROM <http://fr.dbpedia.org/graph/dbpedia_generic_geo-coordinates> \
     WHERE { \
     ?s <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ?type . \
     OPTIONAL{ ?s <http://www.georss.org/georss/point> ?point .} \
     OPTIONAL { ?s <http://www.w3.org/2003/01/geo/wgs84_pos#lat> ?lat.} \
     OPTIONAL { ?s <http://www.w3.org/2003/01/geo/wgs84_pos#long> ?long.} \
     OPTIONAL { ?s <http://www.w3.org/2003/01/geo/wgs84_pos#geometry> ?geo.} \
     } LIMIT $limit \
     } ;");
     
     
     nb_last=$nb_new;
     echo "=============> update";
     resp_georelated2=$(run_virtuoso_cmd "SPARQL SELECT COUNT(?s) FROM <http://fr.dbpedia.org/graph/dbpedia_generic_geo-coordinates> WHERE {?s dbo:relatedPlaces ?o. } ;");
     nb_new=$(get_answer_nb "$resp_georelated2");
     echo "=============> NB TODO : $nb_todo";
done

