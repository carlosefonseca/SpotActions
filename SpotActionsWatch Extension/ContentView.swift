//
// ContentView.swift
//

import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject var presenter: WatchPresenter

    init(presenter: WatchPresenter) {
        self.presenter = presenter
    }

    var body: some View {
        Text("\(presenter.track)")
            .padding()
    }
}

// struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(presenter: WatchPresenter()
//    }
// }
