FROM rocker/r-base:latest

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  git \
  libcurl4-openssl-dev \
  libssl-dev

COPY . /tagbot

# fix https://github.com/actions/checkout/issues/1169
RUN git config --system --add safe.directory "*"
RUN Rscript -e "install.packages('remotes')"
RUN Rscript -e "remotes::install_local('/tagbot/')"
