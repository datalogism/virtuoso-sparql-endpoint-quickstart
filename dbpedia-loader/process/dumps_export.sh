
#!/usr/bin/env bash
. ../virtuoso_fct.sh --source-only



cd $DATA_DIR
mkdir -p computed_dumps
cd ${DATA_DIR}/computed_dumps
echo ">>>>>>> DUMP METADATA"
run_virtuoso_cmd "dump_one_graph ('http://fr.dbpedia.org/graph/metadata', '${DATA_DIR}/computed_dump/metadata_computed_', 1000000000);"
echo ">>>>>>> DUMP LABELS" 
run_virtuoso_cmd "dump_one_graph ('http://fr.dbpedia.org/graph/dbpedia_generic_labels', '${DATA_DIR}/computed_dumps/labels_computed_', 1000000000);"
echo ">>>>>>> DUMP WIKIDATA SUBCLASS OF" 
run_virtuoso_cmd "dump_one_graph ('http://fr.dbpedia.org/graph/dbpedia_wikidata_mappingbased-literals', '${DATA_DIR}/computed_dumps/wikidata-subclassof_computed_', 1000000000);"
echo ">>>>>>> DUMP WIKIDATA GEOCOORD" 
run_virtuoso_cmd "dump_one_graph ('http://fr.dbpedia.org/graph/dbpedia_wikidata_geo-coordinates', '${DATA_DIR}/computed_dumps/wikidata-geocoord_computed_', 1000000000);"
echo ">>>>>>> DUMP WIKIDATA LINKS EXTERNAL" 
run_virtuoso_cmd "dump_one_graph ('http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-external', '${DATA_DIR}/computed_dumps/wikidata-links-external_computed_', 1000000000);"
echo ">>>>>>> DUMP WIKIDATA LINKS SAME AS" 
run_virtuoso_cmd "dump_one_graph ('http://fr.dbpedia.org/graph/dbpedia_wikidata_sameas-all-wikis', '${DATA_DIR}/computed_dumps/wikidata-links-sameas_computed_', 1000000000);"
echo ">>>>>>> DUMP WIKIDATA Mapped Obj" 
run_virtuoso_cmd "dump_one_graph ('http://fr.dbpedia.org/graph/dbpedia_wikidata_mappingbased-objects-uncleaned', '${DATA_DIR}/computed_dumps/wikidata-mapped-obj_computed_', 1000000000);"




 	
