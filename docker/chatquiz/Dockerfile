FROM rocker/tidyverse

MAINTAINER Sebastian Kranz "sebastian.kranz@uni-ulm.de"

# Add shiny support
RUN /rocker_scripts/install_shiny_server.sh

# Use custom shiny-server.conf
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf

# Required dependency for igraph
RUN apt-get update -y && apt-get install -y libglpk-dev

# External CRAN dependencies
COPY install_1.r /tmp/install_1.r
RUN Rscript /tmp/install_1.r 

# External github dependencies
COPY install_2.r /tmp/install_2.r
RUN Rscript /tmp/install_2.r 

# copy and run installation for main package
COPY install_3.r /tmp/install_3.r
RUN Rscript /tmp/install_3.r 