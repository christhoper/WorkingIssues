//
//  Visitor.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation

//MARK: - 访问者模式: Visitor

/*
 封装某些作用于某种数据结构中各元素的操作，它可以在不改变数据结构的前提下定义作用于这些元素的新的操作
 */

protocol PlanetVisitor {
    
    func visit(planet: MoonJedda)
    func visit(planet: PlanetAlderan)
    func visit(planet: PlanetCoruscant)
    func visit(planet: PlanetTatoonie)
}

protocol Planet {
    
    func accept(visitor: PlanetVisitor)
    
}

final class MoonJedda: Planet {
    
    func accept(visitor: PlanetVisitor) {
        visitor.visit(planet: self)
    }
}

final class PlanetAlderan: Planet {
    
    func accept(visitor: PlanetVisitor) {
        visitor.visit(planet: self)
    }
}


final class PlanetCoruscant: Planet {
    
    func accept(visitor: PlanetVisitor) {
        visitor.visit(planet: self)
    }
}


final class PlanetTatoonie: Planet {
    
    func accept(visitor: PlanetVisitor) {
        visitor.visit(planet: self)
    }
}


final class NameVisitor: PlanetVisitor {
        
    var name: String = ""
    func visit(planet: MoonJedda) {
        name = "MoonJedda"
    }
    
    func visit(planet: PlanetAlderan) {
        name = "PlanetAlderan"
    }
    
    func visit(planet: PlanetCoruscant) {
        name = "PlanetCoruscant"
    }
    
    func visit(planet: PlanetTatoonie) {
        name = "PlanetTatoonie"
    }
}
