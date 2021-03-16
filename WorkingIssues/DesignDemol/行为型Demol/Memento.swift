//
//  Memento.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation

//MARK: - 备忘录
/*
 在不破坏封装性的前提下，捕获一个对象的内部状态，并在该对象之外保存这个状态。这样就可以将该对象恢复到原先保存的状态
 */

/// 备忘录
typealias Memento = [String: String]


//MARK: - 发起人（Originator）
protocol MementoConvertible {
    var memento: Memento { get }
    init?(memento: Memento)
}

struct GameState: MementoConvertible {
    
    private enum Keys {
        static let chapter = "com.1"
        static let weapon = "com.2"
    }
    
    var chapter: String
    var weapon: String
    
    init(chapter: String, weapon: String) {
        self.chapter = chapter
        self.weapon = weapon
    }
    
    init?(memento: Memento) {
        guard let mementoChapter = memento[Keys.chapter],
              let mementoWeapon = memento[Keys.weapon] else { return nil }
        chapter = mementoChapter
        weapon = mementoWeapon
        
    }
    
    var memento: Memento {
        return [Keys.chapter: chapter, Keys.weapon: weapon]
    }
}
