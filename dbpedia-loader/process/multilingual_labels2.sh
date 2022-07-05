#!/usr/bin/env bash
. ../virtuoso_fct.sh --source-only

limit=500000;

echo "============ multilingual_labels2.sh V3 "
################### SPARQL - GET LANG LIST
resp=$(run_virtuoso_cmd "SPARQL SELECT DISTINCT CONCAT('lang_',?lang) FROM <http://fr.dbpedia.org/graph/dbpedia_generic_labels> where { ?s rdfs:label ?o. BIND (lang(?o) AS ?lang) };";);
echo $resp;
lang_list=$(echo $resp | tr " " "\n" | grep -oP "lang_\K(.*)");
graph_list=("http://fr.dbpedia.org/graph/dbpedia_generic_interlanguage-links" "http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-all-wikis")

for lang in ${lang_list[@]}; do
	if [[ $lang != 'fr' ]]; then
		echo "============>>>>>>>>>> $lang need to be treaten"; 

		Lang="${lang[@]^}"
		
		echo "============>>>>>>>>>> WIKILINKS";
		nb_global_wlk=1;
		last_wlk=0;
		while [ $nb_global_wlk -ne $last_wlk ]
		do
			last_wlk=$nb_global_wlk;
			resp_wikilinks_flag=$(run_virtuoso_cmd "SPARQL  WITH <http://fr.dbpedia.org/graph/dbpedia_generic_labels> DELETE { ?s_lang rdfs:label ?o_lang. } INSERT { ?s_fr rdf:type dbo:${Lang}FrResource. ?s_fr rdfs:label ?o_lang. }  WHERE {SELECT  ?s_fr ?s_lang ?o_lang  FROM <http://fr.dbpedia.org/graph/dbpedia_generic_labels>  WHERE {?s_lang rdfs:label ?o_lang. {SELECT ?s_fr ?s_lang FROM <http://fr.dbpedia.org/graph/dbpedia_generic_interlanguage-links> WHERE { ?s_fr owl:sameAs ?s_lang } } . FILTER NOT EXISTS { ?s_fr rdf:type  dbo:${Lang}FrResource } . FILTER(lang(?o_lang)='$lang') } LIMIT $limit };");   
			resp_count=$(run_virtuoso_cmd "SPARQL SELECT COUNT(?s_fr) FROM <http://fr.dbpedia.org/graph/dbpedia_generic_labels> WHERE { ?s_fr rdf:type dbo:${Lang}FrResource };");
			nb_global_wlk=$(get_answer_nb "$resp_count");
			echo ">>> nb flags WKL : $nb_global_wlk";
		done
		echo "============>>>>>>>>>> WIKIDATA";
		nb_global_wkd=1;
		last_wkd=0;
		while [ $nb_global_wkd -ne $last_wkd ]
		do
			resp_wikilinks_flag=$(run_virtuoso_cmd "SPARQL  WITH <http://fr.dbpedia.org/graph/dbpedia_generic_labels> DELETE { ?s_lang rdfs:label ?o_lang. } INSERT { ?s_fr rdf:type dbo:${Lang}FrResource. ?s_fr rdfs:label ?o_lang.} WHERE {SELECT  ?s_fr ?s_lang ?o_lang  FROM <http://fr.dbpedia.org/graph/dbpedia_generic_labels>  WHERE {?s_lang rdfs:label ?o_lang. {SELECT ?s_fr ?s_lang FROM <http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-all-wikis> WHERE { ?s_fr owl:sameAs ?s_lang. ?s_fr rdf:type  dbo:frResource } } . FILTER NOT EXISTS { ?s_fr rdf:type  dbo:${Lang}FrResource } . FILTER(lang(?o_lang)='$lang') } LIMIT $limit };");
			resp_count=$(run_virtuoso_cmd "SPARQL SELECT COUNT(?s_fr) FROM <http://fr.dbpedia.org/graph/dbpedia_generic_labels> WHERE { ?s_fr rdf:type dbo:${Lang}FrResource };");
			nb_global_wlk=$(get_answer_nb "$resp_count");
			echo ">>> nb flags WKD : $nb_global_wlk";
		done
		
	fi 
done
