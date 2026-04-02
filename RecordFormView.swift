//  RecordFormView.swift
//  Profit Calculator App
import SwiftUI
import CoreData
import Combine

struct RecordFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var editingRecord: SaleRecordEntities?
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: CalcView.FocusField?
    
    // 入力用の一時変数
    @State private var itemName: String = ""
    @State private var salesPrice: String = ""
    @State private var purchasePrice: String = ""
    @State private var postage: String = ""
    @State private var envelopeCost: String = ""
    @State private var othersCost: String = ""
    @State private var commission: Double = 10.0
    @State private var saleStartDate: Date = Date()
    @State private var saleDate: Date = Date()
    @State private var isSold: Bool = false
    @State private var memo: String = ""
    
    // 入力フォームが新規か
    var isNew: Bool {
        return editingRecord?.itemName?.isEmpty ?? true
    }
    
    // 保存ボタンを押したか
    @State var isPushedSave: Bool = false
    
    var body: some View {
        NavigationStack {
            Text(isNew ? "新規追加" : "編集")
                .font(.headline)
                .bold()
            // 両端が薄く消える区切り線
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.5), .clear]),
                        startPoint: .leading,  // 左端から
                        endPoint: .trailing    // 右端へ
                    )
                )
                .frame(height: 0.5) // 極細の線
            Form {
                Section("商品情報") {
                    LabeledField(label: "商品名", placeholder: "例：えんぴつ", text: $itemName, isMultiline: 1, focusTag: .salesPrice, focusedField: $focusedField, isPushedSave: $isPushedSave)
                    
                    LabeledField(label: "販売価格", placeholder: "0", text: $salesPrice, isNumeric: true, focusTag: .salesPrice, focusedField: $focusedField)
                    
                    LabeledField(label: "仕入価格", placeholder: "0", text: $purchasePrice, isNumeric: true, focusedField: $focusedField)
                    
                    LabeledField(label: "送料", placeholder: "0", text: $postage, isNumeric: true, focusedField: $focusedField)
                    LabeledField(label: "梱包材", placeholder: "0", text: $envelopeCost, isNumeric: true, focusedField: $focusedField)
                    LabeledField(label: "その他", placeholder: "0", text: $othersCost, isNumeric: true, focusedField: $focusedField)
                    
                    // 手数料調整
                    HStack {
                        Text("手数料 (\(Int(commission))%)")
                            .font(.subheadline)
                        Spacer()
                        Stepper("", value: $commission, in: 0...50)
                            .labelsHidden()
                    }
                }
                
                Section("日付設定") {
                    DatePicker("出品日", selection: $saleStartDate, displayedComponents: .date)
                    if isSold {DatePicker("販売日", selection: $saleDate, displayedComponents: .date)}
                    Toggle(isSold ? "販売済み" : "出品中", isOn: $isSold)
                }
                
                LabeledField(label: "メモ", placeholder: "", text: $memo, isMultiline: 2, focusedField: $focusedField)
            }
            #if os(macOS)
            .padding()
            .frame(minWidth: 400, minHeight: 500) // Macで小さくなりすぎないように固定
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        cancelAndDismiss()
                        isPushedSave = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveAndDismiss()
                        isPushedSave = true
                    }
                }
            }
            .onAppear {
                loadInitialData()
            }
#if os(iOS)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("閉じる") { focusedField = nil }
                }
            }
#endif
        }
        .background(Color.platformBackground)
    }
    
    // 初期データの読み込み
    private func loadInitialData() {
        guard let edit = editingRecord else { return }
        itemName = edit.itemName ?? ""
        salesPrice = edit.salesPrice > 0 ? String(format: "%.0f", edit.salesPrice) : ""
        purchasePrice = edit.purchasePrice > 0 ? String(format: "%.0f", edit.purchasePrice) : ""
        postage = edit.postage > 0 ? String(format: "%.0f", edit.postage) : ""
        envelopeCost = edit.envelopeCost > 0 ? String(format: "%.0f", edit.envelopeCost) : ""
        othersCost = edit.othersCost > 0 ? String(format: "%.0f", edit.othersCost) : ""
        commission = edit.commission
        saleStartDate = edit.saleStartDate ?? Date()
        saleDate = edit.saleDate ?? Date()
        isSold = edit.isSold
        memo = edit.memo ?? ""
    }
    
    // 保存処理
    private func saveAndDismiss() {
        let record = editingRecord ?? SaleRecordEntities(context: viewContext)
        
        // 商品名が書いていない場合返す
        if itemName.isEmpty {return}
        
        record.id = record.id ?? UUID()
        record.itemName = itemName
        record.salesPrice = Double(salesPrice) ?? 0
        record.purchasePrice = Double(purchasePrice) ?? 0
        record.postage = Double(postage) ?? 0
        record.envelopeCost = Double(envelopeCost) ?? 0
        record.othersCost = Double(othersCost) ?? 0
        record.commission = commission
        record.saleStartDate = saleStartDate
        record.saleDate = saleDate
        record.isSold = isSold
        record.memo = memo
        
        if !isSold {
            record.saleDate = nil
        } else if record.saleDate == nil {
            record.saleDate = Date()
        }
        
        do {
            try viewContext.save()
            // 強制的に全て更新
            viewContext.refreshAllObjects()
            
            // 成功してから binding をクリアして閉じる
            editingRecord = nil
            isPushedSave = false
            dismiss()
        } catch {
            print("保存失敗: \(error.localizedDescription)")
        }
    }
    
    // 【重要】キャンセル処理：新規作成中なら削除する
    private func cancelAndDismiss() {
        if let edit = editingRecord, isNew {
            viewContext.delete(edit) // データベースに保存される前に消す
        }
        editingRecord = nil
        dismiss()
    }
}

