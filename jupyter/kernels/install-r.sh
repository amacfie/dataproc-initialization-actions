#!/bin/bash

set -e

# install kernel
apt install -y libzmq3-dev
R -e "install.packages('rzmq', repos='http://cran.us.r-project.org')"
R -e "install.packages('repr', repos='http://cran.us.r-project.org')"
R -e "install.packages(c('IRkernel','IRdisplay'),\
      repos = c('http://irkernel.github.io/', getOption('repos')));\
      IRkernel::installspec(user = FALSE)"

# install packages
readonly R_PACKAGES="$(/usr/share/google/get_metadata_value attributes/R_PACKAGES)"
if [ -n "${R_PACKAGES}" ]; then
  echo "Installing custom R packages '${R_PACKAGES/:/ }'"
  for package in ${R_PACKAGES//:/ }; do
    R -e "install.packages('${package}', repos='http://cran.us.r-project.org')"
  done
fi

