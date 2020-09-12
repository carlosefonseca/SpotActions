//
// FilterTracksHandler.swift
//

import Foundation
import Intents
import CEFSpotifyCore
import Combine

class FilterTracksHandler: NSObject, FilterTracksIntentHandling {
    func handle(intent: FilterTracksIntent, completion: @escaping (FilterTracksIntentResponse) -> Void) {
        guard let tracks = intent.tracks else {
            completion(.failure(error: "No tracks specified!"))
            return
        }

        let titles = intent.titles
        let artists = intent.artists

        var modeIsSelect: Bool?

        switch intent.mode {
        case .unknown:
            break
        case .select:
            modeIsSelect = true
        case .reject:
            modeIsSelect = false
        }

        guard modeIsSelect != nil else {
            completion(.failure(error: "No filter mode specified!"))
            return
        }

        let isRegex: Bool = intent.isRegex?.boolValue ?? false
        var titleRegex: NSRegularExpression?
        if let titles = titles {
            do {
                titleRegex = try createRegexFrom(strings: titles, escaped: !isRegex)
            } catch {
                completion(.failure(error: "Failed to parse titles regex!"))
                return
            }
        }

        var artistRegex: NSRegularExpression?
        if let artists = artists {
            do {
                artistRegex = try createRegexFrom(strings: artists, escaped: !isRegex)
            } catch {
                completion(.failure(error: "Failed to parse artists regex!"))
                return
            }
        }

        let filtered: [Track]
        if modeIsSelect! {
            filtered = tracks.filter { $0.matches(titleRegex: titleRegex, artistRegex: artistRegex) }
        } else {
            filtered = tracks.filter { !$0.matches(titleRegex: titleRegex, artistRegex: artistRegex) }
        }

        completion(.success(result: filtered))
    }

    func createRegexFrom(strings: [String], escaped: Bool) throws -> NSRegularExpression {
        let join = strings.map { escaped ? NSRegularExpression.escapedPattern(for: $0) : $0 }.joined(separator: ")|(")
        return try NSRegularExpression(pattern: "(\(join))")
    }
}

extension String {
    func contains(regex: NSRegularExpression) -> Bool {
        let range = NSRange(location: 0, length: utf16.count)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}

private extension Track {
    func matches(titleRegex: NSRegularExpression?, artistRegex: NSRegularExpression?) -> Bool {
        var matchTitle: Bool = true
        if let titleRegex = titleRegex {
            matchTitle = trackName?.contains(regex: titleRegex) ?? true
        }

        var matchArtist = true
        if let artistRegex = artistRegex {
            matchArtist = (artists?.first(where: { artist in artist.displayString.contains(regex: artistRegex) }) != nil)
        }

        print("\(displayString) title: \(matchTitle) && artist: \(matchArtist) = \(matchTitle && matchArtist) ")

        return matchTitle && matchArtist
    }
}
