# Integration
In Xcode add xcframework to the 'Framework Libraries' section', remove not supported targets in deployment settings.

# Development info

https://krirogn.dev/blog/integrate-rust-in-ios
https://kerkour.com/rust-file-encryption
https://www.swift.org/documentation/cxx-interop/project-build-setup/#mixing-swift-and-c-using-swift-package-manager

# Short tutorial for using the folder
Ensure that you have runned
```
rustup target add aarch64-apple-ios && rustup target add x86_64-apple-ios & rustup target add aarch64-apple-ios-sim 
```
```
brew install swiftformat
```

Open cloned folder in vs code, and in terminal type
```
chmod 701 ./make.sh
```

After that open `make.sh` and modify these three correctly. They should point to valid directories in your system.
```
RUST_PROJ="/Users/abai/Documents/Freelance/rust_saead/saead"
IOS_LIB="/Users/abai/Documents/Freelance/rust_saead/saead/saeadLib"
PATH="$PATH:/Users/abai/.cargo/bin" # Adds the rust compiler
```

Then run ./make.sh which will generate the library inside `.xcframework` and create `saeadLib.swift` in Lib folder


# Short tutorial from scratch

Install architectures with this:
```
rustup target add aarch64-apple-ios && rustup target add x86_64-apple-ios & rustup target add aarch64-apple-ios-sim 
```

Then you have to make a new rust library. It doesn't have to located anywhere near the iOS project itself, because we will only reference the library source files with it's absolute path later in Xcode.

```
cargo new --lib saead
cargo add --build uniffi --features build
cargo add uniffi --features cli
```

Then go into Cargo.toml and add these lines.

```
Cargo.toml
[lib]
crate-type = [ "staticlib" ]
name = "saead"

[[bin]]
name = "uniffi-bindgen"
path = "uniffi-bindgen.rs"
```

At the root create build.rs with
```
fn main() {
    uniffi::generate_scaffolding("./src/saead.udl").unwrap();
}
```
and uniffi-bindgen.rs with
```
fn main() {
    uniffi::uniffi_bindgen_main()
}

```

At the src/lib.rs:
```
use std::{
    fs::File, io::{Read, Write},
};

use tink_core::keyset::{JsonReader, insecure};

uniffi::include_scaffolding!("saead"); // "example" is the name of the .udl file 

pub fn encrypt(
    source_path: String, 
    keyset_path: String,
    aad: String,
) -> Vec<u8> {

    //https://github.com/project-oak/tink-rust/blob/main/streaming/README.md

    tink_streaming_aead::init();

    let mut reader = JsonReader::new(File::open(keyset_path).expect("fkey_open"));
    let kh = insecure::read(&mut reader).expect("fhandle");
    let pr = tink_streaming_aead::new(&kh).expect("f_primitive");

    let tmp_path = source_path.clone() + "_tmp";
    let mut source_file = std::fs::File::open(source_path).expect("fopen");
    let mut source_buffer = Vec::new();
    source_file.read_to_end(&mut source_buffer).expect("fread_to_end");
    
    let tmp_file = std::fs::File::create(tmp_path.clone()).expect("fcreate");
    let mut encrypter = pr.new_encrypting_writer(Box::new(tmp_file), aad.as_bytes()).expect("fwriter");
    encrypter.write_all(&source_buffer).expect("fwrite_encrypt");
    
    let mut read_file = std::fs::File::open(tmp_path).expect("fopen second");
    let mut result_buffer = Vec::new(); 
    read_file.read_to_end(&mut result_buffer).expect("fread_to_end second");
    // Complete the encryption (process any remaining buffered plaintext).
    encrypter.close().expect("fclose");
    
    return result_buffer;
}


pub fn decrypt(
    source_path: String,
    keyset_path: String,
    aad: String,
) -> Vec<u8> {

    //https://github.com/project-oak/tink-rust/blob/main/streaming/README.md

    tink_streaming_aead::init();

    let mut reader = JsonReader::new(File::open(keyset_path).expect("fkey_open"));
    let kh = insecure::read(&mut reader).expect("fhandle");
    let pr = tink_streaming_aead::new(&kh).expect("f_primitive");

    let source_file = std::fs::File::open(source_path).expect("fopen");
    let mut decrypter = pr.new_decrypting_reader(Box::new(source_file), aad.as_bytes()).expect("freader");

    // Read data from the decrypting-reader, in chunks to simulate streaming.
    let mut recovered = vec![];
    decrypter.read_to_end(&mut recovered).expect("fdecrypt");  
    return recovered;
}
```

