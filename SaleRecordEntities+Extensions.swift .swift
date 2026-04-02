//  SaleRecordEntites+Extensions.swift
//  Profit Calculator App
import Foundation
import CoreData

extension SaleRecordEntities {
    // 純利益の計算
    var netProfit: Double {
        let commissionCost = salesPrice * (commission / 100)
        return salesPrice - (purchasePrice + postage + envelopeCost + othersCost + commissionCost)
    }

    // 経費の計算
    var totalExpenses: Double {
        let commissionCost = salesPrice * (commission / 100)
        return purchasePrice + postage + envelopeCost + othersCost + commissionCost
    }
}
