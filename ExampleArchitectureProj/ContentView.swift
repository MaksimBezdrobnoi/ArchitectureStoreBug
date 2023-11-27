//
//  ContentView.swift
//  ExampleArchitectureProj
//
//  Created by Maksim Bezdrobnoi on 06.10.2023.
//

import SwiftUI

struct ContentView: View {

    @ObservedObject private var viewStore: ViewStoreOf<TestReducer>
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    @State var timeCount = 0

    public init(viewStore: ViewStoreOf<TestReducer>) {
        self.viewStore = viewStore
    }

    var body: some View {
        ZStack {
            VStack {
                if timeCount == 50 {
                    Text("END")
                        .padding()
                }

                viewStore.state.errorActive
                ?  Color.red.frame(width: 100, height: 100)
                : Color.green.frame(width: 100, height: 100)
            }

            SomeView(isActive: Binding(
                get: { viewStore.state.errorActive },
                set: { _ in viewStore.send(.resignError) }
            ))
        }
        .onReceive(timer) { value in
            timeCount += 1
            viewStore.send(.getError)
            if timeCount == 50 {
                timer.upstream.connect().cancel()
            }
        }
    }
}

struct SomeView: View {

    @Binding var isActive: Bool

    var body: some View {
        VStack {
            if isActive {
                Text("Hello")
            }
        }
        .onChange(of: isActive, perform: { value in
            if value {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    print("END")
                    isActive = false
                }
            }
        })
    }
}