At the src/saead.udl: (Consult [conversion table](https://mozilla.github.io/uniffi-rs/udl/builtin_types.html) for rust -> udl)
```
namespace saead {
  bytes encrypt(string source_path, string keyset_path, string aad);
  bytes decrypt(string source_path, string keyset_path, string aad);
};
```

## Creation of .xcframework

Create the following structure at the root:

```
saead.xcframework
├── ios-arm64
│   └── saead.framework
│       ├── Headers
│       │   ├── Export.h
│       │   └── saeadFFI.h
│       ├── Modules
│       │   └── module.modulemap
│       └── Info.plist
├── ios-arm64_x86_64-simulator
│   └── saead.framework
│       ├── Headers
│       │   ├── Export.h
│       │   └── saeadFFI.h
│       ├── Modules
│       │   └── module.modulemap
│       └── Info.plist
└── Info.plist
```
The contants of Info.plist under .framework folders: 
```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>CFBundleDevelopmentRegion</key>
        <string>en</string>
        <key>CFBundleExecutable</key>
        <string>Example</string>
        <key>CFBundleIdentifier</key>
        <string>com.user.Example</string>
        <key>CFBundleInfoDictionaryVersion</key>
        <string>6.0</string>
        <key>CFBundleName</key>
        <string>Example</string>
        <key>CFBundlePackageType</key>
        <string>FMWK</string>
        <key>CFBundleShortVersionString</key>
        <string>1.0</string>
        <key>CFBundleVersion</key>
        <string>0.0.1</string>
        <key>NSPrincipalClass</key>
        <string></string>
    </dict>
</plist>
```
You should replace the values "CFBundleExecutable" and "CFBundleName" with your library name, and "CFBundleIdentifier" with your identifier.

Once that is done you can make the "Info.plist" file for the root of the "Example.xcframework" folder. It should have these lines. Replace Example with the saead (your name)
```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>AvailableLibraries</key>
        <array>
            <dict>
                <key>LibraryIdentifier</key>
                <string>ios-arm64</string>
                <key>LibraryPath</key>
                <string>Example.framework</string>
                <key>SupportedArchitectures</key>
                <array>
                    <string>arm64</string>
                </array>
                <key>SupportedPlatform</key>
                <string>ios</string>
            </dict>
            <dict>
                <key>LibraryIdentifier</key>
                <string>ios-arm64_x86_64-simulator</string>
                <key>LibraryPath</key>
                <string>Example.framework</string>
                <key>SupportedArchitectures</key>
                <array>
                    <string>arm64</string>
                    <string>x86_64</string>
                </array>
                <key>SupportedPlatform</key>
                <string>ios</string>
                <key>SupportedPlatformVariant</key>
                <string>simulator</string>
            </dict>
        </array>
        <key>CFBundlePackageType</key>
        <string>XFWK</string>
        <key>XCFrameworkFormatVersion</key>
        <string>1.0</string>
    </dict>
</plist>
```

The `module.modulemap` files should have these lines.
```
framework module Example {
  umbrella header "Example.h"

  export *
  module * { export * }
}
```
"Export.h":
```
#include "saeadFFI.h"
```

Create make.sh file inside with 
```
set -e # Helps to give error info

# Project paths

RUST_PROJ="/Users/abai/Documents/Freelance/rust_saead/saead"
IOS_LIB="/Users/abai/Documents/Freelance/rust_saead/saead/saeadLib"

LOCAL_UDL="src/saead.udl"
UDL_NAME="saead"
FRAMEWORK_NAME="saead"
SWIFT_INTERFACE="saeadLib"

# Binary paths
PATH="$PATH:/Users/abai/.cargo/bin" # Adds the rust compiler
PATH="$PATH:/usr/local/bin" # Adds swiftformat to the path

cd "$RUST_PROJ"

# Compile the rust
cargo build --target aarch64-apple-ios
cargo build --target aarch64-apple-ios-sim
cargo build --target x86_64-apple-ios

# Remove old files if they exist
IOS_ARM64_FRAMEWORK="$FRAMEWORK_NAME.xcframework/ios-arm64/$FRAMEWORK_NAME.framework"
IOS_SIM_FRAMEWORK="$FRAMEWORK_NAME.xcframework/ios-arm64_x86_64-simulator/$FRAMEWORK_NAME.framework"

rm -f "$IOS_ARM64_FRAMEWORK/$FRAMEWORK_NAME"
rm -f "$IOS_ARM64_FRAMEWORK/Headers/${UDL_NAME}FFI.h"
rm -f "$IOS_SIM_FRAMEWORK/$FRAMEWORK_NAME"
rm -f "$IOS_SIM_FRAMEWORK/Headers/${UDL_NAME}FFI.h"

rm -f target/universal.a
rm -f include/ios/*

# Make dirs if it doesn't exist
mkdir -p include/ios

# UniFfi bindgen
cargo run --bin uniffi-bindgen generate "$LOCAL_UDL" --language swift --out-dir ./include/ios

# Make fat lib for sims
lipo -create \
    "target/aarch64-apple-ios-sim/debug/lib${UDL_NAME}.a" \
    "target/x86_64-apple-ios/debug/lib${UDL_NAME}.a" \
    -output target/universal.a

# Move binaries
cp "target/aarch64-apple-ios/debug/lib${UDL_NAME}.a" \
    "$IOS_ARM64_FRAMEWORK/$FRAMEWORK_NAME"
cp target/universal.a \
    "$IOS_SIM_FRAMEWORK/$FRAMEWORK_NAME"

# Move headers
cp "include/ios/${UDL_NAME}FFI.h" \
    "$IOS_ARM64_FRAMEWORK/Headers/${UDL_NAME}FFI.h"
cp "include/ios/${UDL_NAME}FFI.h" \
    "$IOS_SIM_FRAMEWORK/Headers/${UDL_NAME}FFI.h"

# Move swift interface
sed "s/${UDL_NAME}FFI/$FRAMEWORK_NAME/g" "include/ios/$UDL_NAME.swift" > "include/ios/$SWIFT_INTERFACE.swift"
rm -f "$IOS_LIB/$SWIFT_INTERFACE.swift"
cp "include/ios/$SWIFT_INTERFACE.swift" "$IOS_LIB/$SWIFT_INTERFACE.swift"
```

# Xcode

Remove all non iOS targets since we haven't compiled binaries for them and choose the iOS version you want to support.

Then scroll down to "Frameworks, Libraries, and Embedded Content".

Then click the + symbol. Then in the new window click on "Add Other..." and then "Add Files...".

Then select the XCFrameworks folder you made in the rust library.

Then click on the Embed tab and make sure it's set to "Do Not Embed".

If it's not set to "Do Not Embed" the project will work in the simulator, but won't successfully build on an actual iPhone. I don't exactly know why this is, but I do suspect it has something to do with some security concerns?

Then make a new folder called "Lib" by right clicking the project index in the navigation tree and selecting "New Group" and calling it "Lib". Move `saeadLib.swift` inside that