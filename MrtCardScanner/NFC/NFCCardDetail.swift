//
//  NFCCardTransaction+.swift
//  EZ-PZ-iOS
//
//  Created by Yu Wang on 2020/7/17.
//  Copyright © 2020 ezlink. All rights reserved.
//
import UIKit


enum EZLinkCardStatus: String {
    case notBlocked = "normal"
    case blocked = "blocked"
    case pendingBlock = "pending block"
    
    var shouldShowBanner: Bool {
        switch self {
        case .blocked, .pendingBlock: return true
        case .notBlocked: return false
        }
    }
}

struct NFCCardTransaction: Codable {
    let txnType: String
    let txnAmt: String
    let txnDatetime: String
    let txnUserData: String
    let txnALAmt: String
    
    private enum CodingKeys: String, CodingKey {
            case txnAmt = "txn_amt"
            case txnDatetime = "txn_datetime"
            case txnALAmt = "txn_a_l_amt"
            case txnUserData = "txn_user_data"
            case txnType = "txn_type"
    }
}
enum EZLinkCardProfileType: String {
    case motoring = "Motoring"
}

struct NFCCardDetail: Codable {
    
    let can: String
    let purseBalance: String
    let purseBalanceInt: UInt64
    let expiryDate: String
    let autoloadStatus: String
    let purseStatus: String
    let autoloadAmount: String
    let cardProfile: String
    let historyRecordNum: UInt8
    let lastTxn: NFCCardTransaction?
    let txnHistory: [NFCCardTransaction]?
    
    var cardStatusFromServer: EZLinkCardStatus?
    var profileType: EZLinkCardProfileType?
    private enum CodingKeys: String, CodingKey {
        case cardProfile = "card_profile"
        case purseBalanceInt = "int_purse_balance"
        case expiryDate = "expiry_date"
        case lastTxn = "last_txn"
        case purseBalance = "purse_balance"
        case purseStatus = "status"
        case can
        case historyRecordNum = "history_record_num"
        case autoloadStatus = "autoload_status"
        case autoloadAmount = "auloload_amount"
        case txnHistory = "txn_history"
    }
    
    // swiftlint:disable line_length
    internal init(can: String, purseBalance: String, purseBalanceInt: UInt64, expiryDate: String, autoloadStatus: String, purseStatus: String, autoloadAmount: String, cardProfile: String, historyRecordNum: UInt8, lastTxn: NFCCardTransaction?, txnHistory: [NFCCardTransaction]?, cardStatusFromServer: EZLinkCardStatus? = nil, profileType: EZLinkCardProfileType? = nil) {
        self.can = can
        self.purseBalance = purseBalance
        self.purseBalanceInt = purseBalanceInt
        self.expiryDate = expiryDate
        self.autoloadStatus = autoloadStatus
        self.purseStatus = purseStatus
        self.autoloadAmount = autoloadAmount
        self.cardProfile = cardProfile
        self.historyRecordNum = historyRecordNum
        self.lastTxn = lastTxn
        self.txnHistory = txnHistory
        self.cardStatusFromServer = cardStatusFromServer
        self.profileType = profileType
    }
    
