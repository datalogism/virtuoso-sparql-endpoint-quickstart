
#!/usr/bin/env bash
. ../virtuoso_fct.sh --source-only

create_proc="""CREATE PROCEDURE dump_one_graph 
  ( IN  srcgraph           VARCHAR
  , IN  out_file           VARCHAR
  , IN  file_length_limit  INTEGER  := 1000000000
  )
  {
    DECLARE  file_name     VARCHAR;
    DECLARE  env,  ses           ANY;
    DECLARE  ses_len
          ,  max_ses_len
          ,  file_len
          ,  file_idx      INTEGER;
   SET ISOLATION = 'uncommitted';
   max_ses_len  := 10000000;
   file_len     := 0;
   file_idx     := 1;
   file_name    := sprintf ('%s%06d.ttl', out_file, file_idx);
   string_to_file ( file_name || '.graph', 
                     srcgraph, 
                     -2
                   );
    string_to_file ( file_name, 
                     sprintf ( '# Dump of graph <%s>, as of %s\n@base <> .\n', 
                               srcgraph, 
                               CAST (NOW() AS VARCHAR)
                             ), 
                     -2
                   );
   env := vector (dict_new (16000), 0, '', '', '', 0, 0, 0, 0, 0);
   ses := string_output ();
   FOR (SELECT * FROM ( SPARQL DEFINE input:storage "" 
                         SELECT ?s ?p ?o { GRAPH `iri(?:srcgraph)` { ?s ?p ?o } } 
                       ) AS sub OPTION (LOOP)) DO
      {
        http_ttl_triple (env, "s", "p", "o", ses);
        ses_len := length (ses);
        IF (ses_len > max_ses_len)
          {
            file_len := file_len + ses_len;
            IF (file_len > file_length_limit)
              {
                http (' .\n', ses);
                string_to_file (file_name, ses, -1);
                gz_compress_file (file_name, file_name||'.gz');
                file_delete (file_name);
                file_len := 0;
                file_idx := file_idx + 1;
                file_name := sprintf ('%s%06d.ttl', out_file, file_idx);
                string_to_file ( file_name, 
                                 sprintf ( '# Dump of graph <%s>, as of %s (part %d)\n@base <> .\n', 
                                           srcgraph, 
                                           CAST (NOW() AS VARCHAR), 
                                           file_idx), 
                                 -2
                               );
                 env := VECTOR (dict_new (16000), 0, '', '', '', 0, 0, 0, 0, 0);
              }
            ELSE
              string_to_file (file_name, ses, -1);
            ses := string_output ();
          }
      }
    IF (LENGTH (ses))
      {
        http (' .\n', ses);
        string_to_file (file_name, ses, -1);
        gz_compress_file (file_name, file_name||'.gz');
        file_delete (file_name);
      }
  }
;""";

run_virtuoso_cmd "${create_proc}";

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




 	
