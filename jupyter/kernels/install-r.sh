#!/bin/bash

set -e

# install kernel
apt install -y libzmq3-dev
R -e "install.packages('rzmq', repos='http://cran.us.r-project.org')"
R -e "install.packages('repr', repos='http://cran.us.r-project.org')"
R -e "install.packages(c('IRkernel','IRdisplay'), \
      repos='http://cran.us.r-project.org'); \
      IRkernel::installspec(user = FALSE)"

