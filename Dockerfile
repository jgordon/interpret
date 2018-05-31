FROM debian:8.10

MAINTAINER Jonathan Gordon <jgordon@isi.edu>

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8


# Install basic system dependencies.

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -q -y --fix-missing && \
    apt-get install -q -y --fix-missing --no-install-recommends \
        bison bzip2 ca-certificates flex g++ libssl-dev make wget zlib1g-dev

RUN apt-get clean -q


# Install Miniconda.

RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
         -O /tmp/miniconda.sh -q && \
    bash /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh

ENV PATH /opt/conda/bin:$PATH

RUN conda update -y conda

RUN conda install -y flask beautifulsoup4 lxml ftfy


# Add the C&C pipeline and compile.

RUN apt-get install -q -y --fix-missing --no-install-recommends \
        swi-prolog gsoap

COPY ext /interpret/ext

WORKDIR /interpret/ext

RUN cd candc && \
    make && \
    make bin/t && \
    make bin/boxer && \
    make soap && \
    tar -xjvf models-1.02.tbz2


# Install Gurobi.

ENV GUROBI_INSTALL /interpret/ext/gurobi
ENV GUROBI_HOME $GUROBI_INSTALL/linux64
ENV PATH $PATH:$GUROBI_HOME/bin
ENV CPLUS_INCLUDE_PATH $GUROBI_HOME/include:$CPLUS_INCLUDE_PATH
ENV LD_LIBRARY_PATH $GUROBI_HOME/lib:$LD_LIBRARY_PATH
ENV GRB_LICENSE_FILE $GUROBI_INSTALL/license/gurobi.lic

RUN mkdir -p $GUROBI_INSTALL && \
    wget http://packages.gurobi.com/6.0/gurobi6.0.5_linux64.tar.gz && \
    tar xvzf gurobi6.0.5_linux64.tar.gz && \
    mv gurobi605/linux64 $GUROBI_INSTALL && \
    mkdir $GUROBI_HOME/scripts && \
    rm -rf $GUROBI_HOME/docs && \
    rm -rf $GUROBI_HOME/examples && \
    rm -rf $GUROBI_HOME/src && \
    rm -rf gurobi605 && \
    rm -f gurobi6.0.5_linux64.tar.gz


# Install Phillip.

RUN apt-get install -q -y --fix-missing --no-install-recommends \
        git graphviz liblpsolve55-dev lp-solve

ENV CPLUS_INCLUDE_PATH /usr/include/lpsolve:$CPLUS_INCLUDE_PATH
ENV LD_LIBRARY_PATH /usr/lib/lp_solve:$LD_LIBRARY_PATH
ENV LIBRARY_PATH /usr/lib/lp_solve:$GUROBI_HOME/lib:$LIBRARY_PATH

RUN git clone https://github.com/kazeto/phillip.git && \
    cd phillip && \
    2to3 -w tools/configure.py && \
    /bin/echo -e "\ny\ny" | python ./tools/configure.py && \
    make LDFLAGS="-lcolamd -llpsolve55 -lgurobi_c++ -lgurobi60 -ldl"

RUN 2to3 -w phillip/tools/util.py && \
    2to3 -w phillip/tools/graphviz.py


# Add the application code to the Docker image.

COPY app /interpret/app
COPY kb /interpret/kb
COPY server /interpret


# Run our server.

EXPOSE 5000

WORKDIR /interpret
CMD ["./server"]
