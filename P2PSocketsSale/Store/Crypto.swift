//
//  Crypto.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 12/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import Foundation


class Crypto {
    
    let publicKey = "MFswDQYJKoZIhvcNAQEBBQADSgAwRwJAXVjFBQChnDso3MZGaANu5YJ5vvCkYLmi\nu1qTRCJH4TloqgYbFvdBP+ThpFkVrLeXJSyFPSdm0UrMiyS3ybYoeQIDAQAB"
    
    let privateKey = "MIIBOAIBAAJAXVjFBQChnDso3MZGaANu5YJ5vvCkYLmiu1qTRCJH4TloqgYbFvdB\nP+ThpFkVrLeXJSyFPSdm0UrMiyS3ybYoeQIDAQABAkApkKN6DMPpizYwyGEFY7H3\npFeNvB2VrFNX1YcJqbIUCS+GoUG2U4TzCy6uUU6M0/w3eGuLmAflJpcAGqCy3KMZ\nAiEArZ9g6reDbeF8P9voe+3FODAt0cF5blojE779qfoYaBcCIQCJouT61Di5AtuA\nfKCzlq0YBvAcvF83G8a2wZN+MQy97wIgRBXQB7tXSuu1scUm8hJX2KTsEulwGRo3\nzzKCfvmYQJkCIH5P+VbcxsW8ApgTSCQopuhDDb9BfRyFKEP2uRZ5i1kPAiAmVizA\n1ncP9UgKfCyCl6ObPiZ4ZhsiI2X8K6CpTvOJjg=="
    
    func testEncrypt() {
        do {
            let message = try RSAUtils.encryptWithRSAPublicKey(str: "heeey", pubkeyBase64: publicKey)
            print("crypto")
            let str = NSString(data: message!, encoding: String.Encoding.utf8.rawValue)
            let dt = message as! NSData
            
            
            print(test ?? "is nil")
            
            
            let decrypted = try RSAUtils.decryptWithRSAPrivateKey(encryptedData: message!, privkeyBase64: privateKey)
            
            //NSLog("%@", NSData(bytes: message., length:1))
            
            print(decrypted ?? "decryption didnt work")
            let hey = String(data: decrypted!, encoding: .utf8)
            print(hey)
        } catch let error {
            
        }
    }
    
    
    
    
}
