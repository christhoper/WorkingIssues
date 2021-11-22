//
//  State.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation

//MARK: - 状态模式： State

/**
 在状态模式中，对象的行为是基于它的内部状态而改变的，这个模式允许某个类对象在运行时发生改变
 */

protocol State {
    
    func isAuthorized(context: Context) -> Bool
    func userId(context: Context) -> String?
}

final class Context {
    private var state: State = UnauthorizedState()
    var isAuthorized: Bool {
        get { return state.isAuthorized(context: self) }
    }
    
    var userId: String? {
        get { return state.userId(context: self) }
    }
    
    func changeStateToAuthorized(userId: String) {
        state = AuthorizedState(userId: userId)
    }
    
    func changeStateToUnAuthorized() {
        state = UnauthorizedState()
    }
    
}

class UnauthorizedState: State {
    
    func isAuthorized(context: Context) -> Bool {
        return false
    }
    
    func userId(context: Context) -> String? {
        return nil
    }
}

class AuthorizedState: State {
    
    let userId: String
    func isAuthorized(context: Context) -> Bool {
        return true
    }
    
    func userId(context: Context) -> String? {
        return userId
    }
    
    required init(userId: String) {
        self.userId = userId
    }
}
