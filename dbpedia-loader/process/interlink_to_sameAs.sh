. ../virtuoso_fct.sh --source-only

################### SPARQL - GET ALL THE SAMEAS LINKS
get_named_graph='SPARQL \
SELECT ?o FROM <http://fr.dbpedia.org/graph/metadata> WHERE {\
?s sd:namedGraph ?o.\
FILTER( ?o != <http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-all-wikis> \
AND ?o != <http://fr.dbpedia.org/graph/dbpedia_generic_interlanguage-links>\
AND STRSTARTS(STR(?o), "http://fr.dbpedia.org/graph/dbpedia_wikidata_")\
)\
};'
resp=$(run_virtuoso_cmd "$get_named_graph");
graph_list=$(echo $resp | tr " " "\n" | grep -E "\/graph\/");
echo "> INTERLANG LINKS TRANSFORM TO SAMEAS ";
nbsameAs=0;

################### SPARQL - COUNT INTERLINKS
resp_interlang=$(run_virtuoso_cmd "SPARQL \
SELECT count(?s) FROM <http://fr.dbpedia.org/graph/dbpedia_generic_interlanguage-links> WHERE {\
?s dbo:wikiPageInterLanguageLink ?o \
};");
nb_interlang=$(echo $resp_interlang | awk '{print $4}');
if [ $nb_interlang -ne 0 ]
then
    while [ $nb_interlang -ne $nbsameAs ];
    do

        ################### SPARQL - ADD SAMEAS LINKS FOR EACH INTERLANG
        resp_update=$(run_virtuoso_cmd "SPARQL \
        WITH <http://fr.dbpedia.org/graph/dbpedia_generic_interlanguage-links>\
        INSERT { ?x owl:sameAs ?y } WHERE {\
        SELECT ?x ?y FROM <http://fr.dbpedia.org/graph/dbpedia_generic_interlanguage-links> WHERE {\
        ?x dbo:wikiPageInterLanguageLink ?y.\
        MINUS{ ?x owl:sameAs ?y }\
        } LIMIT $limit \
        } ;");

        ################### SPARQL - COUNT INTERLANG TO TRANSFORM
        resp_sameAs=$(run_virtuoso_cmd "SPARQL\
        SELECT count(?s) FROM <http://fr.dbpedia.org/graph/dbpedia_generic_interlanguage-links> WHERE { \
        ?s owl:sameAs ?o\
        };");
        nbsameAs=$(echo $resp_sameAs | awk '{print $4}');
        echo "$nb_interlang ne $nbsameAs";
    done
fi
