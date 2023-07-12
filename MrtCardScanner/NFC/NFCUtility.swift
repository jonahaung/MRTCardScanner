//
//  NFCUtility.swift
//  EZ-PZ-iOS
//
//  Created by Yu Wang on 2020/6/23.
//  Copyright © 2020 ezlink. All rights reserved.
//

import Foundation
import CoreNFC

class NFCUtility {
    static var isAvailable: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        if #available(iOS 13.0, *), NFCNDEFReaderSession.readingAvailable {
            return true
        } else {
            return false
        }
        #endif
    }
    
    static func mapTxnCatagory(txnType: String) -> String {
        if "Retail Payment" == txnType {
            return "Retail"
        } else if "Miscellaneous" == txnType {
            return "Others"
        } else if "Bus Refund with AL Disable" == txnType
                    || "Bus Payment with AL Disable" == txnType
                    || "Rail Payment with AL Disable" == txnType {
            return "Public Transport"
        } else if "Purse and AL Disable" == txnType {
            return "Block Card"
        } else if "AL Enable" == txnType || "AL Disable" == txnType {
            return "EZ-Reload"
        } else if "Bus Refund" == txnType {
            return "Public Transport"
        } else if "Add Value" == txnType {
            return "Top Up"
        } else if "Cash back" == txnType {
            return "Refund"
        } else if "VEP Payment" == txnType {
            return "VEP"
        } else if "EZL Debit" == txnType {
            return "Card Purchase"
        } else if "Bus Payment" == txnType || "Rail Payment" == txnType {
            return "Public Transport"
        } else if "Purse Disable" == txnType {
            return "Block Card"
        } else if "EPS TBC (Time Based Charging)" == txnType {
            return "EPS (Carparks)"
        } else if "ERP DBC (Distance Based Charging)" == txnType
                    || "ERP CBC (Congestion Based Charging)" == txnType {
            return "ERP"
        } else {
            return ""
        }
    }
    
    static func mapMerchant(txnType: String, userData: String) -> String {
        if "AL Disable" == txnType {
            return "EZ-Reload Termination"
        } else if "Application of EZ-Reload (S20)" ==  userData {
            return "EZ-Reload Application(S20)"
        } else if "Application of EZ-Reload (S30)" ==  userData {
            return "EZ-Reload Application(S30)"
        } else if "Application of EZ-Reload (S40)" ==  userData {
            return "EZ-Reload Application(S40)"
        } else if "Application of EZ-Reload (S50)" ==  userData {
            return "EZ-Reload Application(S50)"
        } else if "EZ-Reload successfully activated" ==  userData {
            return "EZ-Reload Activation"
        } else if userData.trimString.isEmpty {
            return "Unknown"
        } else {
            return  userData
        }
    }
    
    static func mapAmount(_ amountWithCurrency: String) -> String {
        let amountStr = amountWithCurrency.replacingOccurrences(of: "$", with: "")
        guard let amount = Double(amountStr) else { return "N.A." }
        if amount > 0 {
            return "+\(amountWithCurrency)"
        } else {
            return "\(amountWithCurrency)"
        }
    }
    
    static func mapTime(txnTime: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy hh:mm:ss"
        guard let date = formatter.date(from: txnTime) else { return txnTime }
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        formatter.dateStyle = .medium
        formatter.dateFormat = "dd/MM/yyyy hh:mm a"
        return formatter.string(from: date)
    }
}

extension String {
    var trimString: String {
        return self.trimmingCharacters(in: CharacterSet(charactersIn: " "))
    }
}
