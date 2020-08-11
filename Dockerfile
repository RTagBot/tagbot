FROM rocker/r-base:3.6.3

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  git \
  libcurl4-openssl-dev \
  libssl-dev

COPY . /tagbot

RUN Rscript -e "install.packages('remotes')"
RUN Rscript -e "remotes::install_local('/tagbot/')"
