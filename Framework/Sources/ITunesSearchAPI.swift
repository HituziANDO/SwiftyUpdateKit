//
//  ITunesSearchAPI.swift
//  SwiftyUpdateKit
//
//  Created by Masaki Ando on 2021/10/08.
//  Copyright © 2021 Hituzi Ando. All rights reserved.
//

import Foundation

public struct LookUpResult {
    let artistId: UInt?
    let artistName: String?
    let artistViewUrl: String?
    let artworkUrl100: String?
    let artworkUrl512: String?
    let artworkUrl60: String?
    let averageUserRating: Int?
    let averageUserRatingForCurrentVersion: Int?
    let bundleId: String?
    let contentAdvisoryRating: String?
    let currency: String?
    let currentVersionReleaseDate: String?
    let description: String?
    let fileSizeBytes: UInt?
    let formattedPrice: String?
    let genreIds: [String]?
    let genres: [String]?
    let isVppDeviceBasedLicensingEnabled: Bool?
    let kind: String?
    let languageCodesISO2A: [String]?
    let minimumOsVersion: String?
    let price: Int?
    let primaryGenreId: Int?
    let primaryGenreName: String?
    let releaseDate: String?
    let releaseNotes: String?
    let screenshotUrls: [String]?
    let sellerName: String?
    let sellerUrl: String?
    let trackCensoredName: String?
    let trackContentRating: String?
    let trackId: UInt?
    let trackName: String?
    let trackViewUrl: String?
    let userRatingCount: Int?
    let userRatingCountForCurrentVersion: Int?
    let version: String?
    let wrapperType: String?
}

public enum ITunesSearchAPIError: Error {
    /// HTTP Error with the HTTP status code.
    case httpError(Int)
    /// The response data is invalid.
    case invalidResponseData
}

public struct ITunesSearchAPI {

    public static func lookUp(with config: SwiftyUpdateKitConfig,
                              completion: @escaping (Result<[LookUpResult], Error>) -> Void) {
        let url: URL
        if let country = config.country, !country.isEmpty {
            url = URL(string: "https://itunes.apple.com/lookup?id=\(config.iTunesID)&country=\(country)")!
        }
        else {
            url = URL(string: "https://itunes.apple.com/lookup?id=\(config.iTunesID)")!
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data, let response = response as? HTTPURLResponse else {
                completion(.failure(ITunesSearchAPIError.invalidResponseData))
                return
            }

            guard response.statusCode == 200 else {
                completion(.failure(ITunesSearchAPIError.httpError(response.statusCode)))
                return
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]] else {
                completion(.failure(ITunesSearchAPIError.invalidResponseData))
                return
            }

            let lookUpResults = results.map {
                LookUpResult(
                    artistId: $0["artistId"] as? UInt,
                    artistName: $0["artistName"] as? String,
                    artistViewUrl: $0["artistViewUrl"] as? String,
                    artworkUrl100: $0["artworkUrl100"] as? String,
                    artworkUrl512: $0["artworkUrl512"] as? String,
                    artworkUrl60: $0["artworkUrl60"] as? String,
                    averageUserRating: $0["averageUserRating"] as? Int,
                    averageUserRatingForCurrentVersion: $0["averageUserRatingForCurrentVersion"] as? Int,
                    bundleId: $0["bundleId"] as? String,
                    contentAdvisoryRating: $0["contentAdvisoryRating"] as? String,
                    currency: $0["currency"] as? String,
                    currentVersionReleaseDate: $0["currentVersionReleaseDate"] as? String,
                    description: $0["description"] as? String,
                    fileSizeBytes: $0["fileSizeBytes"] as? UInt,
                    formattedPrice: $0["formattedPrice"] as? String,
                    genreIds: $0["genreIds"] as? [String],
                    genres: $0["genres"] as? [String],
                    isVppDeviceBasedLicensingEnabled: $0["isVppDeviceBasedLicensingEnabled"] as? Bool,
                    kind: $0["kind"] as? String,
                    languageCodesISO2A: $0["languageCodesISO2A"] as? [String],
                    minimumOsVersion: $0["minimumOsVersion"] as? String,
                    price: $0["price"] as? Int,
                    primaryGenreId: $0["primaryGenreId"] as? Int,
                    primaryGenreName: $0["primaryGenreName"] as? String,
                    releaseDate: $0["releaseDate"] as? String,
                    releaseNotes: $0["releaseNotes"] as? String,
                    screenshotUrls: $0["screenshotUrls"] as? [String],
                    sellerName: $0["sellerName"] as? String,
                    sellerUrl: $0["sellerUrl"] as? String,
                    trackCensoredName: $0["trackCensoredName"] as? String,
                    trackContentRating: $0["trackContentRating"] as? String,
                    trackId: $0["trackId"] as? UInt,
                    trackName: $0["trackName"] as? String,
                    trackViewUrl: $0["trackViewUrl"] as? String,
                    userRatingCount: $0["userRatingCount"] as? Int,
                    userRatingCountForCurrentVersion: $0["userRatingCountForCurrentVersion"] as? Int,
                    version: $0["version"] as? String,
                    wrapperType: $0["wrapperType"] as? String
                )
            }
            completion(.success(lookUpResults))
        }

        task.resume()
    }
}
