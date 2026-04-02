//  AddRecordButton.swift
//  Profit Calculator App
//
//  概要：新規レコード作成画面（RecordFormView）を呼び出す共通ボタン。
//

import SwiftUI

/// アプリ全体で使用する、新規データ登録用のプラスボタン
struct AddRecordButton: View {
    /// 編集対象のレコード（新規作成時はnilを代入する）
    @Binding var editingRecord: SaleRecordEntities?
    /// 入力フォームの表示フラグ
    @Binding var showingForm: Bool

    var body: some View {
        Button {
            // 既存の選択状態を解除し、新規作成モードとしてフォームを開く
            editingRecord = nil
            showingForm = true
        } label: {
            Image(systemName: "plus")
        }
    }
}
