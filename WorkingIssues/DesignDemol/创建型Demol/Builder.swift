//
//  Builder.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation

//MARK: - 生成器: Builder

/*
 一种对象构建模式。它可以将复杂对象的建造过程抽象出来（抽象类别），使用这个抽象过程的不同实现方法可以构造出不同表现（属性）的对象
 
 */


final class DeathStarBuilder {
    
    typealias BuilderClourse = (DeathStarBuilder) -> ()
    
    var x: Double?
    var y: Double?
    var z: Double?
    
    init(builderClourse: BuilderClourse) {
        builderClourse(self)
    }
}


struct DeathStar: CustomStringConvertible {
    
    let x: Double
    let y: Double
    let z: Double
    
    init?(builder: DeathStarBuilder) {
        if let x = builder.x, let y = builder.y, let z = builder.z {
            self.x = x
            self.y = y
            self.z = z
        } else {
            return nil
        }
    }
    
    var description: String {
        return "Death Star at (x:\(x) y:\(y) z:\(z)"
    }
    
}
