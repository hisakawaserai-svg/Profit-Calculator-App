//  MonthlySummaryCurd.swift
//  Profit Calculator App
import SwiftUI

struct MonthlySummaryCard: View {
    let records: [SaleRecordEntities]
    
    // 累計純利益
    private var totalNetProfit: Int {
        records.reduce(0) { $0 + Int($1.netProfit) }
    }
    
    // 累計経費
    private var totalExpense: Int {
        records.reduce(0) { $0 + Int($1.totalExpenses) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("純利益")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("¥\(totalNetProfit)")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("経費")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("¥\(totalExpense)")
                        .font(.headline)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        #if os(iOS)
        .background(Color(.systemGray6)) // iPhone/iPadなら
        #else
        .background(Color.platformSecondaryBackground)       // Macなら
        #endif
        .cornerRadius(10)
    }
}