// プラットフォームごとに見た目を最適化した入力フィールド
struct LabeledField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isNumeric: Bool = false
    var isMultiline: Int = 1
    var focusTag: CalcView.FocusField? = nil //親要素にあるFocusFieldの型の状態
    var focusedField: FocusState<CalcView.FocusField?>.Binding? = nil // 親要素のFocusStateへのバインディング (任意)
    
    var isPushedSave: Binding<Bool>? = nil
    
    @State private var showCalc = false // 電卓の非表示
    
    var body: some View {
        #if os(iOS)
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack{
                if let focusedField {
                    VStack{
                        TextField(placeholder, text: $text, axis: .vertical)
                            .lineLimit(isMultiline == 1 ? (1...5) : (isMultiline == 2 ? (3...10) : (1...1)))
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(isNumeric ? .decimalPad : .default)
                            .focused(focusedField, equals: focusTag)
                            .overlay{
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke((isPushedSave?.wrappedValue ?? false) && text.isEmpty && !isNumeric ? Color.red : .clear, lineWidth: 1)
                            }
                        // 警告メッセージ
                        if (isPushedSave?.wrappedValue ?? false) && text.isEmpty {
                            Text("⚠️ 商品名を入力してください")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                } else {
                    VStack{
                        TextField(placeholder, text: $text, axis: .vertical)
                            .lineLimit(1...isMultiline)
                            .textFieldStyle(.roundedBorder)
                            .overlay{
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke((isPushedSave?.wrappedValue ?? false) && text.isEmpty && !isNumeric ? Color.red : .clear, lineWidth: 1)
                            }
                            .keyboardType(isNumeric ? .decimalPad : .default)
                        // 警告メッセージ
                        if (isPushedSave?.wrappedValue ?? false) && text.isEmpty {
                            Text("⚠️ 商品名を入力してください")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // 数字オンリーの時だけ電卓を表示
                if isNumeric {
                    Button(action: { showCalc = true }) {
                        Image(systemName: "plus.forwardslash.minus")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .popover(isPresented: $showCalc){
            MiniCalculatorView(targetText: $text)
        }
        .padding(.vertical, 2)
        .onChange(of: text) { oldValue, newValue in
            if isNumeric {
                let filtered = newValue.filter { "0123456789.".contains($0) }
                if filtered != newValue {
                    text = filtered
                }
            }
        }
        #else
        // macOSでは横並び
        HStack(alignment: (isMultiline > 1) ? .top : .center) {
            Text(label)
                .frame(width: 100, alignment: .trailing)
                .font(.body)
            
                TextField("", text: $text, prompt: Text(placeholder), axis: .vertical)
                    .lineLimit(isMultiline == 1 ? (1...5) : (isMultiline == 2 ? (3...10) : (1...1)))
                    .textFieldStyle(.roundedBorder)
                    .overlay{
                        RoundedRectangle(cornerRadius: 6)
                            .stroke((isPushedSave?.wrappedValue ?? false) && text.isEmpty && !isNumeric ? Color.red : .clear, lineWidth: 1)
                    }
            if (isPushedSave?.wrappedValue ?? false) && text.isEmpty {
                Text("⚠️ 商品名を入力してください")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            // 数字オンリーの時だけ電卓を表示
            if isNumeric {
                Button(action: { showCalc = true }) {
                    Image(systemName: "plus.forwardslash.minus")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .popover(isPresented: $showCalc){
            MiniCalculatorView(targetText: $text)
        }
        .padding(.vertical, 4)
        .onChange(of: text) { oldValue, newValue in
            if isNumeric {
                let filtered = newValue.filter { "0123456789.".contains($0) }
                if filtered != newValue {
                    text = filtered
                }
            }
        }
        #endif
    }
}

