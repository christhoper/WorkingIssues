//
//  Abstract Factory.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation

//MARK: - 抽象工厂： Abstract Factory

/**
 抽象工厂模式提供了一种方式，可以将一组具有同一主题的单独的工厂封装起来。在正常使用中，客户端程序需要创建抽象工厂的具体实现，然后使用抽象工厂作为接口来创建这一主题的具体对象
 **/



protocol BurgerDescribing {
    var ingredients: [String] { get }
}


struct CheeseBurger: BurgerDescribing {
    let ingredients: [String]
}

protocol BurgerMaking {
    func make() -> BurgerDescribing
}


//MARK: - 工厂实现
final class BigProductBurger: BurgerMaking {
    
    func make() -> BurgerDescribing {
        return CheeseBurger(ingredients: ["Fazzaco", "Hui"])
    }
}

final class SubProductBurger: BurgerMaking {
    
    func make() -> BurgerDescribing {
        return CheeseBurger(ingredients: ["QQ", "Wechat"])
    }
}


//MARK: - 抽象工厂
enum BurgerFactoryType: BurgerMaking {
    case big
    case sub
    
    func make() -> BurgerDescribing {
        switch self {
        case .big:
            return BigProductBurger().make()
        case .sub:
            return SubProductBurger().make()
        }
    }
}


//MARK: - 可乐抽象
protocol Cola {
    
    func createCola() -> ColaFactory
}

struct ColaFactory: Cola {
    
    func createCola() -> ColaFactory {
        return self
    }
}


//MARK: - 瓶子抽象
protocol Bottle {
    
    func createBottle() -> BottleFactory
}

struct BottleFactory: Bottle {
    
    func createBottle() -> BottleFactory {
        return self
    }
}


//MARK: - 箱子抽象
protocol Box {
    
    func createBottle() -> BoxFactory
}

struct BoxFactory: Box {
    
    func createBottle() -> BoxFactory {
        return self
    }
}

//MARK: - 饮料抽象类
protocol DrinkMakerFatory {
    
    /// 创建工厂
    func colaMaker() -> ColaFactory
    func bottleMaker() -> BottleFactory
    func boxMaker() -> BoxFactory
}



final class PasiCola: DrinkMakerFatory {
    
    func colaMaker() -> ColaFactory {
        return ColaFactory().createCola()
    }
    
    func bottleMaker() -> BottleFactory {
        return BottleFactory().createBottle()
    }
    
    func boxMaker() -> BoxFactory {
        return BoxFactory().createBottle()
    }
}


final class CocoCola: DrinkMakerFatory {
    
    func colaMaker() -> ColaFactory {
        return ColaFactory().createCola()
    }
    
    func bottleMaker() -> BottleFactory {
        return BottleFactory().createBottle()
    }
    
    func boxMaker() -> BoxFactory {
        return BoxFactory().createBottle()
    }

}

