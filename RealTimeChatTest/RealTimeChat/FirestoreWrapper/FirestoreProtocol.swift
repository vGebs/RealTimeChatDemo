//
//  FirestoreProtocol.swift
//  RealTimeChatTest
//
//  Created by Vaughn on 2023-03-11.
//

import Foundation

public protocol FirestoreProtocol: Codable {
    var documentID: String? { get set }
}
