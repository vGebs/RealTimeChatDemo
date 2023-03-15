//
//  FirestoreWrapper.swift
//  RealTimeChatTest
//
//  Created by Vaughn on 2023-03-11.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

class FirestoreWrapper {
    static let shared = FirestoreWrapper()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    func create<T: Encodable>(collection: String, data: T) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            do {
                let _ = try self?.db.collection(collection).addDocument(from: data)
                promise(.success(()))
            } catch let error {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func read<T: FirestoreProtocol>(collection: String, documentId: String) -> AnyPublisher<T, Error> {
        return Future<T, Error> { [weak self] promise in
            self?.db.collection(collection).document(documentId).getDocument { (snapshot, error) in
                if let error = error {
                    promise(.failure(error))
                } else {
                    do {
                        let object = try snapshot!.data(as: T.self)
                        promise(.success(object))
                    } catch let error {
                        promise(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // Read multiple documents
    func read<T: FirestoreProtocol>(query: Query) -> AnyPublisher<[T], Error> {
        return Future<[T], Error> { promise in
            query.getDocuments { (snapshot, error) in
                if let error = error {
                    promise(.failure(error))
                } else {
                    do {
                        let values = try snapshot?.documents.compactMap {
                            let data = try $0.data(as: T.self)
                            return data
                        }
                        promise(.success(values ?? []))
                    } catch let error {
                        promise(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }

    // Update a single document
    func update<T: Encodable>(collection: String, documentId: String, data: T) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            let encoder = Firestore.Encoder()
            self?.db.collection(collection).document(documentId).setData(try! encoder.encode(data), merge: true) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // Delete a single document
    func delete(collection: String, documentId: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            self?.db.collection(collection).document(documentId).delete { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func listenByDocument<T: FirestoreProtocol>(collection: String, documentId: String) -> AnyPublisher<(T, DocChangeType), Error> {
        let publisher = DocumentSnapshotPublisher<T>(db.collection(collection).document(documentId))
        return publisher.mapError { $0 }.eraseToAnyPublisher()
    }
    
    func listenByQuery<T: FirestoreProtocol>(query: Query) -> AnyPublisher<[(T, DocumentChangeType)], Error> {
        let publisher = QuerySnapshotPublisher<T>(query)
        return publisher.mapError { $0 }.eraseToAnyPublisher()
    }
}