    init(hexData: Data, txnLogHexData: [Data]) {
        let respStr = hexData.toHex().joined()
        can = respStr.substring(8 * 2, 16 * 2)
        purseBalance = NFCCardDetail.getAmount(temp: respStr.substring(2 * 2, 5 * 2), typeHexStr: "")
        purseBalanceInt = NFCCardDetail.getAmountInt(temp: respStr.substring(2 * 2, 5 * 2), txnType: "")
        expiryDate = NFCCardDetail.getDate(respStr.substring(2 * 24, 2 * 26))
        autoloadStatus = NFCCardDetail.getALStatus(respStr.substring(2 * 1, 2 * 2))
        purseStatus = NFCCardDetail.getPurseStatus(respStr.substring(2 * 1, 2 * 2))
        autoloadAmount = NFCCardDetail.getALAmount(respStr.substring(2 * 1, 2 * 2), respStr.substring(2 * 5, 2 * 8))
        cardProfile = NFCCardDetail.getCardProfile(respStr.substring(2 * 66, 2 * 67))
        historyRecordNum = [UInt8](hexData)[40]
        if !respStr.substring(0, 2).elementsEqual("03") {
            let lastTransactionStr = respStr.substring(2 * 46, 2 * 54)
            let baKeyword: [UInt8] = Array([UInt8](hexData)[46 + 8..<46 + 8 + 8])
            lastTxn = NFCCardDetail.getTxnLog(transactionStr: lastTransactionStr,
                                              userData: baKeyword,
                                              autoloadAmount: autoloadAmount)
        } else {
            lastTxn = nil
        }
        
        if txnLogHexData.count > 0 {
            let ALAmount = NFCCardDetail.getALAmount(respStr.substring(2 * 1, 2 * 2), respStr.substring(2 * 5, 2 * 8))
            txnHistory = txnLogHexData.compactMap { txnLogData -> NFCCardTransaction? in
                guard txnLogData.count >= 16 else { return nil }
                let tnxStr = txnLogData.toHex().joined()
                let baKeyword: [UInt8] = Array([UInt8](txnLogData)[8..<16])
                return NFCCardDetail.getTxnLog(transactionStr: tnxStr,
                                               userData: baKeyword,
                                               autoloadAmount: ALAmount)
            }
        } else {
            txnHistory = nil
        }
    }
}

extension NFCCardDetail {
    static func getAmount(temp: String, typeHexStr: String) -> String {
        if typeHexStr.hasPrefix("F0") // miscellaneous txn
            || typeHexStr.hasPrefix("83") // purse diable txn
            || typeHexStr.hasPrefix("11") { // autoload disable txn
            return "N.A."
        }
        if temp.hasPrefix("0") {
            var index = 0
            while index < temp.count - 1 {
                if temp.substring(index, index+1).first == "0" {
                    index += 1
                } else {
                    break
                }
            }
            if let j = UInt64(temp.substring(index), radix: 16),
                let result = NSNumber(value: Double(j) * 0.01).currencyFormat() {
                return result
            } else {
                return "N.A."
            }
        } else {
            let max = UInt64("FFFFFF", radix: 16)!
            guard let min = UInt64(temp, radix: 16) else {
                return ""
            }
            let bal = max - min + 1
            return "-" + (NSNumber(value: Double(bal) * 0.01).currencyFormat() ?? "")
        }
    }

    static func getAmountInt(temp: String, txnType: String) -> UInt64 {
        if txnType.hasPrefix("F0") // miscellaneous txn
            || txnType.hasPrefix("83") // purse diable txn
            || txnType.hasPrefix("11") { // autoload disable txn
            return 0
        }
        
        if temp.hasPrefix("0") {
            var index = 0
            while index < temp.count - 1 {
                if temp.substring(index, index+1).first == "0" {
                    index += 1
                } else {
                    break
                }
            }
            if let j = UInt64(temp.substring(index), radix: 16) {
                return j
            } else {
                return 0
            }
        } else {
            let max = UInt64("FFFFFF", radix: 16)!
            guard let min = UInt64(temp, radix: 16) else {
                return 0
            }
            let bal = max - min + 1
            return bal
        }
    }

    static func getDate(_ temp: String) -> String {
        guard let j = UInt64(temp, radix: 16) else { return "" }
        // added seconds between 1995 and 1970
        let seconds: TimeInterval = (Double(j) + 9131) * 86400
        let date = Date(timeIntervalSince1970: seconds)
        let format = DateFormatter()
        format.dateFormat = "dd/MM/yyyy"
        return format.string(from: date)
    }

