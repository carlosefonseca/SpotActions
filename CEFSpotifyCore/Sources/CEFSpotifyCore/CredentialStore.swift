//
//  CredentialStore.swift
//

import Foundation

public protocol CredentialStore {
    func exists(account: String) throws -> Bool
    func set(value: Data, account: String) throws
    func get(account: String) throws -> Data?
    func delete(account: String) throws
    func deleteAll() throws
}
