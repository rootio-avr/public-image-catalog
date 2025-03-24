# Copyright 2019 The TensorFlow Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ============================================================================

# Build stage
FROM nvidia/cuda:12.3.0-devel-ubuntu22.04 as builder
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG C.UTF-8

COPY ./utils/setup.sources.sh /setup.sources.sh
COPY ./utils/setup.packages.sh /setup.packages.sh
COPY ./utils/gpu.packages.txt /gpu.packages.txt
RUN /setup.sources.sh
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --allow-change-held-packages \
    $(grep -v '^#' /gpu.packages.txt | tr '\n' ' ')

ARG PYTHON_VERSION=3.11.7
ARG TENSORFLOW_PACKAGE=tensorflow==2.18.0
COPY ./utils/setup.python.sh /setup.python.sh
COPY ./utils/gpu.requirements.txt /gpu.requirements.txt

# Clean up any system-level Python packages first
RUN apt-get update && apt-get remove -y python3-cryptography python3-jwt && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/lib/python3/dist-packages/cryptography* && \
    rm -rf /usr/lib/python3/dist-packages/PyJWT* && \
    rm -rf /usr/lib/python3/dist-packages/jwt*

# Install dependencies for building Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    zlib1g-dev \
    libffi-dev \
    libssl-dev \
    libsqlite3-dev \
    libbz2-dev \
    libreadline-dev \
    liblzma-dev \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Download and compile Python from source
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz && \
    tar -xvf Python-${PYTHON_VERSION}.tgz && \
    cd Python-${PYTHON_VERSION} && \
    ./configure --enable-optimizations && \
    make -j$(nproc) && \
    make altinstall && \
    cd .. && rm -rf Python-${PYTHON_VERSION}*

# Ensure the correct Python version is used
RUN ln -sf /usr/local/bin/python3.11 /usr/bin/python3 && \
    ln -sf /usr/bin/python3 /usr/bin/python

# Upgrade pip and install packages
RUN python3 -m ensurepip && \
    python3 -m pip install --no-cache-dir --upgrade pip setuptools==70.0.0 wheel && \
    python3 -m pip install --no-cache-dir ${TENSORFLOW_PACKAGE} \
    cryptography==42.0.4 \
    PyJWT==2.4.0

COPY ./utils/setup.cuda.sh /setup.cuda.sh
RUN /setup.cuda.sh

# Final stage
FROM nvidia/cuda:12.3.0-runtime-ubuntu22.04 as base
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG C.UTF-8

# Install minimal dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

# Copy Python and required files
COPY --from=builder /usr/local/bin/python3.11 /usr/local/bin/python3.11
COPY --from=builder /usr/local/lib/python3.11 /usr/local/lib/python3.11
COPY --from=builder /usr/local/include/python3.11 /usr/local/include/python3.11

# Copy only required shared libraries
COPY --from=builder /usr/lib/x86_64-linux-gnu/libpython3.11.so* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libssl.so* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libcrypto.so* /usr/lib/x86_64-linux-gnu/
# Copy CUDA binaries (including nvcc) from the builder stage
COPY --from=builder /usr/local/cuda /usr/local/cuda

# Set the environment variable for CUDA binaries
ENV PATH=/usr/local/cuda/bin:$PATH
COPY ./utils/bashrc /etc/bash.bashrc
RUN chmod a+rwx /etc/bash.bashrc

# Set environment variables
ENV PATH=/usr/local/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/lib:/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
ENV PYTHONPATH=/usr/local/lib/python3.11/site-packages:$PYTHONPATH
ENV PYTHONHOME=/usr/local

# Symlink Python commands
RUN ln -sf /usr/local/bin/python3.11 /usr/bin/python3 && \
    ln -sf /usr/bin/python3 /usr/bin/python

# Jupyter stage
FROM base as jupyter

COPY ./utils/jupyter.requirements.txt /jupyter.requirements.txt
COPY ./utils/setup.jupyter.sh /setup.jupyter.sh
RUN python3 -m pip install --no-cache-dir -r /jupyter.requirements.txt -U
RUN /setup.jupyter.sh
COPY ./utils/jupyter.readme.md /tf/tensorflow-tutorials/README.md

WORKDIR /tf
EXPOSE 8888

CMD ["bash", "-c", "source /etc/bash.bashrc && jupyter notebook --notebook-dir=/tf --ip 0.0.0.0 --no-browser --allow-root"] 