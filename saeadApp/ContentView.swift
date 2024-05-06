//
//  ContentView.swift
//  saeadApp
//
//  Created by Abai on 6/5/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
            Button("Test") {
                test()
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

func test() {
    let key = """
{
"key": [
{
  "keyData": {
    "keyMaterialType": "SYMMETRIC",
    "typeUrl": "type.googleapis.com/google.crypto.tink.AesGcmHkdfStreamingKey",
    "value": "EggIgIBAEBAYAxoQKdO3/xvlH3OxyoK1MIG4IA=="
  },
  "keyId": 1069226562,
  "outputPrefixType": "RAW",
  "status": "ENABLED"
}
],
"primaryKeyId": 1069226562
}
"""
    let keysetPath = getFilePath(fileName: "key.json")
    let plainFilePath = getFilePath(fileName: "plain.txt")
    let encryptedFilePath = getFilePath(fileName: "encrypted")
    let decryptedFilePath = getFilePath(fileName: "decrypted")
    
    writeData(filePath:keysetPath, dataToWrite: key)
    writeData(filePath:plainFilePath, dataToWrite: "Hi from rust tink")
    
    
    let _ = print(encrypt(plainPath: plainFilePath.absoluteString, encryptPath: encryptedFilePath.absoluteString, keysetPath: keysetPath.absoluteString, aad: "@Secret(|)Piano@"))

    let _ = print(decrypt(encryptPath: encryptedFilePath.absoluteString, decryptPath: decryptedFilePath.absoluteString, keysetPath: keysetPath.absoluteString, aad: "@Secret(|)Piano@"))
}

func getFilePath(fileName: String) -> URL {
    let filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
    return filePath
}

func writeData(filePath: URL, dataToWrite: String) {
    do {
      let file = try FileHandle(forWritingTo: filePath)
      
      let key = dataToWrite.data(using: .utf8)!
      file.write(key)
      
      file.closeFile()
      print("created key")
    } catch {
      print("Error key: \(error)")
    }
}
