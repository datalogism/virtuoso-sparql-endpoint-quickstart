#!/usr/bin/env bash
. ../virtuoso_fct.sh --source-only

limit=500000;

echo "============ multilingual_labels2.sh V1 "
################### SPARQL - GET LANG LIST
resp=$(run_virtuoso_cmd "SPARQL SELECT DISTINCT CONCAT('lang_',?lang) FROM <http://fr.dbpedia.org/graph/dbpedia_generic_labels> where { ?s rdfs:label ?o. BIND (lang(?o) AS ?lang) };";);
echo $resp;
lang_list=$(echo $resp | tr " " "\n" | grep -oP "lang_\K(.*)");
graph_list=("http://fr.dbpedia.org/graph/dbpedia_generic_interlanguage-links" "http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-all-wikis")

for lang in ${lang_list[@]}; do
	if [[ $lang != 'fr' ]]; then
		echo "============>>>>>>>>>> $lang need to be treaten"; 

		Lang="${lang[@]^}"
		nb_global=1;
		last=0;

		while [ $nb_global -ne $last ]
		do
			last=$nb_global;
			for graph in ${graph_list[@]}; do
				echo ">>>>>>>>>> GRAPH : $graph"; 
				 ################### SPARQL - FLAG  WIKILINKS FOUND
				resp_wikilinks_flag=$(run_virtuoso_cmd "SPARQL DEFINE sql:log-enable 2 WITH <http://fr.dbpedia.org/graph/dbpedia_generic_labels> INSERT { ?s_lang rdf:type dbo:${Lang}FrResource. } WHERE {SELECT ?s_lang FROM <http://fr.dbpedia.org/graph/dbpedia_generic_labels>  WHERE {?s_lang rdfs:label ?o_lang. FILTER NOT EXISTS { ?s_lang rdf:type dbo:${Lang}FrResource }. FILTER(lang(?o_lang)='$lang'). {SELECT ?s_fr ?s_lang FROM <$graph> WHERE { ?s_fr owl:sameAs ?s_lang } } } LIMIT $limit };");
			done
			
			resp_count=$(run_virtuoso_cmd "SPARQL \
			SELECT COUNT(?s) \
			FROM  <http://fr.dbpedia.org/graph/dbpedia_generic_labels> \
			WHERE { ?s rdf:type dbo:${Lang}FrResource. };");    
			nb_global=$(get_answer_nb "$resp_count");
			echo ">>> nb flags : $nb_global";
		done
	fi 
done
