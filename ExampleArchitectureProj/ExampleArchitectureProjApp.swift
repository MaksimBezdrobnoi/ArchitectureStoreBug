//
//  ExampleArchitectureProjApp.swift
//  ExampleArchitectureProj
//
//  Created by Maksim Bezdrobnoi on 06.10.2023.
//

import SwiftUI

@main
struct ExampleArchitectureProjApp: App {
    let store: StoreOf<TestReducer> = .init(
        initialState: .init(),
        reducer: TestReducer()
    )

    var body: some Scene {
        WindowGroup {
            ContentView(viewStore: .init(store))
        }
    }
}
