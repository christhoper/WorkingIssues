//
//  Monostate.swift
//  WorkingIssues
//
//  Created by bailun on 2021/12/22.
//

import Foundation

//MARK: - 单态： Monostate

/*
 单态模式是实现单一共享的另一种方法。不同于单例模式，它通过完全不同的机制，在不限制构造方法的情况下实现单一共享特性。因此在这种情况下，单态会将状态保存为静态，而不是将整个实例保存为单例。
 */


class Setting {
    
    enum Theme {
        case `default`
        case old
        case new
    }
    
    private static var theme: Theme?
    
    var currentTheme: Theme {
        get { Setting.theme ?? .old }
        set(newValue) { Setting.theme = newValue }
    }
}
