//
//  Flyweight.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation

//MARK: - 享元: Flyweight

/*
 使用共享物件，用来尽可能减少内存使用量以及分享资讯给尽可能多的相似物件。适合用于当大量物件只是重复因而导致无法令人接受的使用大量内存
 */

struct SpecialityCoffee {
    
    let origin: String
}

protocol CoffeeSearching {
    
    func search(origin: String) -> SpecialityCoffee?
}

final class Menu: CoffeeSearching {
    
    private var coffeeAvailabel: [String: SpecialityCoffee] = [:]
    
    func search(origin: String) -> SpecialityCoffee? {
        if coffeeAvailabel.index(forKey: origin) == nil {
            coffeeAvailabel[origin] = SpecialityCoffee(origin: origin)
        }
        return coffeeAvailabel[origin]
    }
}

final class CoffeeShop {
    
    private var orders: [Int: SpecialityCoffee] = [:]
    private var menu: CoffeeSearching
    
    init(menu: CoffeeSearching) {
        self.menu = menu
    }
    
    func takeOrder(origin: String, table: Int) {
        orders[table] = menu.search(origin: origin)
    }
    
    func serve() {
        for (table, origin) in orders {
            print("Sevring \(origin) to table \(table)")
        }
    }
}
