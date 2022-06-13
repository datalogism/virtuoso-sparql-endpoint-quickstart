. ../virtuoso_fct.sh --source-only
pat4='metadata'

echo "[STATS TIME]"
echo "----GENERAL STATS"
run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> { <${DOMAIN}> void:entities ?no . } WHERE { SELECT COUNT(distinct ?s) AS ?no { ?s a [] } };"
run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> { <${DOMAIN}> void:classes ?no . } WHERE { SELECT COUNT(distinct ?o) AS ?no { ?s rdf:type ?o } };"
run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> { <${DOMAIN}> void:triples ?no . } WHERE { SELECT (COUNT(*) AS ?no) { ?s ?p ?o } };"
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
    run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> { <$graph> void:triples ?no . } WHERE { SELECT (COUNT(*) AS ?no)  FROM <$graph>  { ?s ?p ?o } };"
    run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> { <$graph> void:entities ?no .} WHERE { SELECT COUNT(distinct ?s) AS ?no  FROM <$graph> { ?s a [] } };"
    run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> { <$graph> void:classes ?no .} WHERE { SELECT COUNT(distinct ?o) AS ?no  FROM <$graph> { ?s rdf:type ?o } };"
    run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> { <$graph> void:properties ?no .} WHERE { SELECT COUNT(distinct ?p) AS ?no  FROM <$graph> { ?s ?p ?o } };"
        
     #if [[ ! $graph =~ $pat4 ]] &&  [[ ! $graph =~ $pat5 ]]; then
     if [[ ! $graph =~ $pat4 ]]; then
       
        echo "---- CLASS PARTITIONS stats";
        echo "- classes";
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph> void:classPartition [void:class ?c ] . } WHERE {SELECT DISTINCT(?c) FROM <$graph>  { ?s a ?c . } };"
        echo "- nb entities per classes";
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph> void:classPartition [void:class ?class ; void:entities ?count ] . } WHERE {{ SELECT ?class (count(?instance) AS ?count) WHERE {SELECT DISTINCT ?class ?instance FROM <$graph> WHERE {?instance a ?class } } GROUP BY ?class } };"
        echo "- nb triplet per classes";
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph> void:classPartition [void:class ?c ; void:triples ?x ] . } WHERE {{ SELECT (COUNT(?p) AS ?x) ?c FROM <$graph> WHERE { ?s a ?c ; ?p ?o } GROUP BY ?c } };"
        echo "- nb prop by class";
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph> void:classPartition [void:class ?c ; void:properties ?x ] . } WHERE {{ SELECT (COUNT(DISTINCT ?p) AS ?x) ?c FROM <$graph> WHERE { ?s a ?c ; ?p ?o } GROUP BY ?c } };"
        echo "- besoin d'explications";
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph> void:classPartition [void:class ?c ; void:classes ?x ] . } WHERE {{ SELECT (COUNT(DISTINCT ?d) AS ?x) ?c  FROM <$graph> WHERE { ?s a ?c , ?d } GROUP BY ?c } };"
        echo "- distinct subject per classes";
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph> void:classPartition [void:class ?c ; void:distinctSubjects ?x ] . } WHERE {{ SELECT (COUNT(DISTINCT ?s) AS ?x) ?c FROM <$graph> WHERE { ?s a ?c } GROUP BY ?c } };"
        echo "- distinct object per classes";
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph>  void:classPartition [void:class ?c ; void:distinctObjects ?x ] . } WHERE {{ SELECT (COUNT(DISTINCT ?o) AS ?x) ?c FROM <$graph> WHERE { ?s a ?c ; ?p ?o } GROUP BY ?c } };"
        echo "- nb triples by prop";
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph> void:classPartition [void:class ?c ; void:propertyPartition [void:property ?p ; void:triples ?x ] ] . } WHERE {{ SELECT ?c (COUNT(?o) AS ?x) ?p FROM <$graph> WHERE { ?s a ?c ; ?p ?o } GROUP BY ?c ?p } };"
        echo "- nb subj distinct by prop";
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph>  void:classPartition [void:class ?c ; void:propertyPartition [void:property ?p ; void:distinctSubjects ?x ] ] . } WHERE {{ SELECT (COUNT(DISTINCT ?s) AS ?x) ?c ?p FROM <$graph>  WHERE { ?s a ?c ; ?p ?o } GROUP BY ?c ?p } };"
        echo "---- Property PARTITIONS";
        echo "-nb triples by property";
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph> void:propertyPartition [void:property ?p ; void:triples ?x ] . } WHERE {{ SELECT (COUNT(?o) AS ?x) ?p FROM <$graph> WHERE { ?s ?p ?o } GROUP BY ?p } };" 
        echo "- nb distinct Subject by prop";
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph> void:propertyPartition [void:property ?p ; void:distinctSubjects ?x ] . } WHERE {{ SELECT (COUNT(DISTINCT ?s) AS ?x) ?p FROM <$graph> WHERE { ?s ?p ?o } GROUP BY ?p } };"
        echo "- nb distinct Objects by prop";
        run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> {<$graph> void:propertyPartition [void:property ?p ; void:distinctObjects ?x ] . } WHERE {{ SELECT (COUNT(DISTINCT ?o) AS ?x) ?p FROM <$graph> WHERE { ?s ?p ?o } GROUP BY ?p } };"

     fi
done
echo ">>>>>>>>> END NAMED GRAPH STATS COMPUTATION"
