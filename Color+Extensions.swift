//  Color+Extensions.swift
//  Profit Calculator App
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    static let platformBackground: Color = {
        // macOSネイティブ、または Mac Catalyst の場合
        #if os(macOS) || targetEnvironment(macCatalyst)
        // macOSの標準的なウィンドウ背景（少しグレー）
        return Color(white: 0.95)
        #else
        return Color(uiColor: .systemGroupedBackground)
        #endif
    }()

    static let platformSecondaryBackground: Color = {
        #if os(macOS) || targetEnvironment(macCatalyst)
        return .white // カードや入力欄は真っ白に固定
        #else
        return Color(uiColor: .secondarySystemGroupedBackground)
        #endif
    }()
}
