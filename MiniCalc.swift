//  MiniCalc.swift
//  Profit Calculator App
import SwiftUI

struct MiniCalculatorView: View {
    // 親画面の入力欄（String）と直接つながる
    @Binding var targetText: String
    
    @State private var display: String = ""
    @Environment(\.dismiss) private var dismiss

    let buttons: [[String]] = [
        ["7", "8", "9", "/"],
        ["4", "5", "6", "*"],
        ["1", "2", "3", "-"],
        ["0", "C", "=", "+"]
    ]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("電卓").font(.caption).bold()
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            // 表示画面
            Text(display.isEmpty ? "0" : display)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .font(.system(.title, design: .monospaced))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            // ボタン配置
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { label in
                        Button(action: { handleButton(label) }) {
                            Text(label)
                                .font(.title2.bold())
                                .frame(width: 50, height: 50)
                                .background(isOperator(label) ? Color.orange : Color.platformSecondaryBackground)
                                .foregroundColor(isOperator(label) ? .white : .primary)
                                .cornerRadius(25) // 丸いボタン
                                .shadow(radius: 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // 決定ボタン
            Button(action: {
                calculate()
                targetText = display
                dismiss()
            }) {
                Text("この数字を入力する")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(width: 280)
        .onAppear{
            if targetText == "0" {
                display = ""
            } else {
                display = targetText
            }
        }
    }
    
    // buttonsの処理
    private func handleButton(_ label: String) {
        if label == "C" {
            display = ""
        } else if label == "=" {
            calculate()
        } else {
            display += label
        }
    }

    // 計算
    private func calculate() {
        // 空っぽ、または記号だけで終わっている場合は計算しない
        guard !display.isEmpty else { return }
        let lastChar = String(display.last!)
        if isOperator(lastChar) { return }

        // 計算実行
        let expression = NSExpression(format: display)
        // エラーが起きないように念のためチェック
        if let result = expression.expressionValue(with: nil, context: nil) as? Double {
            // 日本円なので基本は整数、割り算などで小数が出た時だけ小数点を出す
            if result.truncatingRemainder(dividingBy: 1) == 0 {
                display = String(format: "%.0f", result)
            } else {
                display = String(format: "%.1f", result) // 小数点1桁まで
            }
        }
    }

    // 計算式
    private func isOperator(_ label: String) -> Bool {
        return ["/", "*", "-", "+", "="].contains(label)
    }
}
