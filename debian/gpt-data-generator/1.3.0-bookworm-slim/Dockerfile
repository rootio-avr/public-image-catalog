# 1st Stage
FROM debian:bookworm-slim AS build

ENV GEM_HOME="/usr/local/bundle"
ENV PATH $GEM_HOME/bin:$GEM_HOME/gems/bin:$PATH

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl wget tar libssl-dev zlib1g-dev libreadline-dev libyaml-dev ca-certificates \
    && update-ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# Install Ruby 3.4.1 or higher
ARG RUBY_VERSION="3.4.1"
RUN curl -fsSL https://cache.ruby-lang.org/pub/ruby/3.4/ruby-${RUBY_VERSION}.tar.gz -o ruby-${RUBY_VERSION}.tar.gz && \
    tar -xzf ruby-${RUBY_VERSION}.tar.gz && \
    cd ruby-${RUBY_VERSION} && \
    ./configure && \
    make && make install && \
    cd .. && rm -rf ruby-${RUBY_VERSION}*

WORKDIR /performance

# Download the source code
ARG PERFORMANCE_VERSION="2.14.0"
ENV PERFORMANCE_URL="https://gitlab.com/gitlab-org/quality/performance/-/archive/${PERFORMANCE_VERSION}/performance-${PERFORMANCE_VERSION}.tar.gz"

RUN wget -q -O /tmp/performance.tar.gz ${PERFORMANCE_URL} \
    && tar -xzf /tmp/performance.tar.gz --strip-components=1 -C /performance \
    && rm /tmp/performance.tar.gz

RUN gem install bundler && bundle config set without 'dev' && bundle install


# 2nd Stage
FROM debian:bookworm-slim

ENV GEM_HOME="/usr/local/bundle"
ENV PATH $GEM_HOME/bin:$GEM_HOME/gems/bin:/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
ENV GPT_DOCKER=true
ENV GPT_DOCKER_CONFIG_DIR=/config
ENV GPT_DOCKER_RESULTS_DIR=/results

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libc6 \
    libyaml-0-2 \
    libssl3 \
    zlib1g \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy Ruby installation from build stage
COPY --from=build /usr/local/bin/ /usr/local/bin/
COPY --from=build /usr/local/lib/ /usr/local/lib/
COPY --from=build /usr/local/include/ /usr/local/include/
COPY --from=build /usr/local/share/ /usr/local/share/


COPY --from=build /usr/local/bundle/ /usr/local/bundle/
COPY --from=build /performance /performance
WORKDIR /performance

ENTRYPOINT ["./bin/generate-gpt-data"]
CMD ["--help"]