//
//  RealTimeChat.swift
//  RealTimeChatTest
//
//  Created by Vaughn on 2023-03-10.
//

import Foundation
import Combine

protocol RealTimeChatProtocol: ObservableObject {
    var mostRecentMessages: [Message] { get }
    
    func sendMessage(_ message: Message)
    func deleteMessage(with docID: String)
    func readMessage(_ msg: Message)
    func fetchConversation(with uid: String)
}

class RealTimeChat: RealTimeChatProtocol {
    
    @Published private var mostRecentMessagesDict: [String: Message] = [:]
    @Published private(set) var mostRecentMessages: [Message] = []
    
    private let coordinator: MessageCoordinator
    private let currentUID: String
    
    @Published var currentChatMessages: [Message] = []
    
    private var allNewMessagesObserver: AnyCancellable?
    private var oneTimePublishers: [AnyCancellable] = []
    private var mostRecentMessageObserver: [String: AnyCancellable] = [:]
    
    init(coordinator: MessageCoordinator, currentUID: String) {
        self.coordinator = coordinator
        self.currentUID = currentUID
        
        $mostRecentMessagesDict
            .map { dictionary in
                dictionary.values.sorted { $0.timestamp > $1.timestamp }
            }
            .sink { [weak self] sortedMessages in
                
                for msg in sortedMessages {
                    
                    if msg.toUID == self!.currentUID {
                        if self?.mostRecentMessageObserver[msg.fromUID] == nil {
                            self?.observeMessage(with: msg.documentID!, friend: msg.fromUID)
                        }
                    } else {
                        if self?.mostRecentMessageObserver[msg.toUID] == nil {
                            self?.observeMessage(with: msg.documentID!, friend: msg.toUID)
                        }
                    }
                }
                
                self?.mostRecentMessages = sortedMessages
            }
            .store(in: &oneTimePublishers)
        
        //1. we need to fetch cache most recent message for each conversation
        //2. once we get the messages back, we will observe each one and store
        //3. we also need to get the most recent message (regardless of the conversation)
        //      - we will then observe all new incoming messages
        self.fetchMostRecentMessages()
    }
    
    func sendMessage(_ message: Message) {
        coordinator.pushMessage(message)
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .sink { completion in
                switch completion {
                case .finished:
                    print("RealTimeChat: Message Sent with docID: \(String(describing: message.documentID))")
                case .failure(let e):
                    print("RealTimeChat: Failed to send message with docID: \(String(describing: message.documentID))")
                    print("RealTimeChat: \(e)")
                }
            } receiveValue: { _ in }
            .store(in: &oneTimePublishers)
    }
    
    func fetchConversation(with uid: String) {
        coordinator.fetchConversation(between: currentUID, uid2: uid)
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    print("RealTimeChat: Finished fetching conversation for uid: \(uid)")
                case .failure(let e):
                    print("RealTimeChat: Failed to fetch conversation for uid: \(uid)")
                    print("RealTimeChat: \(e)")
                }
            } receiveValue: { [weak self] msgs in
                let sorted = msgs.sorted { $0.timestamp > $1.timestamp }
                self?.currentChatMessages = sorted
            }.store(in: &oneTimePublishers)
    }
    
    func readMessage(_ msg: Message) {
        coordinator.readMessage(with: msg.documentID!, msg: msg)
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .sink { completion in
                switch completion {
                case .finished:
                    print("RealTimeChat: Message read with docID: \(String(describing: msg.documentID))")
                case .failure(let e):
                    print("RealTimeChat: Failed to read message with docID: \(String(describing: msg.documentID))")
                    print("RealTimeChat: \(e)")
                }
            } receiveValue: { _ in }
            .store(in: &oneTimePublishers)
    }
    
    func deleteMessage(with docID: String) {
        coordinator.deleteMessage(with: docID)
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .sink { completion in
                switch completion {
                case .finished:
                    print("RealTimeChat: Message deleted with docID: \(docID)")
                case .failure(let e):
                    print("RealTimeChat: Failed to delete message with docID: \(docID)")
                    print("RealTimeChat: \(e)")
                }
            } receiveValue: { _ in }
            .store(in: &oneTimePublishers)
    }
}

