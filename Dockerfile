FROM debian:8.10

MAINTAINER Jonathan Gordon <jgordon@isi.edu>

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8


# Install basic system dependencies.

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -q -y --fix-missing \
 && apt-get install -q -y --fix-missing --no-install-recommends \
        bison bzip2 ca-certificates flex g++ git libssl-dev make wget \
        zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*


# Install Miniconda.

RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh \
 && wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
         -O /tmp/miniconda.sh -q \
 && bash /tmp/miniconda.sh -b -p /opt/conda \
 && rm /tmp/miniconda.sh

ENV PATH /opt/conda/bin:$PATH

RUN conda update -y conda \
 && conda install -y ansi2html beautifulsoup4 flask ftfy lxml


# Install Gurobi.

ENV GUROBI_INSTALL /interpret/ext/gurobi
ENV GUROBI_HOME $GUROBI_INSTALL/linux64

WORKDIR /interpret/ext

RUN mkdir -p "$GUROBI_INSTALL/scripts" \
 && wget http://packages.gurobi.com/6.0/gurobi6.0.5_linux64.tar.gz \
 && tar xvzf gurobi6.0.5_linux64.tar.gz \
 && mv gurobi605/linux64 "$GUROBI_INSTALL" \
 && rm -rf "$GUROBI_HOME/docs" "$GUROBI_HOME/examples" "$GUROBI_HOME/src" \
        gurobi605 gurobi6.0.5_linux64.tar.gz

ENV PATH $PATH:$GUROBI_HOME/bin
ENV CPLUS_INCLUDE_PATH $GUROBI_HOME/include:$CPLUS_INCLUDE_PATH
ENV LD_LIBRARY_PATH $GUROBI_HOME/lib:$LD_LIBRARY_PATH
ENV GRB_LICENSE_FILE $GUROBI_INSTALL/license/gurobi.lic


# Install Phillip.

RUN apt-get update -q -y --fix-missing \
 && apt-get install -q -y --fix-missing --no-install-recommends \
        graphviz liblpsolve55-dev lp-solve \
 && rm -rf /var/lib/apt/lists/*

ENV CPLUS_INCLUDE_PATH /usr/include/lpsolve:$CPLUS_INCLUDE_PATH
ENV LD_LIBRARY_PATH /usr/lib/lp_solve:$LD_LIBRARY_PATH
ENV LIBRARY_PATH /usr/lib/lp_solve:$GUROBI_HOME/lib:$LIBRARY_PATH

WORKDIR /interpret/ext

RUN git clone https://github.com/kazeto/phillip

WORKDIR /interpret/ext/phillip

RUN 2to3 -w tools/configure.py \
 && 2to3 -w tools/util.py \
 && 2to3 -w tools/graphviz.py \
 && /bin/echo -e "\ny\ny" | python ./tools/configure.py \
 && make LDFLAGS="-lcolamd -llpsolve55 -lgurobi_c++ -lgurobi60 -ldl"


# Add the C&C pipeline and compile.

RUN apt-get update -q -y --fix-missing \
 && apt-get install -q -y --fix-missing --no-install-recommends \
        gsoap swi-prolog \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /interpret/ext

RUN git clone https://github.com/jgordon/boxer candc

WORKDIR /interpret/ext/candc

RUN make \
 && make bin/t \
 && make bin/boxer \
 && make soap

RUN tar -xjvf models-1.02.tar.bz2 \
 && rm models-1.02.tar.bz2


# Add the application code to the Docker image.

COPY app /interpret/app
COPY kb /interpret/kb
COPY server /interpret
COPY store-license /interpret


# Run our server.

EXPOSE 5000

WORKDIR /interpret
CMD ["./server"]
