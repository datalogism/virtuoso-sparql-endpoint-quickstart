#!/usr/bin/env bash
. ../virtuoso_fct.sh --source-only
limit=500000;

echo "=============> GEOLOC CHANGES"
resp_georelated=$(run_virtuoso_cmd "SPARQL \
SELECT count(?o) FROM <http://fr.dbpedia.org/graph/dbpedia_generic_geo-coordinates> WHERE {\
?s ?p ?o. FILTER (!isBlank(?o))\
};");

nb_todo=$(get_answer_nb "$resp_georelated");

echo "=============> NB TODO : $nb_todo";
while [ $nb_todo -ne 0 ];
    do

 ################### SPARQL - ADD BLANK NODE FOR EACH RELATED PLACE
     resp_update=$(run_virtuoso_cmd "SPARQL \
     WITH <http://fr.dbpedia.org/graph/dbpedia_generic_geo-coordinates>\
     INSERT { ?s dbo:relatedPlaces [ \
     <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ?type; \
      <http://www.georss.org/georss/point> ?point; \
      <http://www.w3.org/2003/01/geo/wgs84_pos#lat> ?lat; \
      <http://www.w3.org/2003/01/geo/wgs84_pos#long> ?long; \
     <http://www.w3.org/2003/01/geo/wgs84_pos#geometry> ?geo; \
     ]. \ 
     } \
     DELETE { ?s ?p ?o. } WHERE {\
     SELECT ?s ?type ?geo ?lat ?long ?point \
     FROM <http://fr.dbpedia.org/graph/dbpedia_generic_geo-coordinates> \
     WHERE { \
     ?s ?p ?o. \
     OPTIONAL{ ?s <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ?type .} \
     OPTIONAL{ ?s <http://www.georss.org/georss/point> ?point .} \
     OPTIONAL { ?s <http://www.w3.org/2003/01/geo/wgs84_pos#lat> ?lat.} \
     OPTIONAL { ?s <http://www.w3.org/2003/01/geo/wgs84_pos#long> ?long.} \
     OPTIONAL { ?s <http://www.w3.org/2003/01/geo/wgs84_pos#geometry> ?geo.} \
     } LIMIT $limit \
     } ;");
     
     
     echo "=============> update";
     resp_georelated=$(run_virtuoso_cmd "SPARQL \
     SELECT count(?o) FROM <http://fr.dbpedia.org/graph/dbpedia_generic_geo-coordinates> WHERE {\
     ?s ?p ?o. FILTER (!isBlank(?o))\
     };");
     nb_todo=$(get_answer_nb "$resp_georelated");
     
     echo "=============> NB TODO : $nb_todo";
done

