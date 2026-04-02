//  Profit Calculator App.swift
//  Profit Calculator App


import SwiftUI
import CoreData

@main
struct Reselling_net_profit_calculation_appApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
