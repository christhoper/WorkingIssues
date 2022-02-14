//
//  Singleton.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation

//MARK: - 单例: Singleton

/*
 单例对象的类必须保证只有一个实例存在，许多时候整个系统只需拥有一个全局对象，这样有利于协调系统整体的行为
 */

final class User {
    
    static let shared = User()
    private init() {}
}
