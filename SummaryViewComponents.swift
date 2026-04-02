//  SummaryViewComponents.swift
//  Profit Calculator App
import SwiftUI

// --- 1. 二つのファイルを横に並べた「累計エリア」の共通部品 ---
struct CareerSummarySection: View {
    let totalNetProfit: Double
    let totalExpenses: Double
    
    // 出品中かどうか
    let isSoldMode: Bool

    // 収支計算セクションの初期化
    init<S: Sequence>(records: S, isSoldMode: Bool, targetMonth: Date? = nil) where S.Element == SaleRecordEntities {
        self.isSoldMode = isSoldMode
        
        let allItems = Array(records)
        let finalItems: [SaleRecordEntities]
        
        if let month = targetMonth {
            // 1. 月が指定されている場合：ViewModelのロジックで絞り込む
            let tempViewModel = SaleRecordViewModel()
            tempViewModel.setTargetMonth(month)
            let grouped = tempViewModel.filteredAndGrouped(from: allItems, isSoldMode: isSoldMode)
            finalItems = grouped.flatMap { $0.values }
        } else {
            // 2. 月が nil の場合：渡されたレコードをそのまま使う（全期間）
            finalItems = allItems
        }
        
        // 最後に合計を計算
        self.totalNetProfit = finalItems.reduce(0) { $0 + $1.netProfit }
        self.totalExpenses = finalItems.reduce(0) { $0 + $1.totalExpenses }
    }

    // --- B. 1つだけ（単体）が渡されたときの初期化 ---
    init(_ record: SaleRecordEntities) {
        self.isSoldMode = false
        self.totalNetProfit = record.netProfit
        self.totalExpenses = record.totalExpenses
    }

    // --- C. 直接数字を渡したいとき用の初期化 ---
    init(netProfit: Double, expenses: Double) {
        self.isSoldMode = false
        self.totalNetProfit = netProfit
        self.totalExpenses = expenses
    }

    // --- 表示部分 ---
    var body: some View {
        HStack(spacing: 16) {
            SummaryMiniCard(
                title: "純利益",
                value: totalNetProfit,
                color: totalNetProfit >= 0 ? .green : .red
            )
            
            SummaryMiniCard(
                title: "経費",
                value: totalExpenses,
                color: totalExpenses >= 0 ? .red : .green
            )
        }
        .padding()
        .background(Color.platformBackground)
    }
}

// --- 2. 個別の小さなカード部品 ---
struct SummaryMiniCard: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(Int(value)) 円")
                .font(.headline)
                .bold()
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.platformSecondaryBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
    }
}
