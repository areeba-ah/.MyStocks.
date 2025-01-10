//
//  Model.swift
//  Assignment4_Areeba
//
//  Created by Areeba Abid Mahmood on 2024-11-27.
//

import Foundation


struct StockData: Codable {
    let lastPrice: Double?
    let lastUpdateTime: String?
    let currencyCode: String?
    let currencySymbol: String?
}



struct ResultValues: Codable{
    var count: Int
    var results: [TStock]
}

struct TStock: Codable{
    var name: String
    var id: String
    var performanceId: String
    var exchange: String
    var securityType: String
}

enum StockStatus: Int, CaseIterable {
    case active = 0
    case watch = 1

    static func status(for index: Int) -> StockStatus? {
        return Self(rawValue: index)
    }
}


enum RankStatus: Int, CaseIterable {
    case cold = 0
    case hot = 1
    case veryHot = 2

    static func rankStatus(for index: Int) -> RankStatus? {
        return Self(rawValue: index)
    }
}
