//
//  MessageCoordinator.swift
//  RealTimeChatTest
//
//  Created by Vaughn on 2023-03-13.
//

import Foundation
import Combine

class MessageCoordinator: MessageCoordinatorProtocol {
    
    var cache:  MessengerCache
    var remote: MessengerRemote
    
    private var cancellables: [AnyCancellable] = []
    
    init(cache: MessengerCache, remote: MessengerRemote) {
        self.cache = cache
        self.remote = remote
    }
    
    func observeMessage(with docID: String) -> AnyPublisher<(Message, DocChangeType), Error> {
        return remote.observeMessage(with: docID)
            .flatMap { [weak self] (message, docChange) -> AnyPublisher<(Message, DocChangeType), Error> in
                switch docChange {
                case .added:
                    self!.cache.pushMessage(message)
                        .retry(3)
                        .sink { _ in } receiveValue: { _ in }
                        .store(in: &self!.cancellables)
                    
                case .modified:
                    self!.cache.readMessage(with: docID, msg: message)
                        .retry(3)
                        .sink { _ in } receiveValue: { _ in }
                        .store(in: &self!.cancellables)
                    
                case .removed:
                    self!.cache.deleteMessage(with: docID)
                        .retry(3)
                        .sink { _ in } receiveValue: { _ in }
                        .store(in: &self!.cancellables)
                }
                
                return Just((message, docChange)).setFailureType(to: Error.self).eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }
    
    //expirimental
    func observeMessages(for currentUID: String) -> AnyPublisher<[(Message, DocChangeType)], Error> {
        return remote.observeMessages(for: currentUID)
            .flatMap { [weak self] messages -> AnyPublisher<[(Message, DocChangeType)], Error> in
                for msg in messages {
                    switch msg.1 {
                    case .added:
                        self!.cache.pushMessage(msg.0)
                            .retry(3)
                            .sink { _ in } receiveValue: { _ in }
                            .store(in: &self!.cancellables)
                            
                    case .modified:
                        self!.cache.readMessage(with: msg.0.documentID!, msg: msg.0)
                            .retry(3)
                            .sink { _ in } receiveValue: { _ in }
                            .store(in: &self!.cancellables)

                    case .removed:
                        self!.cache.deleteMessage(with: msg.0.documentID!)
                            .retry(3)
                            .sink { _ in } receiveValue: { _ in }
                            .store(in: &self!.cancellables)
                    }
                }
                
                return Just(messages).setFailureType(to: Error.self).eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }
    
    func observeMessagesToMe(forCurrent uid: String) -> AnyPublisher<[(Message, DocChangeType)], Error> {
        return remote.observeMessagesToMe(forCurrent: uid)
            .flatMap { [weak self] messages -> AnyPublisher<[(Message, DocChangeType)], Error> in
                for msg in messages {
                    switch msg.1 {
                    case .added:
                        self!.cache.pushMessage(msg.0)
                            .retry(3)
                            .sink { _ in } receiveValue: { _ in }
                            .store(in: &self!.cancellables)
                            
                    case .modified:
                        self!.cache.readMessage(with: msg.0.documentID!, msg: msg.0)
                            .retry(3)
                            .sink { _ in } receiveValue: { _ in }
                            .store(in: &self!.cancellables)

                    case .removed:
                        self!.cache.deleteMessage(with: msg.0.documentID!)
                            .retry(3)
                            .sink { _ in } receiveValue: { _ in }
                            .store(in: &self!.cancellables)
                    }
                }
                
                return Just(messages).setFailureType(to: Error.self).eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }
    
    func observeMessagesFromMe(forCurrent uid: String) -> AnyPublisher<[(Message, DocChangeType)], Error> {
        return remote.observeMessagesFromMe(forCurrent: uid)
            .flatMap { [weak self] messages -> AnyPublisher<[(Message, DocChangeType)], Error> in
                for msg in messages {
                    switch msg.1 {
                    case .added:
                        self!.cache.pushMessage(msg.0)
                            .retry(3)
                            .sink { _ in } receiveValue: { _ in }
                            .store(in: &self!.cancellables)
                            
                    case .modified:
                        self!.cache.readMessage(with: msg.0.documentID!, msg: msg.0)
                            .retry(3)
                            .sink { _ in } receiveValue: { _ in }
                            .store(in: &self!.cancellables)

                    case .removed:
                        self!.cache.deleteMessage(with: msg.0.documentID!)
                            .retry(3)
                            .sink { _ in } receiveValue: { _ in }
                            .store(in: &self!.cancellables)
                    }
                }
                
                return Just(messages).setFailureType(to: Error.self).eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }
    
    func fetchConversation(between uid: String, uid2: String) -> AnyPublisher<[Message], Error> {
        return cache.fetchConversation(between: uid, uid2: uid2)
    }
    
    func pushMessage(_ message: Message) -> AnyPublisher<Void, Error> {
        return remote.pushMessage(message)
            .flatMap { [weak self] in
                self!.cache.pushMessage(message)
            }.eraseToAnyPublisher()
    }
    
    func readMessage(with docID: String, msg: Message) -> AnyPublisher<Void, Error> {
        return remote.readMessage(with: docID, msg: msg)
            .flatMap { [weak self] in
                self!.cache.readMessage(with: docID, msg: msg)
            }.eraseToAnyPublisher()
    }
    
    func deleteMessage(with docID: String) -> AnyPublisher<Void, Error> {
        return remote.deleteMessage(with: docID)
            .flatMap { [weak self] in
                self!.cache.deleteMessage(with: docID)
            }.eraseToAnyPublisher()
    }
}
