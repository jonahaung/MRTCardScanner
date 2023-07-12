//
//  NFCScanner.swift
//  MrtCardScanner
//
//  Created by Aung Ko Min on 12/7/23.
//

import SwiftUI

public class NFCScanner: ObservableObject {
    
    @Published var cardDetail: NFCCardDetail?
    private let interactor = NFCCardScannerInteractor()
    
    public init() {
        interactor.setNfcCardDetectedBlock { [weak self] card in
            guard let self else { return }
            DispatchQueue.main.async {
                self.cardDetail = card
            }
        }
    }
    
    public func beginScan() {
        interactor.beginScan()
    }
}
