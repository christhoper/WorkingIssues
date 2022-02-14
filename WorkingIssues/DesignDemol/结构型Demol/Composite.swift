//
//  Composite.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation
import UIKit

//MARK: - 组合: Composite

/*
 将对象组合成树形结构以表示‘部分-整体’的层次结构。组合模式使得用户对单个对象和组合对象的使用具有一致性
 */

/// 组合协议
protocol Shape {
    
    func draw(fillColor: String)
}

/// 叶子节点
final class Square: Shape {
    
    func draw(fillColor: String) {
        print("用: \(fillColor)颜色画方形")
    }
}

final class Circle: Shape {
    
    func draw(fillColor: String) {
        print("用: \(fillColor)颜色画圆形")
    }
}


/// 组合使用
final class Drawboard: Shape {
    
    private lazy var shapes = [Shape]()
    
    init(_ shapes: Shape...) {
        self.shapes = shapes
    }
    
    func draw(fillColor: String) {
        for shape in shapes {
            shape.draw(fillColor: fillColor)
        }
    }
}
