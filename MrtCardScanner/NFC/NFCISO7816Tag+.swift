//
//  NFCISO7816Tag+.swift
//  EZ-PZ-iOS
//
//  Created by Yu Wang on 2020/6/11.
//  Copyright © 2020 ezlink. All rights reserved.
//

import Foundation
import CoreNFC

typealias APDUCommandCompletion = (Result<(resp: Data, sw1: String, sw2: String), Error>) -> Void
private let tagScanQeueue = DispatchQueue(label: "com.ezlink.EzLinkActivate.nfc", qos: .userInitiated)

@available(iOS 13.0, *)
extension NFCISO7816Tag {
    func sendCommand(cls: UInt8,
                     code: UInt8,
                     p1: UInt8,
                     p2: UInt8,
                     dataHexStr: String?,
                     responseLength: Int,
                     completion: @escaping APDUCommandCompletion) {
        let data: Data
        if let hexStr = dataHexStr, let hexData = Data(hexString: hexStr) {
            data = hexData
        } else {
            data = Data()
        }
        let apdu = NFCISO7816APDU(instructionClass: cls,
                                  instructionCode: code,
                                  p1Parameter: p1,
                                  p2Parameter: p2,
                                  data: data,
                                  expectedResponseLength: responseLength)
        
        tagScanQeueue.async {
            self.sendCommand(apdu: apdu) { (respData, sw1, sw2, error) in
                let sw1Str = String(sw1, radix: 16, uppercase: true)
                let sw2Str = String(sw2, radix: 16, uppercase: true)
               
                if let error = error {
                    
                    completion(Result.failure(error))
                } else {
                    completion(Result.success((respData, sw1Str, sw2Str)))
                }
               
            }
        }
    }
    
    func sendCommand(apdu: String, completion: @escaping APDUCommandCompletion) {
        let bytes = apdu.hexaData
        let dataStr: String?
        if apdu.count <= 10 {
            dataStr = nil
        } else {
            let startIndex = apdu.index(apdu.startIndex, offsetBy: 10)
            let endIndex = apdu.index(apdu.endIndex, offsetBy: -3)
            dataStr = String(apdu[startIndex...endIndex])
        }
        sendCommand(cls: bytes[0],
                    code: bytes[1],
                    p1: bytes[2],
                    p2: bytes[3],
                    dataHexStr: dataStr,
                    responseLength: 256,
                    completion: completion)
    }
    
    func getChallenge(completion: @escaping APDUCommandCompletion) {
        sendCommand(cls: 0x00,
                    code: 0x84,
                    p1: 0x00,
                    p2: 0x00,
                    dataHexStr: nil,
                    responseLength: 0x08) { (result) in
            completion(result)
        }
    }
    
    func getTxn(index: UInt, completion: @escaping APDUCommandCompletion) {
        let indexDataStr: String? = {
            let extractedDataStr = String(index, radix: 16)
            return extractedDataStr.count > 1 ? extractedDataStr : "0\(extractedDataStr)"
        }()
        sendCommand(cls: 0x90,
                    code: 0x32,
                    p1: 0x03,
                    p2: 0x00,
                    dataHexStr: indexDataStr,
                    responseLength: 256,
                    completion: completion)
    }
}