    static func getDateTime(_ temp: String) -> String {
        guard let j = UInt64(temp, radix: 16) else { return "" }
        // added seconds between 1995 and 1970
        // then minused 8 hours
        let seconds: TimeInterval = Double(j) + 9131 * 86400 - (8 * 60 * 60)
        let date = Date(timeIntervalSince1970: seconds)
        let format = DateFormatter()
        format.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return format.string(from: date)
    }

    static func getALStatus(_ temp: String) -> String {
        guard let j = UInt8(temp, radix: 16) else { return "" }
        if j&0x01 == 0 {
            return "N.A."
        }
        if j&0x02 == 0 {
            return "Not Enabled"
        }
        return "Enabled"
    }

    static func getPurseStatus(_ temp: String) -> String {
        guard let j = UInt8(temp, radix: 16) else { return "" }
        if j&0x01 == 0 {
            return "Not Enabled"
        }
        return "Enabled"
    }

    static func getALAmount(_ purseStatus: String, _ amt: String) -> String {
        guard let j = UInt8(purseStatus, radix: 16) else { return "" }
        if j&0x01 == 0 {
            return "N.A."
        }
        if j&0x02 == 0 {
            return "N.A."
        }
        return getAmount(temp: amt, typeHexStr: "")
    }

    static func getTypeString(_ typeStr: String) -> String {
        if typeStr.hasSuffix("A0") {
            return "Retail Payment"
        } else if typeStr.hasSuffix("F0") {
            return "Miscellaneous"
        } else if typeStr.hasSuffix("87") {
            return "Bus Refund with AL Disable"
        } else if typeStr.hasSuffix("86") {
            return "Bus Payment with AL Disable"
        } else if typeStr.hasSuffix("85") {
            return "Rail Payment with AL Disable"
        } else if typeStr.hasSuffix("84") {
            return "Purse and AL Disable"
        } else if typeStr.hasSuffix("83") {
            return "AL Disable"
        } else if typeStr.hasSuffix("76") {
            return "Bus Refund"
        } else if typeStr.hasSuffix("75") {
            return "Add Value"
        } else if typeStr.hasSuffix("66") {
            return "Cash back"
        } else if typeStr.hasSuffix("3B") {
            return "VEP Payment"
        } else if typeStr.hasSuffix("32") {
            return "EZL Debit"
        } else if typeStr.hasSuffix("31") {
            return "Bus Payment"
        } else if typeStr.hasSuffix("30") {
            return "Rail Payment"
        } else if typeStr.hasSuffix("11") {
            return "Purse Disable"
        } else if typeStr.hasSuffix("09") {
            return "EPS TBC (Time Based Charging)"
        } else if typeStr.hasSuffix("08") {
            return "ERP DBC (Distance Based Charging)"
        } else if typeStr.hasSuffix("07") {
            return "ERP CBC (Congestion Based Charging)"
        } else {
            return typeStr
        }
    }

    static func getCharFromHex(_ bytes: [UInt8]) -> String {
        return String(bytes: bytes, encoding: .ascii) ?? ""
    }

    static func getCardProfile(_ purseStatus: String) -> String {
        guard let j = UInt8(purseStatus, radix: 16) else { return "" }
        // let cardRefundStatus = j >> 6 & 0x03
        let cardProfileType = j & 0x3f
        return "\(cardProfileType)"
    }

    static func ERPCBC(_ userData: [UInt8]) -> String {
        guard userData.count == 8 else {
            return ""
        }
        return Array(userData[4...5])
            .map { String($0, radix: 16, uppercase: true) }
            .map { $0.count == 1 ? "0\($0)" : $0 }
            .joined()
    }

    static func EPSTBC(_ userData: [UInt8]) -> String {
        guard userData.count == 8 else {
            return ""
        }
        return Array(userData[3...4])
            .map { String($0, radix: 16, uppercase: true) }
            .map { $0.count == 1 ? "0\($0)" : $0 }
            .joined()
    }

