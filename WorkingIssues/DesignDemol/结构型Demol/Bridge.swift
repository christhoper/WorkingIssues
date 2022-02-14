//
//  Bridge.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation
import UIKit

//MARK: - 桥接: Bridge

/*
 桥接模式将抽象部分与实现部分分离，使它们都可以独立的变换
 
 */


protocol Switch {
    
    var appliance: Appliance { get set }
    func turnOn()
}

protocol Appliance {
    
    func run()
}


final class RemoteControl: Switch {
    
    var appliance: Appliance
    
    func turnOn() {
        self.appliance.run()
    }
    
    init(appliance: Appliance) {
        self.appliance = appliance
    }
}


final class TV: Appliance {
    
    func run() {
        print("TV turn on")
    }
}

final class Voidce: Appliance {
    
    func run() {
        print("Voidce turn on")
    }
}
