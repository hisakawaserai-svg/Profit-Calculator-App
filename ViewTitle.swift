//  ViewTitle.swift
//  Reselling net profit calculation app
import SwiftUI

struct ViewTitle {
    let editingRecord: SaleRecordEntities?
    // ナビゲーションタイトルを補完
    let defaultTitle: String
    
    var viewTitle: String{
        if let record = editingRecord {
            return record.objectID.isTemporaryID ? "新規追加" : "編集"
        } else {
            return defaultTitle
        }
    }
}
