//
//  Virtual Proxy.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation

//MARK: - 虚拟代理模式: Virtual Proxy

/*
 在代理模式中，创建一个类代表另一个底层类的功能。虚拟代理用于对象的需时加载
 */

protocol HEVSuitMedicalAid {
    
    func administerMorphine() -> String
}

final class HEVSuit: HEVSuitMedicalAid {
    
    func administerMorphine() -> String {
        return "Morphine administered"
    }
}


final class HEVSuitHumanInterface: HEVSuitMedicalAid {
    
    lazy private var physicalSuit: HEVSuit = HEVSuit()
    
    func administerMorphine() -> String {
        return physicalSuit.administerMorphine()
    }
}
