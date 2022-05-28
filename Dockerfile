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

# Expose TCP port 8080 for player WebSocket connections and web server HTTP access
EXPOSE 8080

# Google stun
EXPOSE 19302

# Turn coturn
EXPOSE 19303

# Set the packaged project as the container's entrypoint
ENTRYPOINT ["/opt/pixel_streaming_bundle/RunEnv.sh", "-PixelStreamingURL=ws://localhost:8888", "-RenderOffScreen", "-UseHyperThreading", "-ResX=1920", "-ResY=1080", "-Windowed", "-ForceRes", "-Unattended"]