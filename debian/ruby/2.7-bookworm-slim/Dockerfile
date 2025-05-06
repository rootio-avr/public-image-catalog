# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
# PLEASE DO NOT EDIT IT DIRECTLY.

FROM debian:bookworm-slim

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		ca-certificates \
	; \
	rm -rf /var/lib/apt/lists/*

# skip installing gem documentation with `gem install`/`gem update`
RUN set -eux; \
	mkdir -p /usr/local/etc; \
	echo 'gem: --no-document' >> /usr/local/etc/gemrc

ENV LANG C.UTF-8

# Ruby 2.7.8 (note: this version is EOL)
ENV RUBY_VERSION 2.7.8
ENV RUBY_DOWNLOAD_URL https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.8.tar.xz
ENV RUBY_DOWNLOAD_SHA256 f22f662da504d49ce2080e446e4bea7008cee11d5ec4858fc69000d0e5b1d7fb

# OpenSSL 1.1.1 compatibility version for Ruby 2.7.8
ENV OPENSSL_VERSION 1.1.1w
ENV OPENSSL_DOWNLOAD_URL https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
ENV OPENSSL_DOWNLOAD_SHA256 cf3098950cb4d853ad95c0841f1f9c6d3dc102dccfcacd521d93925208b76ac8

# some of ruby's build scripts are written in ruby
# we purge system ruby later to make sure our final image uses what we just built
RUN set -eux; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		bison \
		dpkg-dev \
		libgdbm-dev \
		ruby \
		autoconf \
		bzip2 \
		g++ \
		gcc \
		libbz2-dev \
		libffi-dev \
		libgdbm-compat-dev \
		libglib2.0-dev \
		libgmp-dev \
		libncurses-dev \
		libreadline-dev \
		libxml2-dev \
		libxslt-dev \
		libyaml-dev \
		make \
		wget \
		xz-utils \
		zlib1g-dev \
		perl \
	; \
	\
	# Compile OpenSSL 1.1.1 from source
	wget -O openssl.tar.gz "$OPENSSL_DOWNLOAD_URL"; \
	echo "$OPENSSL_DOWNLOAD_SHA256 *openssl.tar.gz" | sha256sum --check --strict; \
	mkdir -p /usr/src/openssl; \
	tar -xzf openssl.tar.gz -C /usr/src/openssl --strip-components=1; \
	rm openssl.tar.gz; \
	cd /usr/src/openssl; \
	./config --prefix=/usr/local/openssl-1.1.1 shared zlib; \
	make -j "$(nproc)"; \
	make install_sw; \
	cd /; \
	\
	# Download Ruby
	wget -O ruby.tar.xz "$RUBY_DOWNLOAD_URL"; \
	echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.xz" | sha256sum --check --strict; \
	\
	mkdir -p /usr/src/ruby; \
	tar -xJf ruby.tar.xz -C /usr/src/ruby --strip-components=1; \
	rm ruby.tar.xz; \
	\
	cd /usr/src/ruby; \
	\
	# Export environment variables for build
	export rb_cv_wide_so_suffix=yes; \
	export rb_cv_binary_compile_options=yes; \
	\
	autoconf; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	./configure \
		--build="$gnuArch" \
		--disable-install-doc \
		--enable-shared \
		--with-openssl-dir=/usr/local/openssl-1.1.1 \
	; \
	\
	make -j2; \
	make install; \
	\
	# Create symlinks for OpenSSL libraries to ensure Ruby can find them at runtime
	ln -sf /usr/local/openssl-1.1.1/lib/libssl.so.1.1 /usr/lib/; \
	ln -sf /usr/local/openssl-1.1.1/lib/libcrypto.so.1.1 /usr/lib/; \
	\
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark > /dev/null; \
	find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' \
		| awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -r apt-mark manual \
	; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*; \
	\
	cd /; \
	rm -r /usr/src/ruby; \
	rm -r /usr/src/openssl; \
	# verify we have no "ruby" packages installed
	if dpkg -l | grep -i ruby; then exit 1; fi; \
	[ "$(command -v ruby)" = '/usr/local/bin/ruby' ]; \
	# rough smoke test
	ruby --version; \
	gem --version; \
	bundle --version

# don't create ".bundle" in all our apps
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_SILENCE_ROOT_WARNING=1 \
	BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $GEM_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/openssl-1.1.1/lib:$LD_LIBRARY_PATH

RUN set -eux; \
	mkdir -p "$GEM_HOME"; \
	# adjust permissions of GEM_HOME for running "gem install" as an arbitrary user
	chmod 1777 "$GEM_HOME"

CMD [ "irb" ]