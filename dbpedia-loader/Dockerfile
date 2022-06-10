FROM debian:jessie

LABEL org.aksw.dld=true org.aksw.dld.type="import" org.aksw.dld.require.store="virtuoso" org.aksw.dld.config="{volumes_from: [store]}"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -y git virtuoso-opensource pigz pbzip2 bzip2

ADD import_conductor.sh /
RUN chmod +x /import_conductor.sh
ADD process /
RUN chmod +rx -R /process

ENTRYPOINT /bin/bash import.sh 
