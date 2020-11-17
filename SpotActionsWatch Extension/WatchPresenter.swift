//
// WatchPresenter.swift
//

import Foundation
import Combine

class WatchPresenter: ObservableObject {

    var connectivity: WatchConnect

    private var cancellableSet = Set<AnyCancellable>()

    @Published var track: String = "-"
    @Published var artists: String = "-"

    init(connectivity: WatchConnect) {
        self.connectivity = connectivity

        connectivity.$playback.receive(on: RunLoop.main).sink {
            self.track = $0?.title ?? "-"
            self.artists = $0?.artist ?? "-"
        }
        .store(in: &cancellableSet)
    }

//    var playback: AnyPublisher<PlaybackViewModel?, Never> {
//        connectivity.$playback.eraseToAnyPublisher()
//    }
}
