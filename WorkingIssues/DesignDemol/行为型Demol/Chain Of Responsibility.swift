//
//  Chain Of Responsibility.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation

//MARK: - 责任链: Chain Of Responsibility
/**
 责任链模式在面向对象程式设计里是一种软件设计模式，它包含了一些命令对象和一系列的处理对象。每一个处理对象决定它能处理哪些命令对象，它也知道如何将它不能处理的命令对象传递给下一个处理对象
 */

/// 纸币协议
fileprivate protocol Withdrawing {
    
    func withdraw(amout: Int) -> Bool
}

fileprivate class MoneyPile {
    // 面值
    let value: Int
    // 数量
    var quantity: Int
    var next: Withdrawing?
    
    init(value: Int, quantity: Int, next: Withdrawing?) {
        self.value = value
        self.quantity = quantity
        self.next = next
    }
    
    
}

extension MoneyPile: Withdrawing {
    
    func withdraw(amout: Int) -> Bool {
        var amout = amout
        var quantity = self.quantity
        while canTakeSomBill(want: amout) {
            if quantity == 0 {
                break
            }
            
            amout -= self.value
            quantity -= 1
        }
        
        guard amout > 0 else {
            return true
        }
        
        if let next = next {
            return next.withdraw(amout: amout)
        }
        
        return false
    }
    
    func canTakeSomBill(want: Int) -> Bool {
        return (want / self.value) > 0
    }
}


fileprivate class ATM: Withdrawing {
    
    private var hundred: Withdrawing
    private var fifty: Withdrawing
    private var twenty: Withdrawing
    private var ten: Withdrawing
    
    private var startPile: Withdrawing {
        return self.hundred
    }
    
    init(hundred: Withdrawing, fifty: Withdrawing, twenty: Withdrawing, ten: Withdrawing) {
        self.hundred = hundred
        self.fifty = fifty
        self.twenty = twenty
        self.ten = ten
    }
    
    func withdraw(amout: Int) -> Bool {
        return startPile.withdraw(amout: amout)
    }
}


class MoneyTest {
    
    init() {}
    
    func testMoney() {
        // 总共有相关面额的钱及数量 （总共：10*6 + 20*2 + 50*2 + 100*1 = 300）
        let ten = MoneyPile(value: 10, quantity: 6, next: nil)
        let twenty = MoneyPile(value: 20, quantity: 2, next: ten)
        let fifty = MoneyPile(value: 50, quantity: 2, next: twenty)
        let hundred = MoneyPile(value: 100, quantity: 1, next: fifty)
        
        let atm = ATM(hundred: hundred, fifty: fifty, twenty: twenty, ten: ten)
        let isCanPickout = atm.withdraw(amout: 310)
        let isCanPickout1 = atm.withdraw(amout: 100)
        
        print("是否可以取出这么多钱，310: \(isCanPickout), 100:\(isCanPickout1)")
    }
}
