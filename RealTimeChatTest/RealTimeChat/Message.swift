//
//  Message.swift
//  RealTimeChatTest
//
//  Created by Vaughn on 2023-03-10.
//

import Foundation
import FirebaseFirestoreSwift
import CoreData

struct Message: Hashable, FirestoreProtocol {
    @DocumentID var documentID: String?
    
    var toUID: String
    var fromUID: String
    var messageText: String
    var timestamp: Date
    var openedDate: Date?
}
