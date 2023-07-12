//
//  ContentView.swift
//  MrtCardScanner
//
//  Created by Aung Ko Min on 10/7/23.
//

import Foundation

public extension NSNumber {
    func currencyFormat() -> String? {
        let format = NumberFormatter()
        format.numberStyle = .currency
        format.currencySymbol = "$"
        format.usesGroupingSeparator = true
        return format.string(from: self)
    }
}