    static func getTxnLog(transactionStr: String, userData: [UInt8], autoloadAmount: String) -> NFCCardTransaction? {
        guard !transactionStr.hasPrefix("00000000") else { return nil }
        let typeHexStr = transactionStr.substring(0, 2)
        let txnType = getTypeString(typeHexStr)
        let txnAmt = getAmount(temp: transactionStr.substring(2, 2 * 4), typeHexStr: typeHexStr)
        
        let dateStr = transactionStr.substring(2 * 4, 2 * 8)
        let txnDatetime = getDateTime(dateStr)
        let txnUserData: String = {
            let char = getCharFromHex(userData)
            if typeHexStr.hasSuffix("07") { // ERP CBC
                return ERPCBC(userData)
            } else if typeHexStr.hasSuffix("08") { // ERP DBC
                return char
            } else if typeHexStr.hasSuffix("09") {
                return EPSTBC(userData)
            }
            return char
        }()
        let txnALAmt: String
        if userData[7]&0x01 == 1 { // auto load
            txnALAmt = autoloadAmount
        } else {
            txnALAmt = "$0.00"
        }
        
        return NFCCardTransaction(txnType: txnType,
                                  txnAmt: txnAmt,
                                  txnDatetime: txnDatetime,
                                  txnUserData: txnUserData,
                                  txnALAmt: txnALAmt)
    }

    static func getTxnHistory(historyRecordNum: UInt8) -> [NFCCardTransaction]? {
        guard historyRecordNum > 0 else { return nil }
        
        return nil
    }
}

extension NFCCardDetail {
    var formattedCan: String { can.formattedCardNumber }
    var formattedBalance: String { purseBalance }
    var formattedExpireDate: String { expiryDate }
    var status: EZLinkCardStatus {
        return cardStatusFromServer ??
            (purseStatus == "Enabled" ? EZLinkCardStatus.notBlocked : EZLinkCardStatus.blocked)
    }
    var isExpired: Bool {
        var config = DatePickerConfiguration.default
        guard let date = config.dateFormatterForDisplay.date(from: expiryDate) else {
            return false
        }
        return date.timeIntervalSince1970 < Date().timeIntervalSince1970
    }
    var isCCCard: Bool { EZLinkCardType.isConcessionCard(can) }
    var type: EZLinkCardType { return .CBT }
    var balanceStatus: EZLinkCardBalanceStatus {
        if purseBalanceInt <= 0 {
            return .OVERDUE
        } else if purseBalanceInt < 300 {
            return .LIMITED
        } else {
            return .SUFFICENT
        }
    }
    var cardProfileType: EZLinkCardProfileType? { profileType }
}


