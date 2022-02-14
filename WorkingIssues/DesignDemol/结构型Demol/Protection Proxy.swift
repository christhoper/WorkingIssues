//
//  Protection Proxy.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation

//MARK: - 保护代理模式: Protection Proxy

/*
 在代理模式中，创建一个类代表另一个底层类的功能，保护代理用于限制访问
 
 */

protocol DoorOpening {
    
    func open(doors: String) -> String
}


final class HAL900: DoorOpening {
    
    func open(doors: String) -> String {
        return "正在打开中。open: \(doors)"
    }
}

final class CurrentComputer: DoorOpening {
    
    private var computer: HAL900!
    
    func authenticate(password: String) -> Bool {
        guard password == "pass" else {
            return false
        }
        
        computer = HAL900()
        return true
    }
    
    func open(doors: String) -> String {
        guard computer != nil else {
            return "Computer is null"
        }
        
        return computer.open(doors: doors)
    }
}
