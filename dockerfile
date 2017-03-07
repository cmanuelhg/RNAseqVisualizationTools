FROM ubuntu:16.04
MAINTAINER Carlos Hernandez-Garcia and Blake Joyce <carlosmhg2015@gmail.com>
LABEL Description="This image is used for running tools required for visualization of RNA-seq results"

# Install iRODS iCommands v.4.2.0
RUN wget -qO - https://packages.irods.org/irods-signing-key.asc | sudo apt-key add - \
    && echo "deb [arch=amd64] https://packages.irods.org/apt/ trusty main" | \
    sudo tee /etc/apt/sources.list.d/renci-irods.list \
    && sudo apt-get update && sudo apt-get install -y \
    irods-icommands

ENV IRODS_PORT=1247
ENV IRODS_PORT_RANGE_BEGIN=20000
ENV IRODS_PORT_RANGE_END=20199
ENV IRODS_CONTROL_PLANE_PORT=1248

RUN mkdir /workspace \
    && chown irods:irods -R /workspace
WORKDIR /workspace

#ENV R_BASE_VERSION 3.3.1
ENV R_BASE_VERSION 3.3.1

# Install R
RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/" >> /etc/apt/sources.list \
	&& apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9 \
	&& apt-get -qq update \
	&& apt-get upgrade -y \
	&& apt-get install -y --no-install-recommends \
		littler \
		r-base-core=${R_BASE_VERSION}* \
		r-base-dev=${R_BASE_VERSION}* \
#		r-recommended=${R_BASE_VERSION}* \
		libcurl4-openssl-dev \
		libxml2-dev \
		libfftw3-dev \
		git \
		wget \
        && echo 'options(repos = c(CRAN = "https://cran.rstudio.com/"), download.file.method = "libcurl")' >> /etc/R/Rprofile.site \
        && echo 'source("/etc/R/Rprofile.site")' >> /etc/littler.r \
	&& ln -s /usr/share/doc/littler/examples/install.r /usr/local/bin/install.r \
	&& ln -s /usr/share/doc/littler/examples/install2.r /usr/local/bin/install2.r \
	&& ln -s /usr/share/doc/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
	&& ln -s /usr/share/doc/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
	&& install.r docopt \
	&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
	&& rm -rf /var/lib/apt/lists/*






# install R packages
RUN Rscript -e 'install.packages("devtools",dependencies=TRUE)' \
	&&Rscript -e 'install.packages(“ggplot2”,dependencies=TRUE)' \
	&&Rscript -e 'install.packages(“plotly”,dependencies=TRUE)' \
	&&Rscript -e 'install.packages(“RCircos”,dependencies=TRUE)' \
	

## install devtools using R
	&&Rscript -e 'install.packages("devtools")'

## install additional R packages using R
RUN > rscript.R \
	&&echo 'source("https://bioconductor.org/biocLite.R")' >> rscript.R \
	&&echo 'biocLite(ask=FALSE)' >> rscript.R \
	&&echo 'biocLite("BiocUpgrade")' >> rscript.R \
	&&echo 'biocLite(c("alyssafrazee/RSkittleBrewer","ballgown","genefilter","dplyr"),ask=FALSE)' >> rscript.R \
	&&Rscript rscript.R

# Cleanup
RUN rm rscript.R

# test if R package are correctly installed
RUN R -e "library(devtools); \
 library(ggplot2); \
 library(plyr); \
 library(RUnit); \
 library(Matrix); \
 library(doParallel); \
 library(foreach); \
 library(assertthat); \
 library(rjson);"

WORKDIR $HOME

# Should I set the command here? If I do this my script will get stucked here?
CMD ["R"]

FROM python:2.7-alpine
RUN apk add --no-cache g++ freetype-dev libpng-dev && \
    ln -s /usr/include/locale.h /usr/include/xlocale.h && \
    pip install \
        cython==0.25.2 \
        jupyter==1.0.0 \
        matplotlib==1.5.1 \
        numpy==1.12.0 && \
    pip install pandas==0.19.2
EXPOSE 8888
WORKDIR /notebooks
VOLUME /notebooks
HEALTHCHECK CMD ["curl", "-f", "http://localhost:8888/"]
CMD jupyter notebook --ip 0.0.0.0 --no-browser

