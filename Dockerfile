FROM adamrehn/ue4-runtime:20.04-vulkan-noaudio

COPY CompiledProject /opt/pixel_streaming_bundle/CompiledProject
COPY PixelStreamingServer /opt/pixel_streaming_bundle/PixelStreamingServer
COPY RunEnv.sh /opt/pixel_streaming_bundle/RunEnv.sh

USER root
RUN apt-get update -yq \
    && apt-get -yq install curl gnupg ca-certificates \
    && curl -L https://deb.nodesource.com/setup_12.x | bash \
    && apt-get update -yq \
    && apt-get install -yq \
        nodejs

# Install the dependencies for the signalling server
WORKDIR /opt/pixel_streaming_bundle/PixelStreamingServer
RUN npm install .

USER ue4

# Expose TCP port 8080 for player WebSocket connections and web server HTTP access
EXPOSE 8080

# Expose TCP port 8888 for streamer WebSocket connections
# No needed since we are embedding both here
#EXPOSE 8888
#EXPOSE 8888/udp

# Google stun
EXPOSE 19302

# Turn coturn
EXPOSE 3478
EXPOSE 3479

# Set the packaged project as the container's entrypoint
ENTRYPOINT ["/opt/pixel_streaming_bundle/RunEnv.sh", "-AudioMixer", "-PixelStreamingIP=localhost", "-PixelStreamingPort=8888", "-RenderOffScreen"]