set -e # Helps to give error info

# Project paths

RUST_PROJ="/Users/abai/Documents/Freelance/saead"
IOS_LIB="/Users/abai/Documents/Freelance/saead/saeadLib"

LOCAL_UDL="src/saead.udl"
UDL_NAME="saead"
FRAMEWORK_NAME="saead"
SWIFT_INTERFACE="saeadLib"

# Binary paths
PATH="$PATH:/Users/abai/.cargo/bin" # Adds the rust compiler
PATH="$PATH:/usr/local/bin" # Adds swiftformat to the path

cd "$RUST_PROJ"

# Compile the rust in debug version
cargo build --target aarch64-apple-ios
#cargo build --release --target aarch64-apple-ios
# cargo build --target aarch64-apple-ios-sim
#cargo build --target x86_64-apple-ios

# Remove old files if they exist
IOS_ARM64_FRAMEWORK="$FRAMEWORK_NAME.xcframework/ios-arm64/$FRAMEWORK_NAME.framework"
# IOS_SIM_FRAMEWORK="$FRAMEWORK_NAME.xcframework/ios-arm64_x86_64-simulator/$FRAMEWORK_NAME.framework"

rm -f "$IOS_ARM64_FRAMEWORK/$FRAMEWORK_NAME"
rm -f "$IOS_ARM64_FRAMEWORK/Headers/${UDL_NAME}FFI.h"
# rm -f "$IOS_SIM_FRAMEWORK/$FRAMEWORK_NAME"
# rm -f "$IOS_SIM_FRAMEWORK/Headers/${UDL_NAME}FFI.h"

rm -f target/universal.a
rm -f include/ios/*

# Make dirs if it doesn't exist
mkdir -p include/ios

# UniFfi bindgen
cargo run --bin uniffi-bindgen generate "$LOCAL_UDL" --language swift --out-dir ./include/ios

# Make fat lib for sims
#lipo -create \
#    -output target/universal.a
    #"target/x86_64-apple-ios/debug/lib${UDL_NAME}.a" \
    #"target/aarch64-apple-ios-sim/debug/lib${UDL_NAME}.a" \

# Move binaries
cp "target/aarch64-apple-ios/debug/lib${UDL_NAME}.a" \
    "$IOS_ARM64_FRAMEWORK/$FRAMEWORK_NAME"
#cp target/universal.a \
#    "$IOS_SIM_FRAMEWORK/$FRAMEWORK_NAME"

# Move headers
cp "include/ios/${UDL_NAME}FFI.h" \
    "$IOS_ARM64_FRAMEWORK/Headers/${UDL_NAME}FFI.h"
#cp "include/ios/${UDL_NAME}FFI.h" \
#    "$IOS_SIM_FRAMEWORK/Headers/${UDL_NAME}FFI.h"

# Move swift interface
sed "s/${UDL_NAME}FFI/$FRAMEWORK_NAME/g" "include/ios/$UDL_NAME.swift" > "include/ios/$SWIFT_INTERFACE.swift"
rm -f "$IOS_LIB/$SWIFT_INTERFACE.swift"
cp "include/ios/$SWIFT_INTERFACE.swift" "$IOS_LIB/$SWIFT_INTERFACE.swift"
