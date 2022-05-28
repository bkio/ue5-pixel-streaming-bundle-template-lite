#!/bin/sh

# TURN setup starts
publicip=$(curl -s http://api.ipify.org)
localip=$(hostname -I | awk '{print $1}')
turnport=$TURN_PORT
turnserveraddress="${publicip}:${turnport}"
turnusername="PixelStreamingUser"
turnpassword="AnotherTURNintheroad"
realm="PixelStreaming"
arguments_1="-p ${turnport} -r $realm -X $publicip -E $localip -L $localip --no-cli --no-tls --no-dtls --pidfile /var/run/turnserver.pid -f -a -v -n -u ${turnusername}:${turnpassword}"
turnserver $arguments_1 & # Start the turn server (coturn)
stunserver="stun.l.google.com:19302"
peerconnectionoptions="{\"iceServers\":[{\"urls\":[\"stun:$stunserver\",\"turn:$turnserveraddress\"],\"username\":\"$turnusername\",\"credential\":\"$turnpassword\"}]}"
# TURN setup ends

cd /opt/pixel_streaming_bundle/PixelStreamingServer
node cirrus --peerConnectionOptions=\"$peerconnectionoptions\" --HttpPort=$HTTP_PORT --StreamerPort=$STREAMER_PORT &

cd /opt/pixel_streaming_bundle/CompiledProject

UE_PROJECT_NAME=""
for FILENAME in *.sh; do
    shFileWithExt=${FILENAME##*/}
    UE_PROJECT_NAME=${shFileWithExt%.*}
done
echo "Found project name: $UE_PROJECT_NAME"

UE_TRUE_SCRIPT_NAME=$(echo \"$0\" | xargs readlink -f)

UE_PROJECT_ROOT=$(dirname "$UE_TRUE_SCRIPT_NAME")/CompiledProject

UE_BINARIES_BASE="$UE_PROJECT_ROOT/$UE_PROJECT_NAME/Binaries/Linux"

# Create a symbolic link to the path where libnvidia-encode.so.1 will be mounted, since Unreal seems to ignore LD_LIBRARY_PATH
ln -s /usr/lib/x86_64-linux-gnu/libnvidia-encode.so.1 $UE_BINARIES_BASE/libnvidia-encode.so.1

UE_PROJECT_BINARY=""
if test -f "$UE_BINARIES_BASE/$UE_PROJECT_NAME"; then
    UE_PROJECT_BINARY="$UE_BINARIES_BASE/$UE_PROJECT_NAME"
elif test -f "$UE_BINARIES_BASE/$UE_PROJECT_NAME-Linux-Shipping"; then
    UE_PROJECT_BINARY="$UE_BINARIES_BASE/$UE_PROJECT_NAME-Linux-Shipping"
elif test -f "$UE_BINARIES_BASE/$UE_PROJECT_NAME-Linux-Debug"; then
    UE_PROJECT_BINARY="$UE_BINARIES_BASE/$UE_PROJECT_NAME-Linux-Debug"
else
    echo "Could not find any candidate for project binary."
    exit 1
fi

#chmod +x $UE_PROJECT_BINARY

arguments_2="-PixelStreamingURL=ws://localhost:${STREAMER_PORT} -RenderOffScreen -UseHyperThreading -ResX=1920 -ResY=1080 -Windowed -ForceRes -Unattended"
$UE_PROJECT_BINARY $UE_PROJECT_NAME $arguments_2