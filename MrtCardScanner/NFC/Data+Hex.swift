//
//  NFCISO7816Tag+.swift
//  EZ-PZ-iOS
//
//  Created by Yu Wang on 2020/6/11.
//  Copyright © 2020 ezlink. All rights reserved.
//

import Foundation

// Convert Hex String to Data And Vise Versa
extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hexString.index(hexString.startIndex, offsetBy: i*2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
    func toHex() -> [String] {
        return [UInt8](self)
            .map { String($0, radix: 16, uppercase: true) }
            .map { $0.count == 1 ? "0\($0)" : $0 }
    }
}
