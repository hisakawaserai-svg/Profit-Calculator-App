//  DataView.swift
//  Profit Calculator App
//
//  概要：売却済みデータの統計・分析画面。
//  機能：
//   - SwiftUI Charts を用いた売上金額および純利益の可視化
//   - 表示単位（日別・月別・年別）に応じたデータの動的な集計処理
//   - グラフ上のタップ/ドラッグ操作による詳細データ（内訳）の表示
//
import SwiftUI
import CoreData
import Charts

struct DataView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: SaleRecordEntities.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \SaleRecordEntities.saleDate, ascending: true)]
    ) var records: FetchedResults<SaleRecordEntities>
    
    @State private var endDate: Date = Date()
    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var isAllPeriod: Bool = false
    @State private var chartType: ChartType = .day
    @State var metricType: MetricType = .sales

    enum ChartType: String, CaseIterable, Identifiable {
        case record = "明細", day = "日別", month = "月別", year = "年別"
        var id: String { rawValue }
    }
    
    enum MetricType: String, CaseIterable, Identifiable {
        case sales = "売上金額", netProfit = "純利益"
        var id: String { rawValue }
    }

    private var filteredRecords: [SaleRecordEntities] {
        records.filter { record in
            guard record.isSold, let date = record.saleDate else { return false }
            return isAllPeriod ? true : (date >= startDate && date <= endDate)
        }
    }
    
    private var totalSales: Double { filteredRecords.reduce(0) { $0 + $1.salesPrice } }
    private var totalExpenses: Double { filteredRecords.reduce(0) { $0 + $1.totalExpenses } }
    private var totalNetProfit: Double { totalSales - totalExpenses }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    periodSettingsSection
                    summaryCardsSection
                    
                    ChartSectionView(
                        chartType: chartType,
                        metricType: $metricType,
                        chartTypeBinding: $chartType,
                        startDate: $startDate,
                        endDate: $endDate,
                        allFilteredRecords: filteredRecords
                    )
                }
                .padding()
                .onChange(of: chartType) { oldValue, newValue in
                    updateDefaultRange(for: newValue)
                }
            }
            .background(Color.platformBackground)
            .navigationTitle("分析データ")
        }
    }

    private func updateDefaultRange(for type: ChartType) {
        let cal = Calendar.current
        let now = Date()
        
        // 単位に合わせて「表示幅」をセットする
        switch type {
        case .record, .day:
            startDate = cal.date(byAdding: .day, value: -7, to: now) ?? startDate
        case .month:
            startDate = cal.date(byAdding: .month, value: -6, to: now) ?? startDate
        case .year:
            startDate = cal.date(byAdding: .year, value: -4, to: now) ?? startDate
        }
        withAnimation{
            endDate = now
        }
    }

    private var periodSettingsSection: some View {
        VStack(spacing: 12) {
            Toggle("全期間を表示", isOn: $isAllPeriod)
                .font(.subheadline)
            
            if !isAllPeriod {
                Divider()
                HStack {
                    DatePicker("開始", selection: $startDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                    Text("〜")
                    DatePicker("終了", selection: $endDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                }
                .labelsHidden()
                .padding(.horizontal, 8)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }

    private var summaryCardsSection: some View {
        HStack(spacing: 12) {
            summaryMiniBox(title: "純利益", value: totalNetProfit, color: .green)
            summaryMiniBox(title: "経費", value: totalExpenses, color: .red)
            summaryMiniBox(title: "売上", value: totalSales, color: .blue)
        }
    }
    
    private func summaryMiniBox(title: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text("\(Int(value))円").font(.headline).foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.15), lineWidth: 1))
    }
}

// MARK: - チャートセクション
struct ChartSectionView: View {
    let chartType: DataView.ChartType
    @Binding var metricType: DataView.MetricType
    @Binding var chartTypeBinding: DataView.ChartType
    @Binding var startDate: Date
    @Binding var endDate: Date
    let allFilteredRecords: [SaleRecordEntities]

    @State private var selectedDate: Date?

    struct AggregatedPoint: Identifiable {
        let id = UUID()
        let date: Date
        var sales: Double
        var profit: Double
        var details: [SaleRecordEntities]
    }

