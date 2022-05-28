#FROM adamrehn/ue4-runtime:20.04-vulkan-noaudio
FROM adamrehn/ue4-runtime:20.04-cudagl11.4.2-noaudio

# Already added in base image
# ENV NVIDIA_DRIVER_CAPABILITIES ${NVIDIA_DRIVER_CAPABILITIES},video

COPY CompiledProject /opt/pixel_streaming_bundle/CompiledProject
COPY PixelStreamingServer /opt/pixel_streaming_bundle/PixelStreamingServer
COPY RunEnv.sh /opt/pixel_streaming_bundle/RunEnv.sh

USER root

# NVIDIA keyrings are broken. These lines are for a temporary fix recommended in NVIDIA forums. NVIDIA fix starts.
COPY cuda-keyring_1.0-1_all.deb /tmp/cuda-keyring_1.0-1_all.deb
WORKDIR /tmp
RUN sed -i '/developer\.download\.nvidia\.com\/compute\/cuda\/repos/d' /etc/apt/sources.list.d/*
RUN sed -i '/developer\.download\.nvidia\.com\/compute\/machine-learning\/repos/d' /etc/apt/sources.list.d/*
RUN apt-key del 7fa2af80 \ 
    && dpkg -i cuda-keyring_1.0-1_all.deb
# NVIDIA fix ends.

RUN apt-get update -yq \
    && apt-get -yq install curl gnupg ca-certificates \
    && curl -L https://deb.nodesource.com/setup_12.x | bash \
    && apt-get update -yq \
    && apt-get install -yq nodejs \
    && apt-get install -yq coturn

# Install the dependencies for the signalling server
WORKDIR /opt/pixel_streaming_bundle/PixelStreamingServer
RUN npm install .

USER ue4

# Use --network host instead of EXPOSEs. For best network performance and also it is tricky to find out what to expose for ICE connection.
# Example run usage: docker run -it --rm --gpus all --network host -e HTTP_PORT=8000 -e STREAMER_PORT=9000 -e TURN_PORT=10000 gcr.io/my-project/my-image

# Set the packaged project as the container's entrypoint
ENTRYPOINT ["/opt/pixel_streaming_bundle/RunEnv.sh"]