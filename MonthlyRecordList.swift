//  MonthlyRecordList.swift
//  Profit Calculator App
//
//  概要：記録を月ごとに集計して表示するメイン一覧画面。
//  機能：「出品中」と「実績（売却済み）」をタブやフラグで切り替えて表示
//

import SwiftUI
import CoreData

struct MonthlyRecordList: View{
    @FetchRequest(entity: SaleRecordEntities.entity(), sortDescriptors: [])
    var records: FetchedResults<SaleRecordEntities>
    
    // 1.viewModelを取り出す
    @StateObject private var viewModel = SaleRecordViewModel()
    
    @State private var selectedRecordForEdit: SaleRecordEntities? = nil
    // デートピッカー
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var isResetting = false // 日付のリセット中の有無

    // カレンダー表示フラグ（ハーフモーダル）
    @State private var showCalendar: Bool = false

    // 表示する年の範囲（例：2020年〜2030年）
    let years = Array(2000...2100)
    let months = Array(1...12)
    
    // record追加ボタン用
    @State private var showingForm = false
    @State private var editingRecord: SaleRecordEntities? = nil
    @Environment(\.managedObjectContext) private var viewContext
    
    // タイトルの切り替え
    let isSoldMode: Bool
    private var navigationTitle: String {
        isSoldMode ? "売上実績" : "出品中（在庫）"
    }
    
    // ソート
    @ViewBuilder
    private var sortButtons: some View {
        Group {
            Button("販売日 ↓") { viewModel.sortType = .saleDateDesc }
            Button("販売日 ↑") { viewModel.sortType = .saleDateAsc }
            Divider()
            Button("純利益 ↓") { viewModel.sortType = .netProfitDesc }
            Button("純利益 ↑") { viewModel.sortType = .netProfitAsc}
            Divider()
            Button("経費 ↓") { viewModel.sortType = .totalExpensesDesc }
            Button("経費 ↑") { viewModel.sortType = .totalExpensesAsc}
        }
    }

    // 年月ホイール（シート用）
    private var monthYearPickerView: some View {
        HStack(spacing: 10) {
            // 年のホイール
            Picker("Year", selection: $selectedYear) {
                ForEach(years, id: \.self) { year in
                    Text("\(String(year))年").tag(year)
                }
            }
            .onChange(of: selectedYear, initial: false) {
                if !isResetting {
                    updateViewModelDate()
                }
            }
            #if os(iOS)
            .pickerStyle(.wheel) // iPhone/iPadならホイール
            #else
            .pickerStyle(.menu)  // Macならメニュー形式（ポチッと押すとリストが出る）
            #endif

            // 月のホイール
            Picker("Month", selection: $selectedMonth) {
                ForEach(months, id: \.self) { month in
                    Text("\(month)月").tag(month)
                }
            }
            .onChange(of: selectedMonth, initial: false) {
                if !isResetting {
                    updateViewModelDate()
                }
            }
            #if os(iOS)
            .pickerStyle(.wheel) // iPhone/iPadならホイール
            #else
            .pickerStyle(.menu)  // Macならメニュー形式（ポチッと押すとリストが出る）
            #endif

        }
        .padding(.horizontal)
    }
    
    private var groupedData: [(key: Date, values: [SaleRecordEntities])] {
        let soldRecords: [SaleRecordEntities] = records.filter { $0.isSold == isSoldMode }
        let grouped: [(key: Date, values: [SaleRecordEntities])] = viewModel.filteredAndGrouped(from: soldRecords, isSoldMode: isSoldMode)
        return grouped
    }
    
    // SaleRecordMonthly の中に追加
    private var allFilteredRecords: [SaleRecordEntities] {
        var flattened: [SaleRecordEntities] = []
        let groups: [(key: Date, values: [SaleRecordEntities])] = groupedData
        for group in groups {
            flattened.append(contentsOf: group.values)
        }
        return flattened
    }

    // Precompute groups once to reduce type-checking load
    private var precomputedGroups: [(key: Date, values: [SaleRecordEntities])] {
        groupedData
    }

