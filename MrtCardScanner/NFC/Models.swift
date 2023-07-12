//
//  Models.swift
//  MrtCardScanner
//
//  Created by Aung Ko Min on 12/7/23.
//

import UIKit

public enum CardTapStepMapping: Float {
    case tagConnected = 0
    case fetchSyncStatusSuccess = 1
    case startValidateCardInfo = 2
    case startGetChallenge = 3
    case startFetchReadSecureCommand = 4
    case startGetReadSecureResult = 5
    case startFetchReadSecureAuthResult = 6
    case startFetchTopUpCommand = 7
    case startGetTopUpResult = 8
    case startFetchTopUpValidationResult = 9
    case startTroubleshooting = 9.1
}

public enum TopUpProcess {
    case validateCardInfo
    case getChallenge
    case fetchReadSecCommand(challenge: String)
    case getReadSecPurse(command: String)
    case fetchSecPurseValidationResult(purse: String)
    case fetchTopUpCommand(challenge: String)
    case getTopUpPurse(command: String)
    case fetchTxnValidationResult(purse: String)
    case getCardInfo
}

public struct NFCCardSecure: Codable {
    let cardRandom: String
    let terminalRandom: String
    let purseData: String
    private enum CodingKeys: String, CodingKey {
        case cardRandom = "card_random"
        case terminalRandom = "terminal_random"
        case purseData = "purse_data"
    }
}
public enum ExpressCardTapStepMapping: Float {
    case tagConnected = 1
    case getChallengeSuccess = 2
    case getCardInfoSuccess = 3
}


public enum NFCTapError: Error {
    case getChallengeFaild
    case reachMaximumAmount
    case wrongCard
    case fetchPurseFailed
    case getPurseFailed
    case getSecPurseFailed
    case fetchPurseValidationResultFailed
    case fetchTopUpCommandFailed
    case getTopUpResultFailed
    case fetchTopUpTransactionValidationResultFailed
    case getTroubleshootingTxnFailed
    case troubleshootingFailed
}


public struct NFCCardTransaction: Codable {
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

public struct ReadPurseSecureCmdResponse: Codable {
    let apdu: String
}

public struct NFCCardDetail: Codable {
    
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
    
