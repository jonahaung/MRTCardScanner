//
//  ContentView.swift
//  MrtCardScanner
//
//  Created by Aung Ko Min on 10/7/23.
//

import SwiftUI
import CoreData

struct ContentView: View {
    
    @StateObject private var scanner = NFCScanner()
    
    var body: some View {
        NavigationView {
            List {
                if let card = scanner.cardDetail {
                    Section("General Details") {
                        Text("Can ID").badge(card.formattedCan)
                        Text("Expiry Date").badge(card.formattedExpireDate)
                        Text("Card Profile").badge(card.cardProfile)
                        Text("Card Profile Type").badge(card.cardProfileType?.rawValue ?? "NA")
                        Text("Is Concession Card").badge(card.isCCCard ? "Yes" : "No")
                    }
                    
                    Section("Purse") {
                        Text("Purse Balance").badge(card.formattedBalance)
                        Text("Balance Status").badge(card.balanceStatus.rawValue)
                        Text("Purse Balance (Int)").badge(card.purseBalanceInt.description)
                        Text("Autoload Status").badge(card.autoloadStatus)
                        Text("Purse Status").badge(card.purseStatus)
                        Text("Autoload Amount").badge(card.autoloadAmount)
                        
                        if let x = card.cardProfileType {
                            Text("Profile Type").badge("\(x.hashValue)")
                        }
                    }
                    
                    if let lastTxt = card.lastTxn {
                        Section("Last Transaction") {
                            Text("Transaction Amount").badge(lastTxt.txnAmt)
                            Text("Transaction Type").badge(lastTxt.txnType)
                            Text("Transaction Date").badge(lastTxt.txnDatetime)
                        }
                    }
                    if let histories = card.txnHistory {
                        Section("Transaction History") {
                            
                            Text("historyRecordNum").badge(card.historyRecordNum.description)
                            
                            ForEach(histories, id: \.txnDatetime) { each in
                                Text("Transaction Amount").badge(each.txnAmt)
                                Text("Transaction Type").badge(each.txnType)
                                Text("Transaction Date").badge(each.txnDatetime)
                            }
                        }
                    }
                } else {
                    Text("Please tap the Start Scanning button to scan your card")
                }
            }
            .navigationTitle("MRT Card Scanner")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .none) {
                        scanner.beginScan()
                    } label: {
                        Text("Start Scanning")
                    }
                    .disabled(scanner.cardDetail != nil)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .destructive) {
                        scanner.cardDetail = nil
                    } label: {
                        Text("Reset")
                    }.disabled(scanner.cardDetail == nil)
                }
            }
        }
    }
}