    // Extracted cell content to simplify the List's generic nesting
    private struct GroupSectionView: View {
        let groupKey: Date
        let values: [SaleRecordEntities]
        let isSoldMode: Bool
        @Binding var selectedRecordForEdit: SaleRecordEntities?

        var headerText: String {
            groupKey.formatted(.dateTime.year().month(.twoDigits))
        }

        var previewRecords: [SaleRecordEntities] {
            Array(values.prefix(3))
        }

        var remainingCount: Int { max(values.count - 3, 0) }

        var body: some View {
            Section(header: Text(headerText)) {
                MonthlySummaryCard(records: values)
                NavigationLink {
                    SaleRecordView(targetMonth: groupKey, editingRecord: $selectedRecordForEdit, isSoldMode: isSoldMode, records: values)
                } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(previewRecords, id: \.objectID) { record in
                            RecordRowView(record: record)
                                .padding()
                            Rectangle()
                                .fill(Color.gray.opacity(0.2)) // 色も少し薄く
                                .frame(height: 0.5)            // 高さを0.5ポイントにする
                                .padding(.horizontal)          // 左右に少し余白を入れるとさらに上品です
                        }
                        if remainingCount > 0 {
                            HStack {
                                Spacer()
                                Text("ほか \(remainingCount) 件を表示...")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
        }
    }
    
    var body: some View{
        NavigationStack{
            VStack{
                List {
                    ForEach(precomputedGroups, id: \.key) { group in
                        GroupSectionView(
                            groupKey: group.key,
                            values: group.values,
                            isSoldMode: isSoldMode,
                            selectedRecordForEdit: $selectedRecordForEdit
                        )
                    }
                }
                .navigationTitle(isSoldMode ? (viewModel.selectedDate == nil ? "全期間の収支" : "\(String(selectedYear))年\(selectedMonth)月の収支") : "出品中")
                .safeAreaPadding(.vertical, 20)
                .focusable(false)
                // 境界線
                Divider()
                // 下部の累計表示エリア（固定）
                CareerSummarySection(records: allFilteredRecords, isSoldMode: isSoldMode)
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    HStack {
                        Button {
                            showCalendar = true
                        } label: {
                            Image(systemName: "calendar")
                        }
                        Menu { sortButtons } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                        AddRecordButton(
                            editingRecord: $editingRecord,
                            showingForm: $showingForm
                        )
                        Button {
                            viewModel.sortType = .saleDateDesc
                            resetFilter()
                        } label: {
                            Image(systemName: "arrow.circlepath")
                        }
                    }
                    .searchable(text: $viewModel.searchText, prompt: "商品名で検索")
                }
            }
            .sheet(isPresented: $showCalendar) {
                VStack {
                    Text("表示月を選択").font(.headline).padding()

                    monthYearPickerView
                    
                    HStack{
                        Button("決定") {
                            showCalendar = false
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                        Button("リセット"){
                            resetFilter()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                }
                // ハーフモーダルの高さを調整（iOS 16以降）
                .presentationDetents([.medium, .fraction(0.4)])
            }
            .sheet(isPresented: $showingForm) {
                // 記録入力のView
                RecordFormView(editingRecord: $editingRecord)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    // 日付でフィルター
    func updateViewModelDate() {
        let components = DateComponents(year: selectedYear, month: selectedMonth)
        if let newDate = Calendar.current.date(from: components) {
            viewModel.setTargetMonth(newDate)
        }
    }
    // 日付フィルターリセット
    func resetFilter() {
        isResetting = true
        
        // 2. ViewModel のフィルターを解除
        viewModel.selectedDate = nil
        print("現在の selectedDate: \(String(describing: viewModel.selectedDate))")
        // 1. 今日の日付から年と月を取得
        let now = Date()
        selectedYear = Calendar.current.component(.year, from: now)
        selectedMonth = Calendar.current.component(.month, from: now)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isResetting = false
        }
    }
}