    private var chartData: [AggregatedPoint] {
        let calendar = Calendar.current
        var dict: [Date: AggregatedPoint] = [:]
        for record in allFilteredRecords {
            guard let date = record.saleDate else { continue }
            let truncatedDate: Date
            switch chartType {
            case .record: truncatedDate = date
            case .day: truncatedDate = calendar.startOfDay(for: date)
            case .month: truncatedDate = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? endDate
            case .year: truncatedDate = calendar.date(from: calendar.dateComponents([.year], from: date)) ?? endDate
            }
            if var point = dict[truncatedDate] {
                point.sales += record.salesPrice
                point.profit += record.netProfit
                point.details.append(record)
                dict[truncatedDate] = point
            } else {
                dict[truncatedDate] = AggregatedPoint(date: truncatedDate, sales: record.salesPrice, profit: record.netProfit, details: [record])
            }
        }
        return dict.values.sorted { $0.date < $1.date }
    }
    
    private var yAxisUpperBound: Double {
        let maxVal = chartData.map { metricType == .sales ? $0.sales : $0.profit }.max() ?? 0
        return max(1000, maxVal) * 1.15
    }

    // クラッシュ防止：X軸の土台を「表示幅」より常に広く保つ
    private var safeDomain: ClosedRange<Date> {
        let minInterval = chartVisibleLength
        let currentInterval = endDate.timeIntervalSince(startDate)
        
        var finalStart = startDate
        if currentInterval < minInterval {
            // 表示したい幅よりカレンダーの範囲が狭い場合、開始日を過去に広げて矛盾をなくす
            finalStart = endDate.addingTimeInterval(-minInterval)
        }
        return finalStart...endDate
    }

    // 1画面に表示する幅
    private var chartVisibleLength: Double {
        let day: Double = 3600 * 24
        switch chartType {
        case .record, .day: return day * 7
        case .month: return day * 30 * 6
        case .year: return day * 365 * 4
        }
    }
    
