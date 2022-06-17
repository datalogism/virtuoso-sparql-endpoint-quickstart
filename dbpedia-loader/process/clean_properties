#!/usr/bin/env bash
. ../virtuoso_fct.sh --source-only



################### SPARQL - GLOBAL STATS - Nb entities total
run_virtuoso_cmd "SPARQL PREFIX void: <http://rdfs.org/ns/void#> INSERT INTO <${DOMAIN}/graph/metadata> { <${DOMAIN}> void:entities ?no . } WHERE { SELECT COUNT(distinct ?s) AS ?no { ?s a [] } };"
