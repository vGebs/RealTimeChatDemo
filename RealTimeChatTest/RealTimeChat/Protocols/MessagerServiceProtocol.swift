//
//  MessagerServiceProtocol.swift
//  RealTimeChatTest
//
//  Created by Vaughn on 2023-03-10.
//

import Foundation
import Combine

protocol MessengerBase {
    func pushMessage(_ message: Message) -> AnyPublisher<Void, Error>
    func readMessage(with docID: String, msg: Message) -> AnyPublisher<Void, Error>
    func deleteMessage(with docID: String) -> AnyPublisher<Void, Error>
}

protocol MessengerCache: MessengerBase {
    //Description:
    //  Messages should not be stored in memory. As you do not need them at all times
    //  This function is for fetching a conversation when a chat is entered
    func fetchConversation(between uid: String, uid2: String) -> AnyPublisher<[Message], Error>
    func fetchMostRecentMessageForEachConversation(for currentUID: String) -> AnyPublisher<[String: Message], Error>
    func fetchMostRecentMessageForConversation(with currentUID: String, and uid: String) -> AnyPublisher<Message?, Error>
}

protocol MessengerRemote: MessengerBase {
    //Description:
    //  We only need to observe the most recent message for each conversation.
    //  Reason for this is because if the message is read, it implies that all messages before hand were read
    //  So, if we want to display to the user if the most recent message has been read (ie a preview in the conversations view), we need to listen on each most recent message from each conversation
    func observeMessage(with docID: String) -> AnyPublisher<(Message, DocChangeType), Error>
    
    //Expirimental:
    // Here we are combining observeMessagesToMe & observeMessagesFromMe into one publisher
    func observeMessages(for currentUID: String, newerThan date: Date) -> AnyPublisher<[(Message, DocChangeType)], Error>
    
    //Description:
    //  We want to observe all messages that are sent to the current user, once we get that new message, we clear the previous observer (see observeMessage) and add a new observer on this message.
    func observeMessagesToMe(forCurrent uid: String, newerThan date: Date) -> AnyPublisher<[(Message, DocChangeType)], Error>
    
    //Description:
    //  We want to observe all messages that the current user sends. Because the database is the single source of truth, we DO NOT add the message to the cache immediately after it is sent. We wait for the observer to send us back what we just sent, then we can add to the cache.
    func observeMessagesFromMe(forCurrent uid: String, newerThan date: Date) -> AnyPublisher<[(Message, DocChangeType)], Error>
}

enum DocChangeType {
    case added
    case modified
    case removed
}
