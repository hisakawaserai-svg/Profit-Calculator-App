//  SaleRecord.swift
//  Profit Calculator App
import SwiftUI
import CoreData

struct SaleRecordView: View {
    // 1. 親から渡される表示対象の月
    let targetMonth: Date
    
    // 2. 親（MonthlyView）と同じ ViewModel インスタンスを共有する、
    @StateObject private var viewModel = SaleRecordViewModel()

//--------------------------------------------------------------
    @Environment(\.dismiss) private var dismiss // 前に戻る
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var editingRecord: SaleRecordEntities?
    
    @State private var sortType: SortType = .saleDateDesc
    @State private var showingForm = false
    @State private var searchText: String = ""
    @State private var selectedDate: Date? = nil
    @State private var showCalendar = false
    // リストを強制更新するためのフラグ
    @State private var refreshID = UUID()
    
    enum SortType {
        case saleDateDesc, saleDateAsc, saleStartDateDesc, saleStartDateAsc , itemName, netProfitDesc
    }
    
    // 💡 画面表示用の最終的なリスト
    private func sortedRecords(for items: [SaleRecordEntities]) -> [SaleRecordEntities] {
        // まず検索ワードでフィルター
        let filtered = items.filter { record in
            let name = record.itemName ?? ""
            return searchText.isEmpty || name.localizedCaseInsensitiveContains(searchText)
        }
        
        // 次に、この画面専用のルールでソート
        return filtered.sorted { a, b in
            switch sortType {
            case .saleDateDesc:
                return (a.saleDate ?? .distantPast) > (b.saleDate ?? .distantPast)
            case .saleDateAsc:
                return (a.saleDate ?? .distantPast) < (b.saleDate ?? .distantPast)
            case .saleStartDateDesc:
                return (a.saleStartDate ?? .distantPast) > (b.saleStartDate ?? .distantPast)
            case .saleStartDateAsc:
                return (a.saleStartDate ?? .distantPast) < (b.saleStartDate ?? .distantPast)
            case .itemName:
                // aの名前とbの名前を、OSの標準的なルールで比べる
                let nameA = a.itemName ?? ""
                let nameB = b.itemName ?? ""
                return nameA.localizedStandardCompare(nameB) == .orderedAscending
            case .netProfitDesc:
                return a.netProfit > b.netProfit
            }
        }
    }
    // 強制再描画用のトリガー
    @State private var lastUpdate = Date()
    
    // 出品中かどうか
    let isSoldMode: Bool
    // MonthlyRecordListからの引数
    let records: [SaleRecordEntities]

    // --- 2. 累計金額の計算（表示されているレコードのみを対象） ---
    private var totalNetProfit: Double {
        var sum: Double = 0
        for record in records {
            sum += record.netProfit
        }
        return sum
    }
    
    private var totalExpenses: Double {
        var sum: Double = 0
        for record in records {
            sum += record.totalExpenses
        }
        return sum
    }

