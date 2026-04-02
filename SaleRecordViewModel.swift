//  SaleRecordViewModel.swift
//  Profit Calculator App
import SwiftUI
import CoreData
import Combine

// ObservableObject を継承
class SaleRecordViewModel: ObservableObject {
    
    @Published var searchText: String = ""
    @Published var sortType: SortTypeMonthly = .saleDateDesc
    @Published var selectedDate: Date? = nil
    
    // Monthly側のソートタイプ
    enum SortTypeMonthly: String, CaseIterable, Identifiable {
        case saleDateDesc = "販売日：日付が新しい順"
        case saleDateAsc = "販売日：日付が古い順"
        case saleStartDateDesc = "出品日：日付が新しい順"
        case saleStartDateAsc = "出品日：日付が古い順"
        case netProfitDesc = "利益が高い順"
        case netProfitAsc = "利益が低い順"
        case totalExpensesDesc = "経費が高い順"
        case totalExpensesAsc = "経費が低い順"
        
        var id: String { self.rawValue }
    }

    // --- データの加工ロジック ---
    func filteredAndGrouped(from records: [SaleRecordEntities], isSoldMode: Bool) -> [(key: Date, values: [SaleRecordEntities])] {
        
        // 1. フィルタリング
        let filteredRecords = records.filter { record in
            // A. 出品中か売却済みか
            guard record.isSold == isSoldMode else { return false }
            
            // B. モードに応じて「基準にする日付」を決める
            let baseDate = isSoldMode ? record.saleDate : record.saleStartDate
            
            // C. 日付のチェック（カレンダー選択がある場合）
            let dateMatches: Bool
            if let selected = selectedDate, let rDate = baseDate {
                // 年と月を比較する
                let sComp = Calendar.current.dateComponents([.year, .month], from: selected)
                let rComp = Calendar.current.dateComponents([.year, .month], from: rDate)
                dateMatches = (sComp.year == rComp.year && sComp.month == rComp.month)
            } else {
                // selectedDateがnilなら、全ての日付を通す
                dateMatches = true
            }
            
            // D. 名前検索のチェック
            let name = record.itemName ?? ""
            let searchMatches = searchText.isEmpty || name.localizedCaseInsensitiveContains(searchText)
            
            return dateMatches && searchMatches
        }

        // 2. 月の中身の並び替え
        let sortedRecords = filteredRecords.sorted { a, b in
            let d1 = (isSoldMode ? a.saleDate : a.saleStartDate) ?? .distantPast
            let d2 = (isSoldMode ? b.saleDate : b.saleStartDate) ?? .distantPast
            return d1 > d2
        }

        // 3. 月ごとにグループ化（辞書作成）
        let dictionary = Dictionary(grouping: sortedRecords) { record in
            let baseDate = isSoldMode ? record.saleDate : record.saleStartDate
            let date = baseDate ?? .distantPast
            let components = Calendar.current.dateComponents([.year, .month], from: date)
            return Calendar.current.date(from: components) ?? .distantPast
        }

        // 4. 月ごとのソート
        let sortedElements = dictionary.sorted { (a, b) in
            switch sortType {
                // --- 日付順のソート ---
            case .saleDateDesc, .saleStartDateDesc:
                return a.key > b.key // 新しい月が上
            case .saleDateAsc, .saleStartDateAsc:
                return a.key < b.key // 古い月が上
                
                // --- 合計利益順のソート ---
            case .netProfitDesc:
                let sumA = a.value.reduce(0.0) { $0 + $1.netProfit }
                let sumB = b.value.reduce(0.0) { $0 + $1.netProfit }
                return sumA > sumB
            case .netProfitAsc:
                let sumA = a.value.reduce(0.0) { $0 + $1.netProfit }
                let sumB = b.value.reduce(0.0) { $0 + $1.netProfit }
                return sumA < sumB
                
                // --- 合計経費順のソート ---
            case .totalExpensesDesc:
                let sumA = a.value.reduce(0.0) { $0 + $1.totalExpenses }
                let sumB = b.value.reduce(0.0) { $0 + $1.totalExpenses }
                return sumA > sumB
            case .totalExpensesAsc:
                let sumA = a.value.reduce(0.0) { $0 + $1.totalExpenses }
                let sumB = b.value.reduce(0.0) { $0 + $1.totalExpenses }
                return sumA < sumB
            }
        }
        // 型を整えて返す（valuesに名前を合わせる）
        return sortedElements.map { (key: $0.key, values: $0.value) }
    }
    
    // 選択した月を取得
    func setTargetMonth(_ date: Date) {
        // 1. カレンダーを使って、その月の「1日 00:00」のデータを作る
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        if let firstOfMonth = Calendar.current.date(from: components) {
            // 2. それを検索条件（selectedDate）に入れる
            self.selectedDate = firstOfMonth
        }
    }
}
