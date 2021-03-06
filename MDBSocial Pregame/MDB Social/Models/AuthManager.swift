//
//  AuthManager.swift
//  MDB Social
//
//  Created by Michael Lin on 10/9/21.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthManager {
    
    static let shared = AuthManager()
    
    let auth = Auth.auth()
    
    enum SignInErrors: Error {
        case wrongPassword
        case userNotFound
        case invalidEmail
        case internalError
        case errorFetchingUserDoc
        case errorDecodingUserDoc
        case unspecified
    }
    
    let db = Firestore.firestore()
    
    var currentUser: User?
    
    private var userListener: ListenerRegistration?
    
    init() {
        guard let user = auth.currentUser else { return }
        
        linkUser(withuid: user.uid, completion: nil)
    }
    
    func signIn(withEmail email: String, password: String,
                completion: ((Result<User, SignInErrors>)->Void)?) {
        self.auth.signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                let nsError = error as NSError
                let errorCode = FirebaseAuth.AuthErrorCode(rawValue: nsError.code)
                switch errorCode {
                case .wrongPassword:
                    completion?(.failure(.wrongPassword))
                case .userNotFound:
                    completion?(.failure(.userNotFound))
                default:
                    completion?(.failure(.unspecified))
                    
                }
                return
            }
            
            guard let authResult = authResult else {
                completion?(.failure(.internalError))
                return
            }
            
            self.linkUser(withuid: authResult.user.uid, completion: completion)
            
        }
        /* TODO: Hackshop */
    }
    
    /* TODO: Firebase sign up handler, add user to firestore */
    
    func isSignedIn() -> Bool {
        return auth.currentUser != nil
    }
    
    func signOut(completion: (()->Void)? = nil) {
        do {
            try auth.signOut()
            unlinkCurrentUser()
            completion?()
        } catch { }
    }
    
    private func linkUser(withuid uid: String,
                          completion: ((Result<User, SignInErrors>)->Void)?) {
        /* TODO: Hackshop */
        
        //calling the database's collection
        userListener = db.collection("users").document(uid).addSnapshotListener { docSnapshot, error in
            guard let document = docSnapshot else {
                completion?(.failure(.errorFetchingUserDoc))
                return
            }

            guard let user = try? document.data(as: User.self) else {
                completion?(.failure(.errorDecodingUserDoc))
                return
            }
            
            completion!(.success(user))
        }
    }
    
    private func unlinkCurrentUser() {
        userListener?.remove()
        currentUser = nil
    }
}
