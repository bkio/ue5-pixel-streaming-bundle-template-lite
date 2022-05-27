#!/bin/sh

cd /opt/pixel_streaming_bundle/PixelStreamingServer
node cirrus &

cd /opt/pixel_streaming_bundle/CompiledProject

UE_PROJECT_NAME=""
for FILENAME in *.sh; do
    shFileWithExt=${FILENAME##*/}
    UE_PROJECT_NAME=${shFileWithExt%.*}
done
echo "Found project name: $UE_PROJECT_NAME"

UE_TRUE_SCRIPT_NAME=$(echo \"$0\" | xargs readlink -f)

UE_PROJECT_ROOT=$(dirname "$UE_TRUE_SCRIPT_NAME")/CompiledProject

# Create a symbolic link to the path where libnvidia-encode.so.1 will be mounted, since Unreal seems to ignore LD_LIBRARY_PATH
ln -s /usr/lib/x86_64-linux-gnu/libnvidia-encode.so.1 $UE_PROJECT_ROOT/$UE_PROJECT_NAME/Binaries/Linux/libnvidia-encode.so.1

chmod +x "$UE_PROJECT_ROOT/$UE_PROJECT_NAME/Binaries/Linux/$UE_PROJECT_NAME-Linux-Shipping"

"$UE_PROJECT_ROOT/$UE_PROJECT_NAME/Binaries/Linux/$UE_PROJECT_NAME-Linux-Shipping" $UE_PROJECT_NAME "$@"