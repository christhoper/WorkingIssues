//
//  Factory Method.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation

//MARK: - 工厂方法: Factory Method


/*
 定义一个创建对象的接口，但是让实现这个接口的类来决定实例化哪个类，工厂方法让类的实例化推迟到子类中进行
 */


//MARK: - 定义创建对象协议
protocol CurrencyDescring {
    
    var symbol: String { get }
    var code: String { get }
}

final class China: CurrencyDescring {
    
    var symbol: String {
        return "¥"
    }
    
    var code: String {
        return "China"
    }
}


final class Japan: CurrencyDescring {
    
    var symbol: String {
        return "日元"
    }
    
    var code: String {
        return "Japan"
    }
}


enum Country {
    case china
    case japan
    case unowned
}

enum CurrencyFactory {

    static func currency(for country: Country) -> CurrencyDescring? {
        switch country {
        case .china:
            return China()
        case .japan:
            return Japan()
        case .unowned:
            return nil
        }
    }
}
