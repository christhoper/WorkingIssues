//
//  Mediator.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation

//MARK: - 中介者: Mediator
/*
 用一个中介者对象封装的对象交互，中介者使各对象不需要显示的相互作用，从而使耦合松散，而且可以独立的改变它们之间的交互
 */

/// 接受者
protocol Receiver {
    // 关联类型
    associatedtype MessageType
    func receive(message: MessageType)
}

protocol Sender {
    
    associatedtype MessageType
    associatedtype ReceiverType: Receiver
    
    var recipients: [ReceiverType] { get }
    func send(message: MessageType)
}

struct Programmer: Receiver {
    
    let name: String
    init(name: String) {
        self.name = name
    }
    
    func receive(message: String) {
        print("\(name)-receive-\(message)")
    }
}

//MARK: - 中介者对象
final class MessageMediator: Sender {
    
    var recipients: [Programmer] = []
    
    func add(recipient: Programmer) {
        recipients.append(recipient)
    }
    
    func send(message: String) {
        recipients.forEach { (programmer) in
            programmer.receive(message: message)
        }
    }
}


class MediatorTest {
    
    init() {}
    
    func test() {
        let messageMediator = MessageMediator()
        let programmer1 = Programmer(name: "Hendy")
        let programmer2 = Programmer(name: "Chris")
        messageMediator.add(recipient: programmer1)
        messageMediator.add(recipient: programmer2)
        spamMoster(message: "想做什么事情", worker: messageMediator)
    }
    
    private func spamMoster(message: String, worker: MessageMediator) {
        worker.send(message: message)
    }
}
