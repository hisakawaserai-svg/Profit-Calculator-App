//  PersistenceController.swift
//  Profit Calculator App
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // Create a local container to avoid capturing `self` in the escaping closure
        let container = NSPersistentContainer(name: "MyAppDataModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
            // 親（保存先）での変更を、今見ている画面に自動で反映させる
            container.viewContext.automaticallyMergesChangesFromParent = true

            // データがぶつかった場合、新しい入力内容を優先して上書きする
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }
        // Assign to the stored property after configuration
        self.container = container
    }
}
