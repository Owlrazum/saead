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
    
    let keyset = Bundle.main.url(forResource: "key", withExtension: "json")!.path(percentEncoded: false)
    let plain = Bundle.main.url(forResource: "plain", withExtension: "txt")!.path(percentEncoded: false)
    let encrypted = Bundle.main.url(forResource: "encrypted", withExtension: "")!.path(percentEncoded: false)
    
    let encryptResult = encrypt(sourcePath: plain, keysetPath: keyset, aad: "@Secret(|)Piano@")
    let decryptResult = decrypt(sourcePath: encrypted, keysetPath: keyset, aad: "@Secret(|)Piano@")
    print("===encrypt===", decryptResult)
    print("===decrypt===", decryptResult)
}
