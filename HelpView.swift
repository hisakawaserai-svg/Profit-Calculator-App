//  HelpView.swift
//  Profit Calculator App
// Helpタブ
import SwiftUI

struct HelpView: View {
    var body: some View {
        NavigationStack {
            List {
                // --- カテゴリー1：計算機の使いかた ---
                Section {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 20) {
                            HelpContentRow(
                                icon: "plus.forwardslash.minus",
                                iconColor: .blue,
                                title: "かんたん電卓",
                                content: "各入力欄の右側にある青いボタンを押すと電卓が開きます。仕入れ金額の合算や、送料の計算に便利です。"
                            )
                            HelpContentRow(
                                icon: "arrow.uturn.backward.circle.fill",
                                iconColor: .teal,
                                title: "目標利益の逆算",
                                content: "「これくらい利益がほしい」という目標がある時に便利です。目標利益と経費を入力すると、いくらで売ればいいか自動で計算します。"
                            )
                            HelpContentRow(
                                icon: "arrow.circlepath",
                                iconColor: .gray,
                                title: "入力欄のリセット",
                                content: "画面右上にある、くるっと回った矢印のボタンを押すと、入力した数字をすべて消して最初から計算し直すことができます。"
                            )
                            HelpContentRow(
                                icon: "plus.circle.fill",
                                iconColor: .green,
                                title: "出品の記録（＋ボタン）",
                                content: "計算機画面の右上にある「＋」ボタンを押すと記録できます。出品日を入力すると「出品中」タブに登録されます。"
                            )
                        }
                        .padding(.vertical, 12)
                    } label: {
                        Label("利益計算機について", systemImage: "plus.forwardslash.minus")
                            .font(.title3.bold())
                            .foregroundColor(.blue)
                    }
                }

                // --- カテゴリー2：在庫と実績の管理 ---
                Section {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 20) {
                            HelpContentRow(
                                icon: "arrow.circlepath",
                                iconColor: .gray,
                                title: "表示のリセット",
                                content: "カレンダーで月を選んでいる時に、右上の矢印ボタンを押すと、すべての期間のデータをまとめて表示する状態に戻せます。"
                            )
                            HelpContentRow(
                                icon: "pencil",
                                iconColor: .blue,
                                title: "データの編集",
                                content: "詳細画面の右上にある「ペン」ボタンを押すと編集画面が開き、そのデータの編集ができます。"
                            )
                            HelpContentRow(
                                icon: "checkmark.seal.fill",
                                iconColor: .orange,
                                title: "売れた時の操作",
                                content: "商品が売れたら、編集画面で「売却済み」スイッチをオンにして、販売日を入力してください。自動的に「実績」タブへ移動します。"
                            )
                            HelpContentRow(
                                icon: "bolt.fill",
                                iconColor: .yellow,
                                title: "かんたん売却更新",
                                content: "詳細画面にある「出品中」のスイッチをオンにするだけで、販売日を「今日」にして実績へ移動させることができます。"
                            )
                        }
                        .padding(.vertical, 12)
                    } label: {
                        Label("出品と売却のルール", systemImage: "shippingbox.fill")
                            .font(.title3.bold())
                            .foregroundColor(.orange)
                    }
                }

                // --- カテゴリー3：データの修正や削除 ---
                Section {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 20) {
                            HelpContentRow(
                                icon: "pencil.and.outline",
                                iconColor: .red,
                                title: "記録の直し方・消し方",
                                content: "リストの記録をタップして詳細画面を開くと、右上に「編集（ペン）」や「削除（ゴミ箱）」ボタンがあります。"
                            )
                            HelpContentRow(
                                icon: "magnifyingglass",
                                iconColor: .gray,
                                title: "商品の探し方",
                                content: "画面上の検索バーに名前を入れたり、並び替えボタン（上下矢印マーク）を使ってみたい記録を探せます。"
                            )
                            HelpContentRow(
                                icon: "chart.bar.fill",
                                iconColor: .indigo,
                                title: "分析グラフの活用",
                                content: "分析タブではこれまでの売上推移が見れます。グラフの棒を触ると、その日の詳細な数字と下にその内訳が表示され、日々の頑張りを振り返ることができます。"
                            )
                        }
                        .padding(.vertical, 12)
                    } label: {
                        Label("記録の整理と分析", systemImage: "chart.bar")
                            .font(.title3.bold())
                            .foregroundColor(.purple)
                    }
                }
            }
            .navigationTitle("使いかたガイド")
            #if os(iOS)
            .listStyle(.insetGrouped) // iPhone/iPadなら
            #else
            .listStyle(.inset)        // Macなら
            #endif
        }
    }
}

// 各項目を大きく表示する部品
struct HelpContentRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // アイコンを少し大きく
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 35)
            
            VStack(alignment: .leading, spacing: 6) {
                // タイトルを headline に
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // 説明文を body（標準サイズ）に
                Text(content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4) // 行間を少し空けて読みやすく
            }
        }
    }
}
