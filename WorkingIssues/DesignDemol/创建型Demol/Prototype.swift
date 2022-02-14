//
//  Prototype.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation

//MARK: - 原型: Prototype

/*
 通过”复制“一个已经存在的实例来返回新的实例，而不是新建实例，被复制的实例就是我们所称的”原型“，这个原型是可以定制的
 
 */


class MoonWorker {
    
    let name: String
    var health: Int = 100
    
    init(name: String) {
        self.name = name
    }
    
    func clone() -> MoonWorker {
        return MoonWorker(name: name)
    }
}