    public init(hexData: Data, txnLogHexData: [Data]) {
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

public extension NFCCardDetail {
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

extension NFCCardDetail: EZLinkCardHeaderData {
    public var formattedCan: String { can.formattedCardNumber }
    public var formattedBalance: String { purseBalance }
    public var formattedExpireDate: String { expiryDate }
    public var status: EZLinkCardStatus {
        return cardStatusFromServer ??
            (purseStatus == "Enabled" ? EZLinkCardStatus.notBlocked : EZLinkCardStatus.blocked)
    }
    public var isExpired: Bool {
        var config = DatePickerConfiguration.default
        guard let date = config.dateFormatterForDisplay.date(from: expiryDate) else {
            return false
        }
        return date.timeIntervalSince1970 < Date().timeIntervalSince1970
    }
    public var isCCCard: Bool { EZLinkCardType.isConcessionCard(can) }
    public var type: EZLinkCardType { return .CBT }
    public var balanceStatus: EZLinkCardBalanceStatus {
        if purseBalanceInt <= 0 {
            return .OVERDUE
        } else if purseBalanceInt < 300 {
            return .LIMITED
        } else {
            return .SUFFICENT
        }
    }
    public var cardProfileType: EZLinkCardProfileType? { profileType }
}


public enum EZLinkCardType: String {
    
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

public extension String {
    var isConcessionCard: Bool {
        return EZLinkCardType.isConcessionCard(self)
    }
}
public enum EZLinkCardProfileType: String {
    case motoring = "Motoring"
}
public enum EZLinkCardVariety {
    
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
}

//UI Specific
public extension EZLinkCardVariety {
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


public protocol EZLinkCardProtocol {
    var canId: String { get }
    var cardName: String { get set }
    var cardStatus: String { get }
    var expiryDate: String { get }
    var availableBalance: String { get set }
    var autoTopUp: Bool { get }
    var expired: Bool { get }
    var statusMessage: String { get }
    var caseSubtype: String { get }
    var reportDate: String { get }
    var estimatedFare: String { get set }
    var type: EZLinkCardType { get }
    var balanceStatus: EZLinkCardBalanceStatus { get set }
    var hasIncompleteSyncStatus: Bool { get }
    var syncStatus: String? { get set }
    var syncAmount: String? { get set }
    var syncStartTime: String? { get set }
    var tappable: Bool { get }
    var _belongsToUser: Bool? { get }
    var cardProfileType: EZLinkCardProfileType? { get }
}

public extension EZLinkCardProtocol {
    var cardType: String {
        return type.rawValue
    }
    
    var belongsToUser: Bool? {
        if EZLinkCardType.isABTCCCard(canId: canId, cardType: type.rawValue) {
            return _belongsToUser
        }
        return true
    }
}

public struct EZLinkCardModel: EZLinkCardProtocol {
   
    public let canId: String
    public var cardName: String
    public var cardStatus: String
    public let expiryDate: String
    public var availableBalance: String
    public let autoTopUp: Bool
    public let expired: Bool
    public let statusMessage: String
    public var reportDate: String
    public var caseSubtype: String
    public var estimatedFare: String
    public let type: EZLinkCardType
    public var balanceStatus: EZLinkCardBalanceStatus
    public var syncStatus: String?
    public var syncAmount: String?
    public var syncStartTime: String?
    public var tappable: Bool
    public var requiresConsent: Bool?
    public var _belongsToUser: Bool?
    public var hasIncompleteSyncStatus: Bool {
        return syncAmount != nil && syncAmount?.isEmpty == false
    }
    public var cardProfileType: EZLinkCardProfileType?
    
    // swiftlint:disable line_length
    internal init(canId: String, cardName: String, cardStatus: String, expiryDate: String, availableBalance: String, autoTopUp: Bool, expired: Bool, statusMessage: String, reportDate: String, caseSubtype: String, estimatedFare: String, type: EZLinkCardType, balanceStatus: EZLinkCardBalanceStatus, syncStatus: String? = nil, syncAmount: String? = nil, syncStartTime: String? = nil, tappable: Bool, requiresConsent: Bool? = nil, belongsToUser: Bool? = nil, cardProfileType: EZLinkCardProfileType? = nil) {
        self.canId = canId
        self.cardName = cardName
        self.cardStatus = cardStatus
        self.expiryDate = expiryDate
        self.availableBalance = availableBalance
        self.autoTopUp = autoTopUp
        self.expired = expired
        self.statusMessage = statusMessage
        self.reportDate = reportDate
        self.caseSubtype = caseSubtype
        self.estimatedFare = estimatedFare
        self.type = type
        self.balanceStatus = balanceStatus
        self.syncStatus = syncStatus
        self.syncAmount = syncAmount
        self.syncStartTime = syncStartTime
        self.tappable = tappable
        self.requiresConsent = requiresConsent
        self._belongsToUser = belongsToUser
        self.cardProfileType = cardProfileType
    }
}

extension EZLinkCardModel {
    
}

extension EZLinkCardModel: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.canId == rhs.canId
    }
}

extension EZLinkCardModel: EZLinkCardHeaderData {
    public var formattedCan: String { canId.formattedCardNumber }
    public var formattedBalance: String { "$ \(availableBalance)" }
    public var formattedExpireDate: String {
        var dateConfig = DatePickerConfiguration.default
        let date = dateConfig.dateFormatterForDatePicker.date(from: expiryDate)
        var expireDateStr = ""
        if let displayDate = date {
            expireDateStr = dateConfig.dateFormatterForDisplay.string(from: displayDate)
        }
        return expireDateStr
    }
    public var isExpired: Bool { expired }
    public var status: EZLinkCardStatus { EZLinkCardStatus(rawValue: cardStatus) ?? EZLinkCardStatus.notBlocked }
    public var isCCCard: Bool { EZLinkCardType.isConcessionCard(canId) }
    
    var profileType: EZLinkCardProfileType? { cardProfileType }
}


public struct DatePickerConfiguration {
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

protocol ABTBlockRefundBannerVisiblityProtocol {
    
    var shouldShowBanner: Bool { get }
}

protocol EZLinkCardsDisplayNewCardProtocol: class {
    func showNewCard(_ card: EZLinkCardProtocol)
    func unableToAddDueToLimit()
    func displayCardList()
}

protocol PresenterNewPageDelegate: class {
    func showNewPage(vc: UIViewController)
}

public enum EZLinkCardStatus: String, ABTBlockRefundBannerVisiblityProtocol {
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

enum CardStatus: Int {
    case active = 0
    case inactive = 1
}


enum ATUStatus: String, Codable {
    case pendingActivation = "Pending Activation"
    case activated = "Activated"
    case pendingDeactivation = "Pending Deactivation"
    case deactivated = "Deactivated"
    case suspend = "Suspend"
    case unregistered = "Unregistered"
    case limited = "Limited"
    case unknown
    init(status: String) {
        switch status {
        case "Activated":
            self = ATUStatus.activated
        case "Pending Activation":
            self = ATUStatus.pendingActivation
        case "Pending Deactivation":
            self = ATUStatus.pendingDeactivation
        case "Deactivated":
            self = ATUStatus.deactivated
        case "Suspend":
            self = ATUStatus.suspend
        case "Unregistered":
            self = ATUStatus.unregistered
        case "Limited":
            self = ATUStatus.limited
        default:
            self = ATUStatus.unknown
        }
    }
}
public enum EZLinkCardBalanceStatus: String {
    case OVERDUE
    case LIMITED
    case SUFFICENT
}
protocol EZATUStatusProtocol where Self: UIView {
    func updateATUStatus(status: ATUStatus, isCardAvaliable: Bool)
}

protocol EZLinkCardHeaderViewProtocol where Self: UIView {
    static func loadFromNib() -> Self

    func configUI(_ data: EZLinkCardHeaderData, temporaryCard: Bool, forcePreventAddCard: Bool)
}

public protocol EZLinkCardHeaderData {
    var formattedCan: String { get }
    var formattedBalance: String { get }
    var formattedExpireDate: String { get }
    var status: EZLinkCardStatus { get }
    var isExpired: Bool { get }
    var isCCCard: Bool { get }
    var type: EZLinkCardType { get }
    var balanceStatus: EZLinkCardBalanceStatus { get }
    var cardProfileType: EZLinkCardProfileType? { get }
}
