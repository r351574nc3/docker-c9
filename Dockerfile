FROM alpine:3.6
MAINTAINER Leo Przybylski <r351574nc3@gmail.com>

ENV C9_HOME /opt/c9
ENV C9_USER c9
ENV C9_PASS changeme

ENV VERSION=v6.10.3 NPM_VERSION=3 CONFIG_FLAGS="" DEL_PKGS="libgcc libstdc++" RM_DIRS=/usr/include

######################################
# Install Node
######################################
RUN apk add --no-cache bash curl make gcc g++ python linux-headers paxctl libgcc libstdc++ gnupg tmux && \
  gpg --keyserver ha.pool.sks-keyservers.net --recv-keys \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 && \
  curl -o node-${VERSION}.tar.gz -sSL https://nodejs.org/dist/${VERSION}/node-${VERSION}.tar.gz && \
  curl -o SHASUMS256.txt.asc -sSL https://nodejs.org/dist/${VERSION}/SHASUMS256.txt.asc && \
  gpg --verify SHASUMS256.txt.asc && \
  grep node-${VERSION}.tar.gz SHASUMS256.txt.asc | sha256sum -c - && \
  tar -zxf node-${VERSION}.tar.gz && \
  cd node-${VERSION} && \
  export GYP_DEFINES="linux_use_gold_flags=0" && \
  ./configure --prefix=/usr ${CONFIG_FLAGS} && \
  NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
  make -j${NPROC} -C out mksnapshot BUILDTYPE=Release && \
  paxctl -cm out/Release/mksnapshot && \
  make -j${NPROC} && \
  make install && \
  paxctl -cm /usr/bin/node && \
  cd / && \
  if [ -x /usr/bin/npm ]; then \
    npm install -g npm@${NPM_VERSION} node-pre-gyp node-gyp \\
    find /usr/lib/node_modules/npm -name test -o -name .bin -type d | xargs rm -rf; \
  fi && \
  rm -rf /node-${VERSION}.tar.gz /SHASUMS256.txt.asc /node-${VERSION} \
    /usr/share/man /tmp/* /var/cache/apk/* /root/.npm /root/.node-gyp /root/.gnupg \
    /usr/lib/node_modules/npm/man /usr/lib/node_modules/npm/doc /usr/lib/node_modules/npm/html

###############################
# Install C9 
###############################
RUN apk add --no-cache git tmux bash ca-certificates curl make gcc g++ python
RUN mkdir -p $C9_HOME/c9sdk && \
	cd $C9_HOME && \
	git config --system http.sslverify false && \
	git clone git://github.com/c9/core.git c9sdk && \
  ln -s $C9_HOME/c9sdk /root/.c9
RUN cd $C9_HOME/c9sdk && \
 	curl -s -L https://raw.githubusercontent.com/c9/install/master/link.sh | bash && \
	bash ./scripts/install-sdk.sh 
RUN npm i pty.js sqlite3 sequelize https://github.com/c9/nak/tarball/c9 && \
 	npm i && \
	npm cache clean  --force && rm -rf /var/cache/apk/* /tmp/* /var/tmp/* 
RUN rm -rf /usr/share/man /tmp/* /var/cache/apk/* /root/.npm /root/.node-gyp /root/.gnupg \
    /usr/lib/node_modules/npm/man /usr/lib/node_modules/npm/doc /usr/lib/node_modules/npm/html

WORKDIR $C9_HOME

VOLUME ["/workspace"]

EXPOSE 8181

ENTRYPOINT [ "node" ]
CMD ["server.js", "--listen", "0.0.0.0", "-a", "$C9_USER:$C9_PASS", "-w", "/workspace"]