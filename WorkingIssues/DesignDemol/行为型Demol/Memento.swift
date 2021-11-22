//
//  Memento.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation

//MARK: - 备忘录: Memento
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

//MARK: - 状态
struct GameState: MementoConvertible {
    
    private enum Keys {
        static let chapter = "com.chapter"
        static let weapon = "com.weapon"
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

//MARK: - 管理者（Caretaker）

enum CheckPoint {
    
    private static let defaults = UserDefaults.standard
    static func save(_ state: MementoConvertible, saveName: String) {
        defaults.setValue(state.memento, forKey: saveName)
        defaults.synchronize()
    }
    
    static func restore(saveName: String) -> Any? {
        return defaults.object(forKey: saveName)
    }
}

class MementoTest {
    
    init() {}
    
    func test() {
        var gameState = GameState(chapter: "章节", weapon: "武器")
        gameState.chapter = "第一章：序幕"
        gameState.weapon = "木棍"
        CheckPoint.save(gameState, saveName: "玩家1")
        
        gameState.chapter = "第二章：寻找"
        gameState.weapon = "木筏"
        CheckPoint.save(gameState, saveName: "玩家2")
        
        if let memento = CheckPoint.restore(saveName: "玩家1") as? Memento {
            let finalState = GameState(memento: memento)
            // dump函数：全局函数，打印出某个对象多有的信息
            dump(finalState)
        }
        
    }
}
