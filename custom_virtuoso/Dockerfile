FROM openlink/virtuoso-opensource-7 

USER root
RUN apt-get update
RUN apt-get -y install git python 
RUN cd /opt && git clone https://github.com/datalogism/dbpedia-vad && cd dbpedia-vad && ./build.sh

