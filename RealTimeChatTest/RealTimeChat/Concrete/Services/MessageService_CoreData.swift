//
//  MessageService_CoreData.swift
//  RealTimeChatTest
//
//  Created by Vaughn on 2023-03-10.
//

import Foundation
import Combine
import CoreData

class MessageService_CoreData: MessengerCache {
    
    private let cache: CoreDataWrapper
    
    init() {
        let storeURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("MessageModel.sqlite")
        
        self.cache = CoreDataWrapper(modelName: "MessageModel", storeURL: storeURL)
    }
    
    func fetchConversation(between uid: String, uid2: String) -> AnyPublisher<[Message], Error> {
        return Publishers.Zip(
            self.fetchMessage(to: uid, from: uid2),
            self.fetchMessage(to: uid2, from: uid))
        .map { (messages1, messages2) in
            let unsortedMessages = messages1 + messages2
            let sortedMessages = unsortedMessages.sorted(by: { $0.timestamp > $1.timestamp })
            
            return sortedMessages
        }
        .eraseToAnyPublisher()
    }
    
    func pushMessage(_ message: Message) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            
            let msg = self!.cache.create(objectType: MessageCoreData.self)
            
            msg.timestamp = message.timestamp
            msg.messageText = message.messageText
            msg.documentID = message.documentID
            msg.fromUID = message.fromUID
            msg.toUID = message.toUID
            msg.openedDate = message.openedDate
            
            do {
                try self!.cache.saveContext()
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func readMessage(with docID: String, msg: Message) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            do {
                let msgs = try self!.fetchMessage(with: docID)
                
                let message = msgs[0]
                message.openedDate = msg.openedDate
                
                do {
                    try self!.cache.saveContext()
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func deleteMessage(with docID: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            do {
                let msgs = try self!.fetchMessage(with: docID)
                
                for msg in msgs {
                    try self!.cache.delete(object: msg)
                }
                
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
}

extension MessageService_CoreData {
    
    //The reason we are returning an array is because the fetch request returns an array of items.
    // There should only be 1 value returned, but if there was a duplicate for some reason then we will delete it as well.
    private func fetchMessage(with docID: String) throws -> [MessageCoreData] {
        
        let fetchRequest = NSFetchRequest<MessageCoreData>(entityName: "MessageCoreData")
        fetchRequest.predicate = NSPredicate(format: "documentID == %@", docID)
        
        let msgs = try self.cache.fetch(fetchRequest: fetchRequest)
        return msgs
    }
    
    private func fetchMessage(to uid: String, from uid2: String) -> AnyPublisher<[Message], Error> {
        return Future<[Message], Error> { promise in
            let fetchRequest = NSFetchRequest<MessageCoreData>(entityName: "MessageCoreData")
            fetchRequest.predicate = NSPredicate(format: "toUID == %@ && fromUID == %@", uid, uid2)
            
            do {
                let msgs = try self.cache.fetch(fetchRequest: fetchRequest)
                var finalMsgs: [Message] = []
                for msg in msgs {
                    let newMessage = Message(
                        documentID: msg.documentID,
                        toUID: msg.toUID!,
                        fromUID: msg.fromUID!,
                        messageText: msg.messageText!,
                        timestamp: msg.timestamp!,
                        openedDate: msg.openedDate
                    )
                    finalMsgs.append(newMessage)
                }
                promise(.success(finalMsgs))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
}