    private var nearestPoint: AggregatedPoint? {
        guard let selectedDate else { return nil }
        return chartData.min { lhs, rhs in
            abs(lhs.date.timeIntervalSince(selectedDate)) < abs(rhs.date.timeIntervalSince(selectedDate))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerControlSection
            
            if chartData.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "chart.bar.xaxis").font(.largeTitle).foregroundColor(.secondary)
                    Text("売却済みのデータがありません").foregroundColor(.secondary)
                    Spacer()
                }.frame(maxWidth: .infinity)
            } else {
                mainChartView
            }
            
            detailListSection
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.platformSecondaryBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }

    private var headerControlSection: some View {
        HStack {
            moveButton(systemName: "chevron.left", step: -1)
            Spacer()
            Picker("単位", selection: $chartTypeBinding) {
                ForEach(DataView.ChartType.allCases) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented).frame(maxWidth: 160)
            
            Picker("指標", selection: $metricType) {
                ForEach(DataView.MetricType.allCases) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented).frame(maxWidth: 100)
            Spacer()
            moveButton(systemName: "chevron.right", step: 1)
        }
    }

    private var mainChartView: some View {
        Chart {
            ForEach(chartData) { point in
                let plotValue = (metricType == .sales) ? point.sales : point.profit
                if chartType == .record {
                    LineMark(x: .value("日", point.date), y: .value("額", plotValue))
                        .symbol(.circle).interpolationMethod(.catmullRom)
                        .foregroundStyle(metricType == .sales ? Color.blue : Color.green)
                } else {
                    BarMark(x: .value("日", point.date), y: .value("額", plotValue), width: .fixed(12))
                        .foregroundStyle(metricType == .sales ? Color.blue.gradient : Color.green.gradient)
                        .cornerRadius(4)
                }
                
                if let selectedDate, Calendar.current.isDate(point.date, inSameDayAs: selectedDate) {
                    RuleMark(x: .value("選", point.date))
                        .foregroundStyle(Color.gray.opacity(0.2))
                        .annotation(position: .top) { tooltipView(for: point) }
                }
            }
        }
        .frame(height: 250)
        .chartYScale(domain: 0...yAxisUpperBound)
        .chartXScale(domain: safeDomain) // 安全な範囲を使用
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: chartVisibleLength)
        .chartScrollPosition(initialX: endDate) // 常に終了日を基準に表示
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine(); AxisTick()
                if let date = value.as(Date.self) {
                    switch chartType {
                    case .day, .record:
                        AxisValueLabel(date.formatted(.dateTime.month(.twoDigits).day(.twoDigits)),anchor: .topTrailing)
                    case .month:
                        AxisValueLabel(date.formatted(.dateTime.year().month(.twoDigits)),anchor: .topTrailing)
                    case .year:
                        AxisValueLabel(date.formatted(.dateTime.year()) ,anchor: .topTrailing)

                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if let plotFrame = proxy.plotFrame {
                                    let origin = geometry[plotFrame].origin
                                    let location = value.location.x - origin.x
                                    if let date: Date = proxy.value(atX: location) {
                                        selectedDate = date
                                    }
                                }
                            }
                    )
            }
        }
        .onTapGesture { selectedDate = nil }
    }
    
    private var detailListSection: some View {
        Group {
            if let selectedPoint = nearestPoint {
                DetailList(selectedPoint: selectedPoint, metricType: self.metricType, onClear: { self.selectedDate = nil })
            }
        }
    }
    
    private struct DetailList: View {
        let selectedPoint: AggregatedPoint
        let metricType: DataView.MetricType
        let onClear: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                header
                records
            }
        }
        
        private var sortedDetails: [SaleRecordEntities] {
            let details = selectedPoint.details
            return details.sorted { a, b in
                if metricType == .sales {
                    return a.salesPrice > b.salesPrice
                } else {
                    return a.netProfit > b.netProfit
                }
            }
        }

        private var header: some View {
            HStack {
                let dateText = selectedPoint.date.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits))
                Text("\(dateText) の内訳")
                    .font(.headline)
                Spacer()
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(.top)
        }

        private var records: some View {
            ForEach(sortedDetails, id: \.objectID) { record in
                RecordDisclosure(record: record, metricType: metricType)
            }
        }
    }

    private struct RecordDisclosure: View {
        let record: SaleRecordEntities
        let metricType: DataView.MetricType
        
        var isSaleMode: Bool { metricType == .sales }

        var body: some View {
            DisclosureGroup {
                VStack(spacing: 16) {
                    ProductInfoSection(record: record)
                    ExpenseDetailSection(record: record)
                }
                .padding(.top)
            } label: {
                HStack {
                    Image(systemName: "tag.circle.fill")
                        .foregroundColor(isSaleMode ? .blue.opacity(0.8) : .green.opacity(0.8))
                        .font(.title2)
                    
                    Text(record.itemName ?? "明細")
                        .foregroundColor(isSaleMode ? .blue.opacity(0.8) : .green.opacity(0.8))
                        .font(.body.bold())
                    
                    Spacer()
                    Text(isSaleMode ? "売上額：" : "純利益：")
                        .foregroundColor(isSaleMode ? .blue.opacity(0.8) : .green.opacity(0.8))
                    
                    Text("¥\(Int(isSaleMode ? record.salesPrice : record.netProfit))")
                        .font(.body.monospacedDigit())
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.platformSecondaryBackground)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.1), lineWidth: 1))
            .shadow(color: .black.opacity(0.03), radius: 5)
        }
    }

    private func moveButton(systemName: String, step: Int) -> some View {
        Button(action: {
            let unit: Calendar.Component = {
                switch chartType {
                case .record, .day: return .day
                case .month: return .month
                case .year: return .year
                }
            }()
            withAnimation {
                startDate = Calendar.current.date(byAdding: unit, value: step, to: startDate) ?? startDate
                endDate = Calendar.current.date(byAdding: unit, value: step, to: endDate) ?? endDate
            }
        }) {
            Image(systemName: systemName).padding(8).background(Circle().fill(Color.gray.opacity(0.1)))
        }.buttonStyle(.plain)
    }

    private func tooltipView(for point: AggregatedPoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(point.date, style: .date).font(.caption2).foregroundColor(.secondary)
            Text("売上: \(Int(point.sales))円").font(.caption.bold()).foregroundColor(.blue)
            Text("利益: \(Int(point.profit))円").font(.caption.bold()).foregroundColor(.green)
        }.padding(8).background(Color.platformSecondaryBackground).cornerRadius(8).shadow(radius: 4)
    }
}