extension String {
    var isFinCodeValid: Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", "^[S,T,G,F]\\d{7}[A-Z]$")
        return predicate.evaluate(with: self)
    }

    var isPasswordValid: Bool {
        let regStr = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,20}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regStr)
        return predicate.evaluate(with: self)
    }

    var isNameValid: Bool {
        return self.trimString.count > 0
    }

    var trimString: String {
        return self.trimmingCharacters(in: CharacterSet(charactersIn: " "))
    }

    var isEmailValid: Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", "^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+$")
        return predicate.evaluate(with: self)
    }

    var isPostalVaild: Bool {
        return self.count == 0 || self.count == 6
    }

    var isPhoneNumberValid: Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", "^[0-9]{8}$")
        return predicate.evaluate(with: self)
    }

    var isDigitsOnly: Bool {
        return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: self))
    }
    
    var numericOnly: String {
      return components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }

    var isValidSGPhoneNumber: Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", "^[89][0-9]{7}$")
        return predicate.evaluate(with: self)
    }
    
    var sgMobileNumberFormattable: (Bool, String) {
        let noSpaces = removeAllSpaces
        let numericsOnly = noSpaces.numericOnly
        guard numericsOnly.count == 8 || numericsOnly.count == 10 else { return (false, self) }
        
        var localNumberFormat = numericsOnly
        if numericsOnly.count == 10 {
            let prefix = String(numericOnly.prefix(2))
            guard prefix == "65" else { return (false, self) }
            localNumberFormat = String(numericsOnly.dropFirst(2))
        }
        let isValid = localNumberFormat.isValidSGPhoneNumber
        guard isValid else { return (false, self) }
        return (true, localNumberFormat)
    }

    var isVehicleNumberValid: Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", "(?![A-Z]+$)[A-Z][A-Z0-9]+[A-Z]")
        return predicate.evaluate(with: self)
    }

    var isPostalCodeValid: Bool {
        return self.count == 6
    }

    var formattedPhoneNumber: String {
        let endIndex = self.index(self.startIndex, offsetBy: 3)
        let startIndex = self.index(self.endIndex, offsetBy: -4)

        return "\(String(self[...endIndex])) \(String(self[startIndex...]))"
    }

    var uppercaseFirstCharacter: String {
        let wordArray = self.components(separatedBy: " ")
        if wordArray.count == 1 || (wordArray.count > 1 && wordArray.last!.isEmpty) {
            return self.capitalized
        }
        return wordArray.reduce("") { (result, word) -> String in
            "\(result) \(word.capitalized)".trimString
        }
    }

    var removeResidualInternalSpaces: String {
        let wordArray = self.components(separatedBy: " ")
        if wordArray.count == 1 || (wordArray.count > 1 && wordArray.last!.isEmpty) {
            return self
        }
        return wordArray.reduce("") { (result, word) -> String in
            "\(result) \(word)".trimString
        }
    }

    var removeAllSpaces: String {
        return self.replacingOccurrences(of: " ", with: "")
    }

    var maskedFinCode: String {
        if self.isFinCodeValid {
            let index = self.index(self.endIndex, offsetBy: -4)
            return "****\(String(self[index...]))"
        }
        return ""
    }

    var maskedPhoneNumber: String {
        let startIndex = self.index(self.endIndex, offsetBy: -4)
        return "**** \(self[startIndex...])"
    }

    var maskedEmailAddress: String {
        guard let emailName = self.split(separator: "@").first else {return ""}
        guard let emailSuffix = self.split(separator: "@").last else {return ""}
        guard let firstCharater = emailName.first else {return ""}
        var maskedEmailName = ""
        if emailName.count > 1 {
            maskedEmailName = emailName.suffix(from: String.Index(utf16Offset: 1, in: emailName)).reduce("", { (result, _) -> String in
                return result + "*"
            })
        }
        return String(firstCharater) + maskedEmailName + "@" + String(emailSuffix)
    }

    var formattedCardNumber: String {
        var cardNumber = self
        for item in [4, 9, 14] where cardNumber.count > item {
            cardNumber.insert(" ", at: cardNumber.index(cardNumber.startIndex, offsetBy: item))
        }
        return cardNumber
    }

    var lastFourDigits: String {
        guard self.count > 4 else { return self }
        let index = self.index(self.endIndex, offsetBy: -4)
        return "\(self[index...])"
    }

    var formattedArnCode: String {
        var arnCode = self
        for item in [4, 9, 14] where arnCode.count > item {
            arnCode.insert(" ", at: arnCode.index(arnCode.startIndex, offsetBy: item))
        }
        return arnCode
    }

    func formateStringByCount(maxCount: Int) -> String {
        if self.count > maxCount {
            let index = self.index(self.startIndex, offsetBy: maxCount - 1)
            return String(self[...index])
        }
        return self
    }

    func pregReplace(pattern: String, with: String, options: NSRegularExpression.Options = []) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return "" }
        return regex.stringByReplacingMatches(in: self, options: [], range: NSRange(location: 0, length: self.count), withTemplate: with)
    }

    func getSubStringByStart(offset: Int) -> String {
        let index = self.index(self.startIndex, offsetBy: min(offset, count-1))
        return String(self[...index])
    }
    
    func getSubStringFromStartingIndex(startingIndex: Int) -> String? {
//        guard isNotEmpty, count >= startingIndex else { return nil }
        return String(self[self.index(startIndex, offsetBy: startingIndex)...])
    }

    func getSubStringByEnd(offset: Int) -> String {
        let index = self.index(self.endIndex, offsetBy: -offset)
        return String(self[index...])
    }

    func getSubStringByIndex(startOffset: Int, endOffset: Int) -> String {
        let indexStart = self.index(self.startIndex, offsetBy: startOffset)
        let indexEnd = self.index(self.endIndex, offsetBy: -endOffset)
        return String(self[indexStart...indexEnd])
    }

    func getIndexString(_ index: Int) -> String {
        return String(self[self.index(self.startIndex, offsetBy: index)])
    }

    func deleteLastLetter() -> String {
        if self.count == 1 || isEmpty {
            return ""
        }
        return getSubStringByStart(offset: count - 2)
    }

    func isEmptyOrWhitespace() -> Bool {
        return self.isEmpty || self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    #if canImport(Foundation)
      ///
      ///        var str = "it's%20easy%20to%20decode%20strings"
      ///        str.urlDecode()
      ///        print(str) // prints "it's easy to decode strings"
      ///
      @discardableResult
      mutating func urlDecode() -> String {
          if let decoded = removingPercentEncoding {
              self = decoded
          }
          return self
      }
      #endif

      #if canImport(Foundation)
      ///
      ///        var str = "it's easy to encode strings"
      ///        str.urlEncode()
      ///        print(str) // prints "it's%20easy%20to%20encode%20strings"
      ///
      @discardableResult
      mutating func urlEncode() -> String {
          if let encoded = addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
              self = encoded
          }
          return self
      }
      #endif
    
    #if canImport(Foundation)
    /// Include "http" and "https" url
    var isValidNetWorkURL: Bool {
        guard let url = URL(string: self) else {
            return false
        }
        return url.scheme == "http" || url.scheme == "https"
    }
    #endif
    
    func substring(_ start: Int, _ end: Int? = nil) -> String {
        let startIndex = index(self.startIndex, offsetBy: start)
        let endIndex = end != nil ? index(self.startIndex, offsetBy: min(end!, self.count)) : self.endIndex
        return String(self[startIndex..<endIndex])
    }
    
    func substring(_ r: Range<Int>) -> String {
        let fromIndex = self.index(self.startIndex, offsetBy: r.lowerBound)
        let toIndex = self.index(self.startIndex, offsetBy: r.upperBound)
        let indexRange = Range<String.Index>(uncheckedBounds: (lower: fromIndex, upper: toIndex))
        return String(self[indexRange])
    }
}

