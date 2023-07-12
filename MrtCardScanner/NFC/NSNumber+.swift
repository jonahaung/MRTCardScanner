//
//  NSNumber+.swift
//  EZ-PZ-iOS
//
//  Created by Yu Wang on 2020/7/17.
//  Copyright © 2020 ezlink. All rights reserved.
//

import Foundation

extension NSNumber {
    func currencyFormat() -> String? {
        let format = NumberFormatter()
        format.numberStyle = .currency
        format.currencySymbol = "$"
        format.usesGroupingSeparator = true
        return format.string(from: self)
    }
}
