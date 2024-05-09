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
