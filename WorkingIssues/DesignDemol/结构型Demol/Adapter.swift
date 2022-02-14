//
//  Adapter.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation
import UIKit

//MARK: - 适配器: Adapter

/*
 适配器模式有时候也称包装样式或者包装(wrapper)，将一个类的接口转接成用户所期待的。一个适配器使得因接口不兼容而不能在一起工作的类工作在一起，做法是将类自己的接口包裹在一个已存在的类中。
 */


protocol NewDeathStarSuperLasserAiming {
    
    var angleVer: Double { get }
    var angleHor: Double { get }
}

/// 被适配者
struct OldDeathStarSuperlaserTarget {
    
    let angleHorizontal: Float
    let angleVertical: Float
    
    init(horizontal: Float, vertical: Float) {
        self.angleHorizontal = horizontal
        self.angleVertical = vertical
    }
}


/// 适配器
struct NewDeathStarlaserTarget: NewDeathStarSuperLasserAiming {
    
    private let target: OldDeathStarSuperlaserTarget
    
    var angleHor: Double {
        return Double(target.angleHorizontal)
    }
    
    var angleVer: Double {
        return Double(target.angleVertical)
    }
 
    init(_ target: OldDeathStarSuperlaserTarget) {
        self.target = target
    }
}
