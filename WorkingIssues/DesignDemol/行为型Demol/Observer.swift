//
//  Observer.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation

//MARK: - 观察者: Observer
/*
 一个目标对象管理所有相依于它的观察者对象，并且在它本身的状态改变时主动发出通知
 */


/// 属性观察
protocol PropertyObserver: AnyObject {
    
    func willChange(propertyName: String, newPropertyValue: Any?)
    func didChange(propertyName: String, oldPropertyValue: Any?)
}


final class TestChambers {
    
    weak var observer: PropertyObserver?
    private let testChambersName: String = "testChambersName"
    
    var testChambersNumber: Int = 0 {
        willSet(newValue) {
            observer?.willChange(propertyName: testChambersName, newPropertyValue: newValue)
        }
        
        didSet {
            observer?.didChange(propertyName: testChambersName, oldPropertyValue: oldValue)
        }
    }
    
}


final class Observer: PropertyObserver {
    
    func willChange(propertyName: String, newPropertyValue: Any?) {
        if newPropertyValue as? Int == 1 {
            print("willChange\(String(describing: newPropertyValue))")
        }
    }
    
    func didChange(propertyName: String, oldPropertyValue: Any?) {
        if oldPropertyValue as? Int == 0 {
            print("didChange\(String(describing: oldPropertyValue))")
        }
    }
}
