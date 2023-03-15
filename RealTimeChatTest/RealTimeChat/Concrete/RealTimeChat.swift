//
//  RealTimeChat.swift
//  RealTimeChatTest
//
//  Created by Vaughn on 2023-03-10.
//

import Foundation
import Combine

protocol RealTimeChatProtocol {
    var mostRecentMessages: [Message] { get }
    
    func sendMessage(to uid: String)
    func deleteMessage(with messageID: String)
    func readMessage(with messageID: String)
    func getCachedMessages(forUserWith uid: String)
}

class RealTimeChat: RealTimeChatProtocol {
    
    @Published private var mostRecentMessagesSet: Set<Message> = Set()
    @Published private(set) var mostRecentMessages: [Message] = []
    
    private let coordinator: MessageCoordinator
    
    @Published var currentChatMessages: [Message] = []
    
//    private var allNewMessagesObserver: AnyCancellable
    
    init(coordinator: MessageCoordinator) {
        self.coordinator = coordinator
        
//        $mostRecentMessagesSet
//            .map { Array($0).sorted{ $0.timestamp > $1.timestamp } }
//            .assign(to: &$mostRecentMessages)
//
//        observeNewMessages()
    }
    
    private func observeNewMessages() {
        
    }
    
    func observeMessage(with messageID: String) {
        
    }
    
    func sendMessage(to uid: String) {
        
    }
    
    func fetchMessages(betweenMyselfAnd uid: String) {
        
    }
    
    func readMessage(with messageID: String) {
        
    }
    
    func deleteMessage(with messageID: String) {
        
    }
    
    func getCachedMessages(forUserWith uid: String) {
        
    }
}