struct DatePickerConfiguration {
    lazy var dateFormatterForDatePicker: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ddMMyyyy"
        return formatter
    }()

    lazy var dateFormatterForDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    var maximumDate: Date
    var minimumDate: Date
    var currentDate: Date

    init(currentDate: Date, maximumDate: Date, minimumDate: Date) {
        self.currentDate = currentDate
        self.maximumDate = maximumDate
        self.minimumDate = minimumDate
    }

    mutating func birthdayFormatter(_ birthday: String) -> String {
        if birthday.trimString.isEmpty {
            return ""
        }
        let birthdayDate = dateFormatterForDatePicker.date(from: birthday) ?? Date()
        return dateFormatterForDisplay.string(from: birthdayDate)
    }

    static var `default`: DatePickerConfiguration {
        var configuration = DatePickerConfiguration(currentDate: Date(), maximumDate: Date(), minimumDate: Date())
        let today = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: today)
        let month = calendar.component(.month, from: today)
        let day = calendar.component(.day, from: today)
        if let current = configuration.dateFormatterForDisplay.date(from: "\(day)/\(month)/\(year - 10)") {
            configuration.currentDate = current
        }
        configuration.maximumDate = today
        configuration.minimumDate = configuration.dateFormatterForDisplay.date(from: "01/01/1900")!
        return configuration
    }
}
enum EZLinkCardType: String {
    case ABT
    case CBT
    