    var body: some View {
        NavigationStack {
            // VStackで「リスト」と「累計エリア」を上下に分ける
            VStack(spacing: 0) {
                // リスト表示
                recordsList
                    .listStyle(.inset)
                    .id(refreshID)
                
                // 境界線
                Divider()
                Spacer()
                // 下部の累計表示エリア（固定）
                CareerSummarySection(records: records, isSoldMode: isSoldMode, targetMonth: targetMonth)
            }
            // displayedRecords.count ではなく、大元の records を見張る
            .onChange(of: currentMonthCount){ oldCount, newCount in
                print("CoreDataの総件数が変わりました: \(newCount)")
                // フィルター後の件数が0になったかチェック
                if currentMonthCount == 0 {
                    print("表示対象がなくなったので画面を閉じます")
                    dismiss()
                }
            }
            .focusable(false)
            .background(Color.platformBackground)
            .navigationTitle("販売記録")
            .searchable(text: $searchText, prompt: "商品名で検索")
            // カレンダーを最前面に浮かせる
            .overlay(alignment: .top) {
                if showCalendar {
                    calendarOverlay
                        .zIndex(1)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button { showCalendar.toggle() } label: {
                        Image(systemName: "calendar")
                    }
                    Menu { sortButtons } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    AddRecordButton(
                        editingRecord: $editingRecord,
                        showingForm: $showingForm
                    )
                }
            }
            .sheet(isPresented: $showingForm, onDismiss: {
                // フォームを閉じた時にIDを更新して、リスト全体を再描画させる
                refreshID = UUID()
            }) {
                RecordFormView(editingRecord: $editingRecord)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .onAppear{viewModel.setTargetMonth(targetMonth)}
    }

    private var recordsList: some View {
        List {
            // ViewModelに「records（全データ）」を渡して「加工済みデータ」をもらう
            let groupedData = viewModel.filteredAndGrouped(from: records, isSoldMode: isSoldMode)
            
            // 加工済みのデータ（groupedData）を使ってループを回す
            ForEach(groupedData, id: \.key) { group in
                // ヘッダーの作成（ViewModelにこの文字列作成を任せてもいいですね！）
                Section(header: Text(group.key.formatted(.dateTime.year().month(.twoDigits)))) {
                    let sortedItems = sortedRecords(for: group.values)  // ソート後の配列を保存
                    
                    ForEach(sortedItems, id: \.objectID) { record in
                        NavigationLink(destination: SaleRecordDetailView(record: record, targetMonth: targetMonth)) {
                            RecordRowView(record: record)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let recordToDelete = sortedItems[index]
                            viewContext.delete(recordToDelete)
                        }
                        do {
                            try viewContext.save()
                            print("削除に成功しました")
                        } catch {
                            print("削除に失敗しました: \(error)")
                        }
                    }
                    .padding()
                    .background(Color.platformBackground)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
            }
        }
        .safeAreaPadding(.vertical, 10)
    }

    // --- 削除ロジック ---
    private func deleteRecords(at offsets: IndexSet, in items: [SaleRecordEntities]) {
        for index in offsets {
            let recordToDelete = items[index]
            viewContext.delete(recordToDelete)
        }
        try? viewContext.save()
        // viewContext.refreshAllObjects() // 必要なら追加
    }

    // ソートボタン
    private var sortButtons: some View {
        Group {
            if isSoldMode {
                Button("販売日 ↓") { sortType = .saleDateDesc }
                Button("販売日 ↑") { sortType = .saleDateAsc }
            } else {
                Button("出品日 ↓") { sortType = .saleStartDateDesc }
                Button("出品日 ↑") { sortType = .saleStartDateAsc }
            }
            Divider()
            Button("商品名") { sortType = .itemName }
            Button("純利益 ↓") { sortType = .netProfitDesc }
        }
    }

    private var calendarOverlay: some View {
        VStack(spacing: 0) {
            HStack {
                Button("リセット") { selectedDate = nil; showCalendar = false }
                Spacer()
                Button("閉じる") { showCalendar = false }
            }
            .padding()
            .background(Color.platformSecondaryBackground)

            DatePicker(
                "日付選択",
                selection: Binding(get: { selectedDate ?? Date() }, set: { selectedDate = $0 }),
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .padding()
        }
        .background(Color.platformBackground)
        .cornerRadius(12)
        .shadow(radius: 10)
        .padding()
        #if os(macOS)
        .frame(width: 400) // Macで広がりすぎないように
        #endif
    }
    
    // 日付（Date）をキーにして、その月のレコード配列（[SaleRecordEntities]）を持つ辞書
    private var groupedRecords: [(key: Date, values: [SaleRecordEntities])] {
        // 1. カレンダーを使って時間を無視してグループ化
        let dictionary = Dictionary(grouping: records) { (record) -> Date in
            let date = record.saleDate ?? Date.distantPast
            let components = Calendar.current.dateComponents([.year, .month], from: date)
            return Calendar.current.date(from: components) ?? Date.distantPast
        }
        
        // 2. 辞書を日付順（降順）に並び替えて配列にする
        return dictionary
            .sorted { $0.key > $1.key }
            .map { (key: $0.key, values: $0.value) }
    }

    // 現在開いているListのrecordの数を数える、ゼロの場合SaleRecordMonthly画面に戻る
    private var currentMonthCount: Int {
        let formatted = records.filter{record in
            guard let date = record.saleDate else { return false }
            return Calendar.current.isDate(date, equalTo: targetMonth, toGranularity: .month)
        }
        return formatted.count
    }
    
}

// --- 行（Row）専用のビュー ---
struct RecordRowView: View {
    @ObservedObject var record: SaleRecordEntities
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(record.itemName ?? "無題")
                .font(.headline)
                .lineLimit(1)
            
            HStack(alignment: .center, spacing: 15) {
                Text("純利益: \(Int(record.netProfit))円")
                    .foregroundColor(record.netProfit >= 0 ? .green : .red)
                    .lineLimit(1)
                Text("経費: \(Int(record.totalExpenses))円")
                    .foregroundColor(record.totalExpenses >= 0 ? .red : .black)
                    .lineLimit(1)
            }
            .font(.subheadline)
            
            if let saleDate = record.saleDate {
                Text(saleDate.formatted(.dateTime.year().month(.twoDigits).day()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 5)
        .lineLimit(1)
        .truncationMode(.tail)
    }
}

