//
//  FirebaseStorageWrapper.swift
//  RealTimeChatTest
//
//  Created by Vaughn on 2023-03-11.
//

import Foundation
import FirebaseStorage
import Combine

enum FirebaseStorageError: Error {
    case permissionError
    case unknownError
    case networkError
}

class FirebaseStorageWrapperCombine {
    private let storage = Storage.storage()
    private let maxFileSize: Int64

    init(maxFileSize: Int64) {
        self.maxFileSize = maxFileSize
    }

    func uploadData(fileName: String, fileData: Data, metaData: [String: String]? = nil) -> AnyPublisher<Void, Error> {
        let storageRef = storage.reference()
        let fileRef = storageRef.child(fileName)
        var uploadTask: StorageUploadTask!
        
        let meta = StorageMetadata()
        meta.customMetadata = metaData
        uploadTask = fileRef.putData(fileData, metadata: meta)
        
        return Future<Void, Error> { promise in
            uploadTask.observe(.success) { snapshot in
                promise(.success(()))
            }
            
            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error {
                    if (error as NSError).domain == "FIRStorageErrorDomain" {
                        switch (error as NSError).code {
                        case -13010:
                            promise(.failure(FirebaseStorageError.permissionError))
                        default:
                            promise(.failure(FirebaseStorageError.unknownError))
                        }
                    } else {
                        promise(.failure(FirebaseStorageError.networkError))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func downloadData(fileName: String) -> AnyPublisher<Data?, Error> {
        let storageRef = storage.reference()
        let fileRef = storageRef.child(fileName)
        
        return Future<Data?, Error> { [weak self] promise in
            fileRef.getData(maxSize: self!.maxFileSize) { data, error in
                if let error = error {
                    if (error as NSError).domain == "FIRStorageErrorDomain" {
                        switch (error as NSError).code {
                        case -13010:
                            promise(.failure(FirebaseStorageError.permissionError))
                        default:
                            promise(.failure(FirebaseStorageError.unknownError))
                        }
                    } else {
                        promise(.failure(FirebaseStorageError.networkError))
                    }
                } else {
                    promise(.success(data))
                }
            }
        }.eraseToAnyPublisher()
    }

    func getMetaData(fileName: String) -> AnyPublisher<StorageMetadata?, Error> {
        let storageRef = storage.reference()
        let fileRef = storageRef.child(fileName)
        
        return Future<StorageMetadata?, Error> { promise in
            fileRef.getMetadata { metadata, error in
                if let error = error {
                    if (error as NSError).domain == "FIRStorageErrorDomain" {
                        switch (error as NSError).code {
                        case -13010:
                            promise(.failure(FirebaseStorageError.permissionError))
                        default:
                            promise(.failure(FirebaseStorageError.unknownError))
                        }
                    } else {
                        promise(.failure(FirebaseStorageError.networkError))
                    }
                } else {
                    promise(.success(metadata))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func updateMetaData(fileName: String, metadata: [String: String]) -> AnyPublisher<Void, Error> {
        let storageRef = storage.reference()
        let fileRef = storageRef.child(fileName)
        let meta = StorageMetadata()
        meta.customMetadata = metadata
        
        return Future<Void, Error> { promise in
            fileRef.updateMetadata(meta) { metadata, error in
                if let error = error {
                    if (error as NSError).domain == "FIRStorageErrorDomain" {
                        switch (error as NSError).code {
                        case -13010:
                            promise(.failure(FirebaseStorageError.permissionError))
                        default:
                            promise(.failure(FirebaseStorageError.unknownError))
                        }
                    } else {
                        promise(.failure(FirebaseStorageError.networkError))
                    }
                } else {
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func deleteFile(fileName: String) -> AnyPublisher<Void, Error> {
        let storageRef = storage.reference()
        let fileRef = storageRef.child(fileName)
        return Future<Void, Error> { promise in
            fileRef.delete { error in
                if let error = error {
                    if (error as NSError).domain == "FIRStorageErrorDomain" {
                        switch (error as NSError).code {
                        case -13010:
                            promise(.failure(FirebaseStorageError.permissionError))
                        default:
                            promise(.failure(FirebaseStorageError.unknownError))
                        }
                    } else {
                        promise(.failure(FirebaseStorageError.networkError))
                    }
                } else {
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }
}
