//
//  NFCCardSecure.swift
//  EZ-PZ-iOS
//
//  Created by Yu Wang on 2020/7/17.
//  Copyright © 2020 ezlink. All rights reserved.
//

import Foundation

struct NFCCardSecure: Codable {
    let cardRandom: String
    let terminalRandom: String
    let purseData: String
    private enum CodingKeys: String, CodingKey {
        case cardRandom = "card_random"
        case terminalRandom = "terminal_random"
        case purseData = "purse_data"
    }
}
