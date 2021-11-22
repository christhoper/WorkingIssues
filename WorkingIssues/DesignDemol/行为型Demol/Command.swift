//
//  Command.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation

//MARK: - 命令: Command
/*
 命令模式是一种设计模式，它尝试以对象来代表实际行动。命令对象可以把行动（action）及其参数封装起来，于是这些行动可以被：
 1、重复多次
 2、取消（如果该对象有实现的话）
 3、取消后又再重做
 
 */

protocol DoorCommand {
    
    /// 执行
    func execute() -> String
}

fileprivate class OpenCommand: DoorCommand {
    
    let doors: String
    
    init(doors: String) {
        self.doors = doors
    }
    
    func execute() -> String {
        return "Opend\(doors)"
    }
}

fileprivate class CloseCommand: DoorCommand {
    
    let doors: String
    
    init(doors: String) {
        self.doors = doors
    }
    
    func execute() -> String {
        return "Close\(doors)"
    }
}

//MARK: - 对象，用来执行命令
class DoorOperation {
    
    let openCommand: DoorCommand
    let closeCommand: DoorCommand
    
    init(doors: String) {
        self.openCommand = OpenCommand(doors: doors)
        self.closeCommand = CloseCommand(doors: doors)
    }
    
    func openDoor() -> String {
        return openCommand.execute()
    }
    
    func closeDoor() -> String {
        return closeCommand.execute()
    }
}
