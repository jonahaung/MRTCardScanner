//
//  NFCCommandInteractor.swift
//  EZ-PZ-iOS
//
//  Created by Yu Wang on 2020/8/12.
//  Copyright © 2020 ezlink. All rights reserved.
//

import Foundation
import CoreNFC



enum NFCTapError: Error {
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

@available(iOS 13.0, *)
protocol NFCCommandInteractor {}

@available(iOS 13.0, *)
extension Reactive where Base: NFCCommandInteractor {
    typealias CommandResp = Result<(resp: Data, sw1: String, sw2: String), Error>
    func sendCommand(_ tag: NFCISO7816Tag, apdu: String) -> Observable<CommandResp> {
        return Single<CommandResp>.create { (event) -> Disposable in
            tag.sendCommand(apdu: apdu) { (result) in
                event(.success(result))
            }
            return Disposables.create()
        }
        .asObservable()
    }
    
    func sendCommand(_ tag: NFCISO7816Tag, cls: UInt8, code: UInt8, p1: UInt8, p2: UInt8, dataHexStr: String?, responseLength: Int) -> Observable<CommandResp> {
        return Single<CommandResp>.create { (event) -> Disposable in
            tag.sendCommand(cls: cls, code: code, p1: p1, p2: p2, dataHexStr: dataHexStr, responseLength: responseLength) { (result) in
                event(.success(result))
            }
            return Disposables.create()
        }
        .asObservable()
    }
    
    func getChallenge(_ tag: NFCISO7816Tag) -> Observable<String> {
        return sendCommand(tag, cls: 0x00, code: 0x84, p1: 0x00, p2: 0x00, dataHexStr: nil, responseLength: 08)
            .flatMap { (result) -> Observable<String> in
                guard case .success(let data) = result, data.resp.count > 0 else {
                    return .error(NFCTapError.getChallengeFaild)
                }
                return .just(data.resp.toHex().joined())
        }
    }
    
//    func fetchSecPurseCommand(canId: String, challenge: String) -> Observable<String> {
//        let request = ReadPurseSecureCmdRequest(can: canId, challenge: challenge)
//        return client.sendAuthorised(request)
//            .flatMap { resp -> Observable<String> in
//                guard let purseCmd = resp.data?.apdu else {
//                    return .error(NFCTapError.fetchPurseFailed)
//                }
//                return .just(purseCmd)
//            }
//    }
    
    func getSecPurse(_ tag: NFCISO7816Tag, apdu: String) -> Observable<String> {
        return sendCommand(tag, apdu: apdu).flatMap { (result) -> Observable<String> in
            guard case .success(let data) = result, data.resp.count > 0 else {
                return .error(NFCTapError.getPurseFailed)
            }
            return .just(data.resp.toHex().joined())
        }
    }
    
    func getCardDetail(_ tag: NFCISO7816Tag) -> Observable<NFCCardDetail> {
        return sendCommand(tag, apdu: "9032030000").flatMap { result -> Observable<NFCCardDetail> in
            guard case .success(let data) = result, data.resp.count > 0 else {
                return .error(NFCTapError.getChallengeFaild)
            }
            return .just(NFCCardDetail(hexData: data.resp, txnLogHexData: []))
        }
    }
    
    func getCardDetailWithTxnRecord(_ tag: NFCISO7816Tag) -> Observable<NFCCardDetail> {
        return sendCommand(tag, apdu: "9032030000").flatMap { result -> Observable<NFCCardDetail> in // CEPAS CARD Detail
            return Single<NFCCardDetail>.create { event in
                guard case .success(let data) = result, data.resp.count > 0  else {
//                    event(.error(NFCTapError.getPurseFailed))
                    return Disposables.create()
                }
                var txnLogData: [Data] = []
                let group = DispatchGroup()
                let historyRecordCount = [UInt8](data.resp)[40]
                for i in 0..<historyRecordCount {
                    group.enter()
                    tag.getTxn(index: UInt(i)) { (result) in
                        guard case .success(let data) = result else {
                            group.leave()
                            return
                        }
                        txnLogData.append(data.resp)
                        group.leave()
                    }
                }
                group.notify(queue: .main) {
                    let detail = NFCCardDetail(hexData: data.resp, txnLogHexData: txnLogData)
                    event(.success(detail))
                }
                return Disposables.create()
            }.asObservable()
        }
    }
    
    func getSecureData(_ tag: NFCISO7816Tag) -> Observable<NFCCardSecure> {
        func generateTerminalRandom() -> String {
            return Array(0..<16).map { _ in
                return String(arc4random() % 16, radix: 16)
            }.joined()
        }
        
        func generateReadSecurePurseDataCommand(terminalRandom: String) -> String {
            let command = "903203000A1403" + terminalRandom + "71"
            return command
        }
        
        func removeStatusCode(_ hexStr: String) -> String {
            if hexStr.hasSuffix("9000") {
                return hexStr.substring(0, hexStr.count - 4)
            }
            return hexStr
        }
        
        func checkResponseStatus(_ purseData: Data) -> Bool {
            let hexStr = purseData.toHex().joined()
            return hexStr.hasSuffix("9000")
        }
        
        // CEPAS CARD Detail
        let cardRandom = getChallenge(tag).map { removeStatusCode($0) }
        let terminalRandom = generateTerminalRandom()
        let readSecPurseCommand = generateReadSecurePurseDataCommand(terminalRandom: terminalRandom)
        let secPurseData = sendCommand(tag, apdu: readSecPurseCommand)
            .flatMap { result -> Observable<String> in
                guard case .success(let data) = result else {
                    return .error(NFCTapError.getSecPurseFailed)
                }
                let purseDataStr = removeStatusCode(data.resp.toHex().joined())
                guard purseDataStr.count >= 226 else {
                    return .error(NFCTapError.getSecPurseFailed)
                }
                return .just(purseDataStr)
            }
        return Observable.combineLatest(cardRandom, secPurseData) {
            NFCCardSecure(cardRandom: $0, terminalRandom: terminalRandom, purseData: $1)
        }
    }
}
