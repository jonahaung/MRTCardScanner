//
//  Extensions.swift
//  MrtCardScanner
//
//  Created by Aung Ko Min on 12/7/23.
//

import Foundation

public protocol OccupiableProtocol {
    var isEmpty: Bool { get }
    var isNotEmpty: Bool { get }
}

public extension OccupiableProtocol {
    var isNotEmpty: Bool {
        return !isEmpty
    }
}

extension String: OccupiableProtocol { }
extension Array: OccupiableProtocol { }
extension Dictionary: OccupiableProtocol { }
extension Set: OccupiableProtocol { }


public extension String {
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
        guard isNotEmpty, count >= startingIndex else { return nil }
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
