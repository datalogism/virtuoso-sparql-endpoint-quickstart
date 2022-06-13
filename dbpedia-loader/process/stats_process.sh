#!/usr/bin/env bash
. ../virtuoso_fct.sh --source-only
pat4='metadata'

echo "[STATS TIME]"
echo "----GENERAL STATS"

################### SPARQL - GLOBAL STATS - Nb entities total
run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> { <${DOMAIN}> void:entities ?no . } WHERE { SELECT COUNT(distinct ?s) AS ?no { ?s a [] } };"
################### SPARQL - GLOBAL STATS - Nb distincts classes
run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> { <${DOMAIN}> void:classes ?no . } WHERE { SELECT COUNT(distinct ?o) AS ?no { ?s rdf:type ?o } };"
################### SPARQL - GLOBAL STATS - Nb total triples
run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> { <${DOMAIN}> void:triples ?no . } WHERE { SELECT (COUNT(*) AS ?no) { ?s ?p ?o } };"
################### SPARQL - GLOBAL STATS - Nb distincts properties
run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> { <${DOMAIN}> void:properties ?no . } WHERE { SELECT COUNT(distinct ?p) AS ?no  { ?s ?p ?o } };"

echo "---->>> ASK FIRST THE LIST OF NAMED GRAPH"
get_named_graph='SPARQL SELECT DISTINCT(?graphName) WHERE {GRAPH ?graphName {?s ?p ?o } } GROUP BY ?graphName ;'
resp=$(run_virtuoso_cmd "$get_named_graph");
graph_list=$(echo $resp | tr " " "\n" | grep -E "\/graph\/");
echo "---->>> COMPUTE FOR EACH GRAPH STATS"
pat4='metadata'
pat5='wikidata'
for graph in ${graph_list[@]}; do
    echo "<$graph>"
    echo "----  GRAPH STATS";
    
    ################### SPARQL - GRAPH STATS - Nb triples total
    run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> { <$graph> void:triples ?no . } WHERE { SELECT (COUNT(*) AS ?no)  FROM <$graph>  { ?s ?p ?o } };"
   
    ################### SPARQL - GRAPH STATS - Nb distincts entities
    run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> { <$graph> void:entities ?no .} WHERE { SELECT COUNT(distinct ?s) AS ?no  FROM <$graph> { ?s a [] } };"
  
    ################### SPARQL - GRAPH STATS - Nb distincts classes
    run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> { <$graph> void:classes ?no .} WHERE { SELECT COUNT(distinct ?o) AS ?no  FROM <$graph> { ?s rdf:type ?o } };"
  
    ################### SPARQL - GRAPH STATS - Nb distincts properties
    run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> { <$graph> void:properties ?no .} WHERE { SELECT COUNT(distinct ?p) AS ?no  FROM <$graph> { ?s ?p ?o } };"
        
     #if [[ ! $graph =~ $pat4 ]] &&  [[ ! $graph =~ $pat5 ]]; then
     if [[ ! $graph =~ $pat4 ]]; then
        ################### SPARQL - CLASS PARTITION - CREATE PARTITION BY CLASS
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph> void:classPartition [void:class ?c ] . } WHERE {SELECT DISTINCT(?c) FROM <$graph>  { ?s a ?c . } };"
        echo "- nb entities per classes";
        ################### SPARQL - CLASS PARTITION - Nb of triples by entites by class
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph> void:classPartition [void:class ?class ; void:entities ?count ] . } WHERE {{ SELECT ?class (count(?instance) AS ?count) WHERE {SELECT DISTINCT ?class ?instance FROM <$graph> WHERE {?instance a ?class } } GROUP BY ?class } };"
        echo "- nb triplet per classes";
        ################### SPARQL - CLASS PARTITION - Nb of triples triples associated to a class
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph> void:classPartition [void:class ?c ; void:triples ?x ] . } WHERE {{ SELECT (COUNT(?p) AS ?x) ?c FROM <$graph> WHERE { ?s a ?c ; ?p ?o } GROUP BY ?c } };"
        echo "- nb prop by class";
        ################### SPARQL - CLASS PARTITION - Nb of triples properties associated to a class
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph> void:classPartition [void:class ?c ; void:properties ?x ] . } WHERE {{ SELECT (COUNT(DISTINCT ?p) AS ?x) ?c FROM <$graph> WHERE { ?s a ?c ; ?p ?o } GROUP BY ?c } };"
        echo "- besoin d'explications";
        ################### SPARQL - CLASS PARTITION - Nb of triples classe associated to a class
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph> void:classPartition [void:class ?c ; void:classes ?x ] . } WHERE {{ SELECT (COUNT(DISTINCT ?d) AS ?x) ?c  FROM <$graph> WHERE { ?s a ?c , ?d } GROUP BY ?c } };"
        echo "- distinct subject per classes";
        ################### SPARQL - CLASS PARTITION - Nb of triples distincts subjects associated to a classe
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph> void:classPartition [void:class ?c ; void:distinctSubjects ?x ] . } WHERE {{ SELECT (COUNT(DISTINCT ?s) AS ?x) ?c FROM <$graph> WHERE { ?s a ?c } GROUP BY ?c } };"
        echo "- distinct object per classes";
        ################### SPARQL - CLASS PARTITION - Nb  of triples  distincts objects associated to a class 
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph>  void:classPartition [void:class ?c ; void:distinctObjects ?x ] . } WHERE {{ SELECT (COUNT(DISTINCT ?o) AS ?x) ?c FROM <$graph> WHERE { ?s a ?c ; ?p ?o } GROUP BY ?c } };"
        echo "- nb triples by prop";
        ################### SPARQL - CLASS PARTITION - Nb of triple by class and properties
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph> void:classPartition [void:class ?c ; void:propertyPartition [void:property ?p ; void:triples ?x ] ] . } WHERE {{ SELECT ?c (COUNT(?o) AS ?x) ?p FROM <$graph> WHERE { ?s a ?c ; ?p ?o } GROUP BY ?c ?p } };"
        echo "- nb subj distinct by prop";
        ################### SPARQL - CLASS PARTITION - Nb distincts subjects by  properties
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph>  void:classPartition [void:class ?c ; void:propertyPartition [void:property ?p ; void:distinctSubjects ?x ] ] . } WHERE {{ SELECT (COUNT(DISTINCT ?s) AS ?x) ?c ?p FROM <$graph>  WHERE { ?s a ?c ; ?p ?o } GROUP BY ?c ?p } };"
        echo "---- Property PARTITIONS";
        echo "-nb triples by property";
        ################### SPARQL - PROPERTIES PARTITION - Nb distincts triples
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph> void:propertyPartition [void:property ?p ; void:triples ?x ] . } WHERE {{ SELECT (COUNT(?o) AS ?x) ?p FROM <$graph> WHERE { ?s ?p ?o } GROUP BY ?p } };" 
        echo "- nb distinct Subject by prop";
        ################### SPARQL - PROPERTIES PARTITION - Nb distincts subjects
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph> void:propertyPartition [void:property ?p ; void:distinctSubjects ?x ] . } WHERE {{ SELECT (COUNT(DISTINCT ?s) AS ?x) ?p FROM <$graph> WHERE { ?s ?p ?o } GROUP BY ?p } };"
        echo "- nb distinct Objects by prop";
        ################### SPARQL - PROPERTIES PARTITION - Nb distincts objects
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph> void:propertyPartition [void:property ?p ; void:distinctObjects ?x ] . } WHERE {{ SELECT (COUNT(DISTINCT ?o) AS ?x) ?p FROM <$graph> WHERE { ?s ?p ?o } GROUP BY ?p } };"

     fi
done
echo ">>>>>>>>> END NAMED GRAPH STATS COMPUTATION"
