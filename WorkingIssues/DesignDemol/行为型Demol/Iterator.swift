//
//  Iterator.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation

//MARK: - 迭代器: Iterator
/*
 迭代器模式可以让用户通过特定的接口巡防容器中的每一个元素而不用了解底层的实现
 */

struct Dev {
    let name: String
}

struct Master {
    let devs: [Dev]
}

struct MasterInterator: IteratorProtocol {
    
    private var current = 0
    private let devs: [Dev]
    
    init(devs: [Dev]) {
        self.devs = devs
    }
    
    mutating func next() -> Dev? {
        defer {
            current += 1
        }
        
        return devs.count > current ? devs[current] : nil
    }
}

extension Master: Sequence {

    func makeIterator() -> MasterInterator {
        return MasterInterator(devs: devs)
    }
}

class IteratorTest {
    init() {}
    
    func test() {
        let master = Master(devs: [Dev(name: "dev_hend"), Dev(name: "dev_jhd")])
        for dev in master {
            print("迭代器",dev.name)
        }
    }
}
