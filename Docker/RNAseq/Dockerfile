FROM continuumio/miniconda3
MAINTAINER mzamanian@wisc.edu

# install (nf tracing)
RUN apt-get update && apt-get install -y procps

# install conda packages
COPY conda_env.yml .
RUN \
   conda env update -n root -f conda_env.yml \
&& conda clean -a

# install Nextflow
#RUN curl -s https://get.nextflow.io | bash
#RUN chmod 777 nextflow
#RUN mv nextflow /opt/
#RUN chmod 777 /opt/nextflow
#ENV PATH="/opt:${PATH}"

#NOTES BELOW
#RUN mv nextflow /usr/local/bin
#ENV PATH="/home/mzamanian:${PATH}"
# WORKDIR /
# RUN mkdir /home/mzamanian
# ENV HOME=/home/mzamanian
