//
//  Decorator.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation

//MARK: - 修饰: Decorator

/*
 修饰模式，是面向对象编程领域中，一种动态地往一个类中添加新的行为的设计模式。就功能而言，修饰模式相比生成子类更为灵活，这样可以给某个对象而不是整个类添加一些功能
 
 */


/// 价格协议
protocol CostHaving {
    
    var cost: Double { get }
}

/// 原料协议
protocol IngredientsHaving {
    
    var ingredients: [String] { get }
}

/// 制作饮料
typealias BeverageDataHaving = CostHaving & IngredientsHaving

struct SimpleCoffee: BeverageDataHaving {
    
    var cost: Double = 1.0
    var ingredients: [String] = ["Water", "Coffee"]
}


protocol BeverageHaving: BeverageDataHaving {
    
    var beverage: BeverageDataHaving { get }
}

struct Milk: BeverageHaving {
    
    var beverage: BeverageDataHaving
    var cost: Double {
        return beverage.cost + 1.5
    }
    
    var ingredients: [String] {
        return beverage.ingredients + ["Milk"]
    }
}


struct WhipCoffee: BeverageHaving {
    
    var beverage: BeverageDataHaving
    
    var cost: Double {
        beverage.cost + 2.5
    }
    
    var ingredients: [String] {
        return beverage.ingredients + ["Whip"]
    }
}
