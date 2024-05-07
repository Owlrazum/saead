use std::{
    fs::File,
    io::{Read, Write},
};

use tink_core::keyset::{JsonReader, Reader, insecure};

uniffi::include_scaffolding!("saead"); // "example" is the name of the .udl file 

const CHUNK_SIZE: usize = 4096;

pub fn encrypt(
    source_file_path: String, 
    dist_file_path: String, 
    key_file_path: String,
    aad: String,
) -> String {

    //https://github.com/project-oak/tink-rust/blob/main/streaming/README.md

    tink_streaming_aead::init();

    let mut reader = JsonReader::new(File::open(key_file_path).expect("fkey_open"));
    let kh = insecure::read(&mut reader).expect("fhandle");

    // Get the primitive that uses the key material.
    let a = tink_streaming_aead::new(&kh).expect("f_primitive");

    let ct_file = std::fs::File::create(source_file_path.clone()).expect("fcreate");
    let mut w = a.new_encrypting_writer(Box::new(ct_file), aad.as_bytes()).expect("fwriter");

    let mut buffer = Vec::new();
    let mut pt_file = std::fs::File::open(dist_file_path).expect("fopen");
    let ct_size = pt_file.read_to_end(&mut buffer).expect("fread_to_end");
      // Write data to the encrypting-writer, in chunks to simulate streaming.
    let mut offset = 0;
    while offset < ct_size {
        let end = std::cmp::min(ct_size, offset + CHUNK_SIZE);
        let written = w.write(&buffer[offset..end]).expect("fwrite_encrypt");
        offset += written;
        // Can flush but it does nothing.
        w.flush().expect("fflush");
    }
    // Complete the encryption (process any remaining buffered plaintext).
    w.close().expect("fclose");

    return "OK".to_string();
}


pub fn decrypt(
    source_file_path: String, 
    dist_file_path: String, 
    key_file_path: String,
    aad: String,
) -> String {

    //https://github.com/project-oak/tink-rust/blob/main/streaming/README.md

    tink_streaming_aead::init();

    let mut reader = JsonReader::new(File::open(key_file_path).expect("fkey_open"));
    let kh = insecure::read(&mut reader).expect("fhandle");

    // Get the primitive that uses the key material.
    let a = tink_streaming_aead::new(&kh).expect("f_primitive");

    let ct_file = std::fs::File::open(source_file_path).expect("fopen");
    let mut r = a.new_decrypting_reader(Box::new(ct_file), aad.as_bytes()).expect("freader");

    // Read data from the decrypting-reader, in chunks to simulate streaming.
    let mut recovered = vec![];
    loop {
        let mut chunk = vec![0; CHUNK_SIZE];
        let len = r.read(&mut chunk).expect("fdecrypt");
        if len == 0 {
            break;
        }
        recovered.extend_from_slice(&chunk[..len]);
    }

    let mut dist_file = std::fs::File::create(dist_file_path.clone()).expect("fopen");
    dist_file.write_all(&recovered).expect("fwrite");
    
    return "OK".to_string();
}