    /// Identify whether an ez-link card is a concession card or not
    static func isConcessionCard(_ canId: String) -> Bool {
        guard canId.count >= 4 else {
            return false
        }
        let fourNumber = Int(canId.getSubStringByStart(offset: 3)) ?? 0
        return fourNumber >= 8000 && fourNumber <= 8009
    }
    
    static func isNetsCard(_ canId: String) -> Bool {
        let fourNumber = Int(canId.components(separatedBy: " ")[0]) ?? 0
        return fourNumber >= 1111 && fourNumber <= 1120
    }
    
    static func isABTCCCard(canId: String, cardType: String) -> Bool {
        guard canId.isConcessionCard, let aCardType = EZLinkCardType(rawValue: cardType),
              aCardType == .ABT else { return false }
        return true
    }
    
    func isCBTDefault(canId: String) -> Bool {
        guard self == .CBT else { return false }
        switch EZLinkCardVariety(canId: canId) {
        case .defalut(let isEzMotoringCard) where isEzMotoringCard == false:
            return true
        default:
            return false
        }
    }
}
//
//struct EZLinkCardList {
//    var ABTCards: [EZLinkCardModel]
//    var CBTCards: [EZLinkCardModel]
//}

extension String {
    var isConcessionCard: Bool {
        return EZLinkCardType.isConcessionCard(self)
    }
}
enum EZLinkCardBalanceStatus: String {
    case OVERDUE
    case LIMITED
    case SUFFICENT
}

enum EZLinkCardVariety {
    
    case smrt
    case unlimited
    case liveFresh
    case everyday
    case dbsyog
    case dbssutd
    case icbc
    case fevo
    case passion
    case defalut(isEzMotoringCard: Bool)
    
    init(canId: String, cardProfileType: EZLinkCardProfileType? = nil) {
        if canId <= "1009309999999999" && canId >= "1009300000000000" {
            self = .smrt
        } else if canId <= "1009459999999999" && canId >= "1009450000000000" {
            self = .unlimited
        } else if canId <= "1009609999999999" && canId >= "1009600000000000" {
            self = .liveFresh
        } else if canId <= "1009619999999999" && canId >= "1009610000000000" {
            self = .dbsyog
        } else if canId <= "1009629999999999" && canId >= "1009620000000000" {
            self = .everyday
        } else if canId <= "1009659999999999" && canId >= "1009650000000000" {
            self = .dbssutd
        } else if canId <= "1009679999999999" && canId >= "1009670000000000" {
            self = .icbc
        } else if canId <= "1009709999999999" && canId >= "1009700000000000" {
            self = .fevo
        } else if canId <= "1009729999999999" && canId >= "1009710000000000" {
            self = .passion
        } else if canId <= "1000150015075249" && canId >= "1000150013065250" {
            self = .passion
        } else {
//            if (canId <= "1008303009999999" && canId >= "1008303000000000") ||
//                (canId <= "1008304009999999" && canId >= "1008304000000000") {
            if cardProfileType == .motoring {
                self = .defalut(isEzMotoringCard: true)
            } else {
                self = .defalut(isEzMotoringCard: false)
            }
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .liveFresh, .unlimited, .dbsyog, .fevo:
            return .black
        default:
            return .white
        }
    }

    
}

//UI Specific
extension EZLinkCardVariety {
    var showRetailIcon: Bool {
        switch self {
        case .defalut(let isEzMotoringCard):
            return !isEzMotoringCard
        default:
            return false
        }
    }
    
    var showTransitIcon: Bool {
        switch self {
        case .defalut(let isEzMotoringCard):
            return !isEzMotoringCard
        default:
            return false
        }
    }
    
    var showMotoringIcon: Bool {
        switch self {
        case .defalut:
            return true
        default:
            return false
        }
    }
    
    var showMotoringOnlyLabel: Bool {
        switch self {
        case .defalut(let isEzMotoringCard):
            return isEzMotoringCard
        default:
            return false
        }
    }
}
