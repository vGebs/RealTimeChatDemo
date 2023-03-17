//
//  MessageService_Firestore.swift
//  RealTimeChatTest
//
//  Created by Vaughn on 2023-03-10.
//

import Foundation
import Combine
import FirebaseFirestore

class MessageService_Firestore: MessengerRemote {
    
    private var firestore = FirestoreWrapper.shared
    
    private let collection = "Messages"
    
    private let db = Firestore.firestore()
    
    init() {}
    
    func observeMessage(with docID: String) -> AnyPublisher<(Message, DocChangeType), Error> {
        return firestore.listenByDocument(collection: collection, documentId: docID)
    }
    
    //expirimental
    func observeMessages(for currentUID: String, newerThan date: Date) -> AnyPublisher<[(Message, DocChangeType)], Error> {
        return Publishers.Zip(self.observeMessagesToMe(forCurrent: currentUID, newerThan: date),
                              self.observeMessagesFromMe(forCurrent: currentUID, newerThan: date))
        .map { return $0 + $1 }
        .eraseToAnyPublisher()
    }
    
    func observeMessagesToMe(forCurrent uid: String, newerThan date: Date) -> AnyPublisher<[(Message, DocChangeType)], Error> {
        let query: Query = db.collection(collection)
            .whereField("toID", isEqualTo: uid)
            .whereField("timestamp", isGreaterThan: date)
        
        return observeHelper(query)
    }
    
    func observeMessagesFromMe(forCurrent uid: String, newerThan date: Date) -> AnyPublisher<[(Message, DocChangeType)], Error> {
        let query: Query = db.collection(collection)
            .whereField("fromID", isEqualTo: uid)
            .whereField("timestamp", isGreaterThan: date)
        
        return observeHelper(query)
    }
    
    func pushMessage(_ message: Message) -> AnyPublisher<Void, Error> {
        return firestore.create(collection: collection, data: message)
    }
    
    func readMessage(with docID: String, msg: Message) -> AnyPublisher<Void, Error> {
        return firestore.update(collection: collection, documentId: docID, data: msg)
    }
    
    func deleteMessage(with docID: String) -> AnyPublisher<Void, Error> {
        return firestore.delete(collection: collection, documentId: docID)
    }
}

extension MessageService_Firestore {
    private func observeHelper(_ query: Query) -> AnyPublisher<[(Message, DocChangeType)], Error> {
        return firestore.listenByQuery(query: query)
            .map { array -> [(Message, DocChangeType)] in
                array.map { (message, changeType) -> (Message, DocChangeType) in
                    switch changeType {
                    case .added:
                        return (message, DocChangeType.added)
                        
                    case .modified:
                        return (message, DocChangeType.modified)
                        
                    case .removed:
                        return (message, DocChangeType.removed)
                    }
                }
            }
            .eraseToAnyPublisher()
    }
}
