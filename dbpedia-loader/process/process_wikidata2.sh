#!/usr/bin/env bash
. ../virtuoso_fct.sh --source-only
limit=500000;
################### SPARQL - GET ALL NAMED WIKIDATA GRAPH
get_named_graph='SPARQL SELECT ?o FROM <http://fr.dbpedia.org/graph/metadata> WHERE { ?s sd:namedGraph ?o. FILTER( ?o != <http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-all-wikis> AND ?o != <http://fr.dbpedia.org/graph/dbpedia_generic_interlanguage-links> AND STRSTARTS(STR(?o), "http://fr.dbpedia.org/graph/dbpedia_wikidata_") ) };'
resp=$(run_virtuoso_cmd "$get_named_graph");
graph_list=$(echo $resp | tr " " "\n" | grep -E "\/graph\/");

echo "> ADD FLAG AND PROPAGATE CHANGE"
count=0;
nb_global=1;
last=0;
while [ $nb_global -ne $last ]
do
    echo "NEW LOOP $nb_global not equals to  $last" ;
    last=$nb_global;
    
    ################### SPARQL - FLAG ALL THE RESOURCE HAVING A FRENCH RESSOURCE LINKED
    resp2=$(run_virtuoso_cmd "SPARQL \
    DEFINE sql:log-enable 2 \
    WITH <http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-all-wikis> \
    INSERT { ?y rdf:type dbo:WdtFrResource. } \
    WHERE { SELECT ?y FROM <http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-all-wikis> \
    WHERE { ?s owl:sameAs ?y. FILTER NOT EXISTS { ?y rdf:type dbo:WdtFrResource }. \
    FILTER(STRSTARTS(STR(?y), 'http://fr.dbpedia.org/') ) \
    } LIMIT $limit \
    };");
    
    ################### SPARQL - COUNT FLAGGED RESOURCES
    resp_count=$(run_virtuoso_cmd "SPARQL \
    SELECT COUNT(?s) \
    FROM  <http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-all-wikis> \
    WHERE { ?s rdf:type dbo:WdtFrResource };");    
    nb_global=$(get_answer_nb "$resp_count");
    
    echo ">>>>>> UPDATE EACH GRAPH SUBJECTS";
    for graph in ${graph_list[@]}; do
        nb_todo0=1;
        while [ $nb_todo0 -ne 0 ]
        do
            ################### SPARQL - UPDATE AND CHANGE RELATIONS FROM WIKIDATA TO FRENCH RESOURCE AT SUBJECT SIDE   
            resp_updategraph=$(run_virtuoso_cmd "SPARQL \
       DEFINE sql:log-enable 2 \
       WITH <$graph> \
       DELETE { ?y ?p ?o. } \
       INSERT { ?s ?p ?o. } \
       WHERE { SELECT ?s ?p ?o ?y \
       WHERE { \
       { SELECT ?s ?y FROM <http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-all-wikis> \
       WHERE { ?y owl:sameAs ?s. FILTER EXISTS { ?s rdf:type  dbo:WdtFrResource }} \
       } . { \
       SELECT ?y ?p ?o FROM <$graph> WHERE {?y ?p ?o } \
       } \
       } LIMIT $limit };");
       
            ################### SPARQL - COUNT SAME AS HAVING FLAG  AT SUBJECT SIDE
            resp_todo0=$(run_virtuoso_cmd "SPARQL \
       SELECT COUNT(?y) WHERE { \
       { \
       SELECT ?s ?y FROM <http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-all-wikis> \
       WHERE { ?y owl:sameAs ?s. FILTER EXISTS { ?s rdf:type  dbo:WdtFrResource }} \
       } . { \
       SELECT ?y ?p ?o FROM <$graph> WHERE {?y ?p ?o } \
       } };");
            nb_todo0=$(get_answer_nb "$resp_todo0");
            echo "$graph need to change Subjects : $nb_todo0";
        done
    done
    echo ">>>>>> UPDATE EACH GRAPH OBJECTS";
    for graph in ${graph_list[@]}; do
        nb_todo0=1;
        while [ $nb_todo0 -ne 0 ]
        do
       
            ################### SPARQL - UPDATE AND CHANGE RELATIONS FROM WIKIDATA TO FRENCH RESOURCE AT OBJECT SIDE 
            resp_updategraph=$(run_virtuoso_cmd "SPARQL \
       DEFINE sql:log-enable 2  WITH <$graph> \
       DELETE { ?s ?p ?wkd. } \
       INSERT { ?s ?p ?dbfr. } \
       WHERE { SELECT ?dbfr ?p ?s ?wkd WHERE { \
       {\
       SELECT ?dbfr ?wkd FROM <http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-all-wikis> \
       WHERE { ?wkd owl:sameAs ?dbfr. FILTER EXISTS { ?dbfr rdf:type  dbo:WdtFrResource }} \
       } . { \
       SELECT ?s ?p ?wkd FROM <$graph> WHERE {?s ?p ?wkd } } \
       }  LIMIT $limit };");
       
            ################### SPARQL - COUNT SAME AS HAVING FLAG  AT OBJECTS SIDE
       resp_todo0=$(run_virtuoso_cmd "SPARQL \
       SELECT COUNT(?wkd) WHERE { \
       {SELECT ?dbfr ?wkd FROM <http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-all-wikis> \
       WHERE { ?wkd owl:sameAs ?dbfr. FILTER EXISTS { ?dbfr rdf:type  dbo:WdtFrResource }} \
       } . { \
       SELECT ?s ?p ?wkd FROM <$graph> WHERE {?s ?p ?wkd } } \
       };");
       nb_todo0=$(get_answer_nb "$resp_todo0");
       echo "$graph need to change objects : $nb_todo0";
        done
    done
    
    ################### SPARQL - INVERSE SAMEAS IN dbpedia_wikidata_sameas-all-wikis graph
    resp3=$(run_virtuoso_cmd "SPARQL \
    DEFINE sql:log-enable 2 WITH <http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-all-wikis> \
    INSERT { ?y owl:sameAs ?s. } \
    WHERE { \
    SELECT ?y ?s FROM <http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-all-wikis> \
    WHERE { ?s owl:sameAs ?y. FILTER EXISTS { ?y rdf:type dbo:WdtFrResource } \
    } LIMIT $limit};");
    echo ">>>>>> LINK TO FR RESSOURCE";
    nb_todo=1;
    while [ $nb_todo -ne 0 ]
    do
      
      ################### SPARQL - LINK TO FRENCH RESOURCES THE OTHERS LINGUISTICS RESOURCES  IN dbpedia_wikidata_sameas-all-wikis graph
        resp4=$(run_virtuoso_cmd "SPARQL DEFINE sql:log-enable 2 \
   WITH <http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-all-wikis>  \
   DELETE { ?s owl:sameAs ?p. } \
   INSERT { ?y owl:sameAs ?p. } \
   WHERE { SELECT ?s ?y ?p FROM <http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-all-wikis> WHERE { \
   ?y rdf:type dbo:WdtFrResource. \
   ?s owl:sameAs ?y. \
   ?s owl:sameAs ?p. \
   FILTER (?y != ?p ) \
   } LIMIT $limit };");
        resp_todo=$(run_virtuoso_cmd "SPARQL SELECT COUNT(*) FROM <http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-all-wikis> WHERE {?y rdf:type dbo:WdtFrResource. ?s owl:sameAs ?y. ?s owl:sameAs ?p. FILTER (?y != ?p ) };");
        nb_todo=$(get_answer_nb "$resp_todo");
        echo $nb_todo;
    done
    echo ">>>>>> INVERSE SAME AS"
    nb_todo2=1;
    while [ $nb_todo2 -ne 0 ]
    do
      
      ################### SPARQL - INVERSE SAMEAS
        resp5=$(run_virtuoso_cmd "SPARQL DEFINE sql:log-enable 2 \
   WITH <http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-all-wikis>  \
   DELETE { ?s owl:sameAs ?y. } \
   INSERT { ?y owl:sameAs ?s. } \
   WHERE { \
   SELECT ?y ?s FROM <http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-all-wikis> WHERE { \
   ?y rdf:type dbo:WdtFrResource. \
   ?s owl:sameAs ?y \
   } LIMIT $limit };");
        resp_todo2=$(run_virtuoso_cmd "SPARQL SELECT COUNT(?s) FROM <http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-all-wikis> WHERE {?y rdf:type dbo:WdtFrResource. ?s owl:sameAs ?y. };");
        nb_todo2=$(get_answer_nb "$resp_todo2");
    done
done
echo "[CLEAN WIKIDATA] END";
