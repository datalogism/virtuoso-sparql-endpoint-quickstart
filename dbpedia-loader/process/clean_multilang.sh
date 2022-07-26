#!/usr/bin/env bash
. ../virtuoso_fct.sh --source-only

limit=500000;

echo "============>>>>>>>>>> DELETE NOT USED LABELS"; 
resp_count=$(run_virtuoso_cmd "SPARQL SELECT COUNT(?S) FROM <http://fr.dbpedia.org/graph/dbpedia_generic_labels> WHERE { ?S ?p ?o . FILTER NOT EXISTS { ?S a ?t } };" 
nb_todelete=$(get_answer_nb "$resp_count");
while [ $nb_todelete -ne 0 ]
do
	$(run_virtuoso_cmd "SPARQL \
       DEFINE sql:log-enable 2  WITH <http://fr.dbpedia.org/graph/dbpedia_generic_labels> \
       DELETE { ?S ?p ?o. } \
       WHERE {   \
       SELECT ?S ?p ?o FROM <http://fr.dbpedia.org/graph/dbpedia_generic_labels> WHERE { \
       ?S ?p ?o . FILTER NOT EXISTS { ?S a ?t } }  LIMIT $limit }};");
       resp_count=$(run_virtuoso_cmd "SPARQL SELECT COUNT(?S) FROM <http://fr.dbpedia.org/graph/dbpedia_generic_labels> WHERE { ?S ?p ?o . FILTER NOT EXISTS { ?S a ?t } };" 
       nb_todelete=$(get_answer_nb "$resp_count");
done
