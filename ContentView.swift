//  ContentView.swift
//  Profit Calculator App
import SwiftUI

struct ContentView: View {
    @State private var editingRecord: SaleRecordEntities? = nil
    
    var body: some View{
        TabView{
            CalcView(editingRecord: $editingRecord)
                .tabItem{
                    Image(systemName: "function")
                    Text("計算")
                }
            // 📦 出品中（在庫）タブ
            MonthlyRecordList(isSoldMode: false)
                .tabItem {
                    Label("出品中", systemImage: "shippingbox")
                }

            // 💰 売上実績タブ
            MonthlyRecordList(isSoldMode: true)
                .tabItem {
                    Label("実績", systemImage: "yensign.circle")
                }
            DataView()
                .tabItem{
                    Image(systemName: "chart.bar")
                    Text("データ")
                }
            HelpView()
                .tabItem {
                    Label("ヘルプ", systemImage: "questionmark.circle")
                }
        }
        .navigationTitle("純利益計算機")
    }
}
    
#Preview{
    ContentView()
}
