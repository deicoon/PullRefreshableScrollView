//
//  ViewController.swift
//  PullToRefreshExample
//
//  Created by Perceval FARAMAZ on 24/03/2018.
//  Copyright © 2018 deicoon. All rights reserved.
//

import Cocoa

import PullRefreshableScrollView

class AccessoryView : NSView, AccessoryViewForPullRefreshable {
    func viewDidEnterElasticity(_ sender: Any?) {
        print("elasticity entered")
    }
    
    func viewDidEnterValidationArea(_ sender: Any?) {
        print("validation entered")
    }
    
    func viewDidStick(_ sender: Any?) {
        print("sticked")
    }
    
    func viewDidRecede(_ sender: Any?) {
        print("receded")
    }
    
    func viewDidReachElasticityPercentage(_ sender: Any?, percentage: Double) {
        print("percentage : \(percentage)")
    }
}

class MyTopAccessoryView : AccessoryView {
    @IBOutlet var indicator : NSProgressIndicator!
    
    override func viewDidReachElasticityPercentage(_ sender: Any?, percentage: Double) {
        indicator.doubleValue = percentage
    }
    
    override func viewDidStick(_ sender: Any?) {
        super.viewDidStick(sender)
        indicator.isIndeterminate = true
        indicator.startAnimation(self)
    }
    
    override func viewDidRecede(_ sender: Any?) {
        super.viewDidRecede(sender)
        indicator.isIndeterminate = false
    }
    
    override func viewDidMoveToWindow() {
        self.isHidden = false
        indicator.isHidden = false
        indicator.isDisplayedWhenStopped = true
        indicator.isIndeterminate = false
        indicator.maxValue = 100
        indicator.minValue = 0
    }
}

class ViewController: NSViewController, PullRefreshableScrollViewDelegate {
    func prScrollView(_ sender: PullRefreshableScrollView, triggeredOnEdge: PullRefreshableScrollView.ViewEdge) -> Bool {
        print("Triggered")
        DispatchQueue.global().async {
            sleep(5)
            DispatchQueue.main.async {
                sender.endActions()
            }
        }
        return true
    }
    
    func prScrollView(_ sender: PullRefreshableScrollView, accessoryViewOnEdge: PullRefreshableScrollView.ViewEdge) -> (NSView & AccessoryViewForPullRefreshable)? {
        return accessoryView
    }
    
    var topAccessoryView: (NSView & AccessoryViewForPullRefreshable)? {
        get {
            return accessoryView
        }
    }
    var bottomAccessoryView: (NSView & AccessoryViewForPullRefreshable)? {
        get {
            return bottomView
        }
    }
    
    @IBOutlet var tableView : NSTableView!
    @IBOutlet var accessoryView : AccessoryView!
    @IBOutlet var bottomView : AccessoryView!
    
    var tableDatas = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        //PullRefreshableScrollView
        // Do any additional setup after loading the view.
        for _ in 0..<5 {
            tableDatas.append("testing testing 123")
        }
        
        tableView.reloadData()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

extension ViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return tableDatas.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: .tableCellId, owner: self) as! NSTableCellView
        
        cell.textField?.stringValue = tableDatas[row]
        
        return cell
    }
}

extension NSUserInterfaceItemIdentifier {
    static var tableCellId = NSUserInterfaceItemIdentifier("cellId")
}
