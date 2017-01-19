From golang:1.5.2

# Install java8 runtime
RUN apt-get update && apt-get install -y unzip && rm -rf /var/lib/apt/lists/*

RUN echo 'deb http://httpredir.debian.org/debian jessie-backports main' > /etc/apt/sources.list.d/jessie-backports.list

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

ENV JAVA_VERSION 8u102
ENV JAVA_DEBIAN_VERSION 8u102-b14.1-1~bpo8+1

# see https://bugs.debian.org/775775
# and https://github.com/docker-library/java/issues/19#issuecomment-70546872
ENV CA_CERTIFICATES_JAVA_VERSION 20140324

RUN set -x \
	&& apt-get update \
	&& apt-get install -y \
		openjdk-8-jre-headless="$JAVA_DEBIAN_VERSION" \
		ca-certificates-java="$CA_CERTIFICATES_JAVA_VERSION" \
	&& rm -rf /var/lib/apt/lists/*

# see CA_CERTIFICATES_JAVA_VERSION notes above
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

# see https://bugs.debian.org/793210
# and https://github.com/docker-library/java/issues/46#issuecomment-119026586
RUN apt-get update && apt-get install -y --no-install-recommends libfontconfig1 && rm -rf /var/lib/apt/lists/*


# Install Elasticsearch

RUN set -x \
	&& apt-get update \
	&& apt-get install -y \
		zip \
                curl \
	&& rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash elasticsearch

ENV ELASTICSEARCH_VERSION 2.1.1
ENV ELASTICSEARCH_HOME /home/elasticsearch
ADD https://download.elasticsearch.org/elasticsearch/release/org/elasticsearch/distribution/zip/elasticsearch/$ELASTICSEARCH_VERSION/elasticsearch-$ELASTICSEARCH_VERSION.zip $ELASTICSEARCH_HOME
RUN cd $ELASTICSEARCH_HOME \
	&& unzip $ELASTICSEARCH_HOME/elasticsearch-$ELASTICSEARCH_VERSION.zip \
	&& rm $ELASTICSEARCH_HOME/elasticsearch-$ELASTICSEARCH_VERSION.zip
ENV ELASTICSEARCH_HOME /home/elasticsearch/elasticsearch-$ELASTICSEARCH_VERSION
ENV PATH $ELASTICSEARCH_HOME/bin:$PATH

RUN set -ex \
	&& for path in \
		/var/elasticsearch/logs \
		/etc/elasticsearch/config \
		/var/elasticsearch/data \
	; do \
		mkdir -p "$path"; \
	done

COPY configs/elasticsearch/* /etc/elasticsearch/config/
RUN chown -R elasticsearch:elasticsearch /var/elasticsearch
RUN chown -R elasticsearch:elasticsearch /etc/elasticsearch
RUN rm -rf $ELASTICSEARCH_HOME/config
RUN ln -s /etc/elasticsearch/config $ELASTICSEARCH_HOME/config
RUN chown -R elasticsearch:elasticsearch $ELASTICSEARCH_HOME

# Install ES plugin
RUN $ELASTICSEARCH_HOME/bin/plugin install mapper-size

# Install Eywa

RUN useradd -ms /bin/bash eywa

RUN mkdir /etc/eywa
COPY configs/eywa/* /etc/eywa/
RUN chown -R eywa:eywa /etc/eywa

RUN mkdir /var/eywa
RUN chown -R eywa:eywa /var/eywa

RUN mkdir -p $GOPATH/src/github.com/vivowares/
COPY eywa $GOPATH/src/github.com/vivowares/eywa
RUN go install github.com/vivowares/eywa

ENV EYWA_HOME $GOPATH/src/github.com/vivowares/eywa
COPY assets $GOPATH/src/github.com/vivowares/eywa/assets

# Install supervisor

RUN apt-get update && apt-get install -y supervisor
RUN mkdir -p /var/log/supervisor
COPY configs/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY bootstrap.sh /
RUN chown root:root /bootstrap.sh
RUN chmod 770 /bootstrap.sh

EXPOSE 8080 8081

CMD ["/usr/bin/supervisord"]

