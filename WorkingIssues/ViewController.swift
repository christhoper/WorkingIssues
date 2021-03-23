//
//  ViewController.swift
//  WorkingIssues
//
//  Created by bailun on 2021/2/24.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        chainOfResponsibilityTest()
        commandtest()
        interpreterTest()
        iteratorTest()
        mediatorTest()
        mementoTest()
    }

    func chainOfResponsibilityTest() {
        let cls = MoneyTest()
        cls.testMoney()
    }
    
    func commandtest() {
        let play = "DoorOPeration"
        let doorAction = DoorOperation(doors: play)
        let command1 = doorAction.openDoor()
        let command2 = doorAction.closeDoor()
        print(command1, command2)
    }
    
    func interpreterTest() {
        let inter = IntereterTest()
        inter.test()
    }
    
    func iteratorTest() {
        let iterator = IteratorTest()
        iterator.test()
    }

    func mediatorTest() {
        let mediator = MediatorTest()
        mediator.test()
    }
    
    func mementoTest() {
        let memnto = MementoTest()
        memnto.test()
    }
    
}

