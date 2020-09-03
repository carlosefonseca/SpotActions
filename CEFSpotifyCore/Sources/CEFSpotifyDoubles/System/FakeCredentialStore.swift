//
// FakeCredentialStore.swift
//

import Foundation
import CEFSpotifyCore

class FakeCredentialStore: CredentialStore {
    var store = [String: Data]()

    func exists(account: String) throws -> Bool {
        store[account] != nil
    }

    func set(value: Data, account: String) throws {
        store[account] = value
    }

    func get(account: String) throws -> Data? {
        store[account]
    }

    func delete(account: String) throws {
        store.removeValue(forKey: account)
    }

    func deleteAll() throws {
        store.removeAll()
    }
}