extension RealTimeChat {
    //Fetch the most recent message for all conversations
    private func fetchMostRecentMessages() {
        coordinator.fetchMostRecentMessageForEachConversation(for: currentUID)
            .subscribe(on: DispatchQueue.global(qos: .userInteractive))
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    print("")
                case .failure(let e ):
                    print("RealTimeChat: Failed to fetch most recent messages")
                    print("RealTimeChat: \(e)")
                }
            } receiveValue: { [weak self] dict in
                
                if dict.isEmpty {
                    
                    let dateString = "1997-06-12" // The date you want to create

                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd" // The format of the date string

                    if let date = dateFormatter.date(from: dateString) {
                        self?.observeMessages(newerThan: date)
                    } else {
                        print("RealTimeChat: Date error")
                    }
                } else {
                    let sortedMessageArray = dict.values.sorted { $0.timestamp > $1.timestamp }
                    let maxMessage = sortedMessageArray.max { $0.timestamp > $1.timestamp }
                    
                    self?.observeMessages(newerThan: maxMessage!.timestamp)
                    
                    self?.mostRecentMessagesDict = dict
                }
            }.store(in: &oneTimePublishers)
    }
    
    private func observeMessages(newerThan date: Date) {
        allNewMessagesObserver = coordinator.observeMessages(for: currentUID, newerThan: date)
            .subscribe(on: DispatchQueue.global(qos: .userInteractive))
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    print("RealTimeChat: Observing new messages")
                case .failure(let e):
                    print("RealTimeChat: Failed to observe messages")
                    print("RealTimeChat: \(e)")
                }
            } receiveValue: { [weak self] msgs in
                //we are getting an array of messages, we need to add them to a dict then
                //  we need to find any new messages from that user and put them in the the class dict
                for message in msgs {
                    switch message.1 {
                    case .added:
                        if message.0.toUID == self!.currentUID {
                            self?.mostRecentMessagesDict[message.0.fromUID] = message.0
                        } else {
                            self?.mostRecentMessagesDict[message.0.toUID] = message.0
                        }
                    case .modified:
                        if message.0.toUID == self!.currentUID {
                            self?.mostRecentMessagesDict[message.0.fromUID] = message.0
                        } else {
                            self?.mostRecentMessagesDict[message.0.toUID] = message.0
                        }
                    case .removed:
                        //what happens when the newest message is deleted?
                        //  we need to first remove it from the cache then fetch the most recent message for that user
                        // this class does not handle the cache, it just uses the coordinator, so the coordinator will have to deal with this
                        //we just need to fetch the most recent message from that chat
                        if message.0.toUID == self!.currentUID {
                            self?.fetchMostRecentMessageForConversation(with: self!.currentUID, and: message.0.fromUID)
                        } else {
                            self?.fetchMostRecentMessageForConversation(with: self!.currentUID, and: message.0.toUID)
                        }
                        
                    }
                }
            }
    }
    
    private func fetchMostRecentMessageForConversation(with currentUID: String, and uid: String) {
        self.coordinator.fetchMostRecentMessageForConversation(with: self.currentUID, and: uid)
            .subscribe(on: DispatchQueue.global(qos: .userInteractive))
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    print("RealTimeChat: Finished fetching most recent message for chat")
                case .failure(let e):
                    print("RealTimeChat: Failed to fetch most recent message")
                    print("RealTimeChat: \(e)")
                }
            } receiveValue: { [weak self] msg in
                if let msg = msg {
                    self?.mostRecentMessagesDict[uid] = msg
                } else {
                    self?.mostRecentMessagesDict[uid] = nil
                }
            }.store(in: &oneTimePublishers)
    }
    
    private func observeMessage(with docID: String, friend uid: String) {
        
        mostRecentMessageObserver[uid] = self.coordinator.observeMessage(with: docID)
            .subscribe(on: DispatchQueue.global(qos: .userInteractive))
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    print("RealTimeChat: Observing message with docID: \(docID)")
                case .failure(let e):
                    print("RealTimeChat: Failed to observe message with docID: \(docID)")
                    print("RealTimeChat: \(e)")
                }
            } receiveValue: { [weak self] (message, docChange) in
                switch docChange {
                case .added:
                    //we already have the document, so dont worry about it
                    return
                case .modified:
                    //it was read, so update the most recent message
                    self?.mostRecentMessagesDict[uid] = message
                case .removed:
                    // message was deleted, remove the message from the dict and remove the observer from the observer dict
                    self?.mostRecentMessagesDict[uid] = nil
                    self?.mostRecentMessageObserver[uid] = nil
                }
            }
    }
}
