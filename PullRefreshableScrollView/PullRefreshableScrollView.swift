//
//  PullRefreshableScrollView.swift
//
//  Copyright (c) 2018 Perceval FARAMAZ.
//  Portions Copyright (c) 2011 Alex Zielenski
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Cocoa

@objc public protocol PullRefreshableScrollViewDelegate : NSObjectProtocol {
    //called when the view is pulled far enough to trigger the pull-to-refresh
    @objc func prScrollView(_ sender: PullRefreshableScrollView, triggeredOnEdge: PullRefreshableScrollView.ViewEdge)
    
    @objc optional var topAccessoryView : (NSView & AccessoryViewForPullRefreshable)? { get }
    @objc optional var leftAccessoryView : (NSView & AccessoryViewForPullRefreshable)? { get }
    @objc optional var rightAccessoryView : (NSView & AccessoryViewForPullRefreshable)? { get }
    @objc optional var bottomAccessoryView : (NSView & AccessoryViewForPullRefreshable)? { get }
    //those accessors are called every time an accessory view may appear ; we're not keeping any reference to these views – it's UP TO YOU.
}

@objc public protocol AccessoryViewForPullRefreshable {
    //the view must always be considered displayed, as long as the scroll view is displayed
    //therefore don't use -viewDidHide or -viewDidUnhide for pull-to-refresh related behaviors and mechanisms
    
    //called when the view retreats outside of the visible rect
    @objc optional func viewDidRecede(_ sender: Any?)
    
    //this is fired when the accessory view starts to be pulled down and actually appears
    //releasing the view in the elasticity area just has it recede, is doesn't fire anything
    @objc optional func viewDidEnterElasticity(_ sender: Any?)
    
    //the validation area is the area where releasing the view causes the pull-to-refresh mechanism to trigger
    //there is no guarantee that entering the validation area will be followed by an actual trigger
    //because the user may voluntarily push back the view so that the pull-to-refresh is not triggered
    @objc optional func viewDidEnterValidationArea(_ sender: Any?)
    
    //this is called very often while pulling down – it may serve to give the user a feedback for how much further
    //they need to pull, in order to trigger the pull-to-refresh mechanism
    @objc optional func viewDidReachElasticityPercentage(_ sender: Any?, percentage: Double)
    
    //this is called when the view is released in the validation area, and thus when the pull-to-refresh mechanism is triggered
    //this method should only update the view, not perform the actual refresh job
    //As the delegate is also notified, it should be up to it to refresh the data
    @objc optional func viewDidStick(_ sender: Any?)
}

typealias AccessoryNSView = NSView & AccessoryViewForPullRefreshable

internal protocol EdgeScrollBehavior {
    var scrollBaseValue : CGFloat { get }
    var minimumScroll : CGFloat { get }
    var isOverThreshold : Bool { get }
    func resetScroll() //sends a scroll event to make the disappearance of the accessory view less brutal
}

internal class EdgeParameters {
    weak var scrollView : PullRefreshableScrollView?
    var edge : PullRefreshableScrollView.ViewEdge
    
    internal enum P2RState {
        case none
        case elastic
        case overpulled
        case stuck
    }
    
    init(_ view: PullRefreshableScrollView, edge myEdge: PullRefreshableScrollView.ViewEdge) {
        scrollView = view
        edge = myEdge
    }
    
    internal var accessoryView : AccessoryNSView? {
        get {
            return scrollView!.viewFor(edge: self.edge) ?? nil
        }
    }
    internal var enabled : Bool {
        get {
            return self.accessoryView != nil
        }
    }
    internal var viewState : P2RState = .none {
        didSet {
            scrollView!.notify(onEdge: self.edge, ofState: viewState, was: oldValue)
        }
    }
}

public class PullRefreshableScrollView: NSScrollView {
    
    @objc public enum ViewEdge : Int {
        case top
        case bottom
        //case left
        //case right
    }
    
    @IBOutlet weak var delegate: PullRefreshableScrollViewDelegate?
    
    internal func viewFor(edge: ViewEdge) -> AccessoryNSView? {
        switch edge {
        case .top:
            return self.delegate?.topAccessoryView ?? nil
        case .bottom:
            return self.delegate?.bottomAccessoryView ?? nil
        }
    }
    
    internal func notify(onEdge edge: ViewEdge, ifNeeded: Bool = true, ofState new: EdgeParameters.P2RState, was oldValue: EdgeParameters.P2RState) {
        if ifNeeded {
            guard new != oldValue else { return }
        }
        
        let view = viewFor(edge: edge)
        
        switch new {
        case .none:
            view?.viewDidRecede?(self)
        case .elastic:
            view?.viewDidEnterElasticity?(self)
        case .overpulled:
            view?.viewDidReachElasticityPercentage?(self, percentage: Double(100))
            view?.viewDidEnterValidationArea?(self)
        case .stuck:
            view?.viewDidStick?(self)
            delegate?.prScrollView(self, triggeredOnEdge: .top)
        }
    }
    
    internal typealias AnyEdgeParameters = EdgeParameters & EdgeScrollBehavior
    internal class TopEdgeParameters : EdgeParameters, EdgeScrollBehavior {
        var scrollBaseValue : CGFloat {
            get {
                return 0
            }
        }
        var minimumScroll : CGFloat {
            get {
                return self.scrollBaseValue - ((self.accessoryView?.frame.size.height) ?? 0)
            }
        }
        var isOverThreshold : Bool {
            get {
                let clipView : NSClipView = scrollView!.contentView
                let bounds = clipView.bounds
                
                let scrollValue = bounds.origin.y
                let minimumScroll = self.minimumScroll
                
                return (scrollValue <= minimumScroll)
            }
        }
        func resetScroll() {
            if self.viewState == .stuck {
                self.viewState = .none
                
                if (scrollView!.documentVisibleRect.origin.y < 0) {
                    scrollView!.sendScroll(wheel1: 1)
                }
            }
        }
    }
    internal class BottomEdgeParameters : EdgeParameters, EdgeScrollBehavior {
        var scrollBaseValue : CGFloat {
            get {
                return (scrollView!.documentView?.frame.height ?? 0)
            }
        }
        var minimumScroll : CGFloat {
            get {
                return ((self.accessoryView?.frame.size.height) ?? 0) + self.scrollBaseValue
            }
        }
        var isOverThreshold : Bool {
            get {
                let clipView : NSClipView = scrollView!.contentView
                let bounds = clipView.bounds
                
                let scrollValue = bounds.maxY
                let minimumScroll = self.minimumScroll
                
                return (scrollValue >= minimumScroll)
            }
        }
        func resetScroll() {
            if self.viewState == .stuck {
                self.viewState = .none
                
                if (scrollView!.documentVisibleRect.maxY > self.scrollBaseValue) {
                    scrollView!.sendScroll(wheel1: -1)
                }
            }
        }
    }
    
    internal lazy var top = TopEdgeParameters(self, edge: .top)
    internal lazy var bottom = BottomEdgeParameters(self, edge: .bottom)
    
    
    
    override public func viewDidMoveToWindow() {
        self.verticalScrollElasticity = .allowed
        
        _ = self.contentView; // create new content view
        
        self.contentView.postsFrameChangedNotifications = true
        self.contentView.postsBoundsChangedNotifications = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(viewBoundsChanged(_:)), name: NSView.boundsDidChangeNotification, object: self.contentView)
        
        placeAccessoryView(self.top.accessoryView, onEdge: .top)
        placeAccessoryView(self.bottom.accessoryView, onEdge: .bottom)
    }

    @objc internal func viewBoundsChanged(_ notification: NSNotification) {
        if top.viewState != .stuck, self.top.enabled {
            let top = self.top.isOverThreshold
            if (top) {
                self.top.viewState = .overpulled
            }
        }
        
        if bottom.viewState != .stuck, self.bottom.enabled {
            let bottom = self.bottom.isOverThreshold
            if (bottom) {
                self.bottom.viewState = .overpulled
            }
        }
    }
    
    private func placeAccessoryView(_ view: NSView?, onEdge edge: ViewEdge) {
        guard let view = view else { return }
        guard let documentView = self.documentView else { return }
        
        // add header view to clipview
        let contentRect = documentView.frame
        
        switch edge {
        case .top:
            view.frame = NSMakeRect(0, 0 - view.frame.height, contentRect.size.width, view.frame.height)
        case .bottom:
            view.frame = NSMakeRect(0, contentRect.height, contentRect.size.width, view.frame.height)
        }
        
        self.contentView.addSubview(view)
        
        // Scroll to top
        self.contentView.scroll(to: NSMakePoint(contentRect.origin.x, 0))
        self.reflectScrolledClipView(self.contentView)
    }
    
    override public func scrollWheel(with theEvent: NSEvent) {
        if theEvent.phase == .began {
            if top.viewState != .stuck && theEvent.scrollingDeltaY > 0 && verticalScroller!.doubleValue == 0 {
                top.viewState = .elastic
            }
            
            if bottom.viewState != .stuck && theEvent.scrollingDeltaY < 0 && verticalScroller!.doubleValue == 1 {
                bottom.viewState = .elastic
            }
        }
        
        super.scrollWheel(with: theEvent)
        
        let clipView = self.contentView
        let bounds = clipView.bounds
        
        if top.viewState == .elastic {
            let minimumScroll = abs(self.top.minimumScroll)
            let scrollValue = abs(bounds.origin.y).clamped(toMinimum: 0, maximum: minimumScroll)
            top.accessoryView?.viewDidReachElasticityPercentage?(self, percentage: Double(100*scrollValue/minimumScroll))
        }
        
        if bottom.viewState == .elastic {
            let minimumScroll = abs(self.bottom.minimumScroll) - bounds.size.height
            let scrollValue = abs(bounds.origin.y).clamped(toMinimum: 0, maximum: minimumScroll)
            let accessoryHeight = bottom.accessoryView?.frame.size.height ?? 0
            let percentage = Double(100*(accessoryHeight - (minimumScroll - scrollValue))/accessoryHeight)
            
            bottom.accessoryView?.viewDidReachElasticityPercentage?(self, percentage: percentage)
        }
        
        if (theEvent.phase == .ended) {
            if (self.top.enabled && self.top.isOverThreshold && top.viewState != .stuck)
            {
                self.top.viewState = .stuck
            }
            else if top.viewState != .stuck {
                top.viewState = .none
            }
            
            if (self.bottom.enabled && self.bottom.isOverThreshold && bottom.viewState != .stuck)
            {
                self.bottom.viewState = .stuck
            }
            else if bottom.viewState != .stuck {
                bottom.viewState = .none
            }
        }
        
        if theEvent.momentumPhase == .ended {
            if top.viewState != .stuck {
                top.viewState = .none
            }
            if bottom.viewState != .stuck {
                bottom.viewState = .none
            }
        }
    }
    
    override public var contentView: NSClipView {
        get {
            var superClipView = super.contentView
            if !(superClipView is PullRefreshableClipView) {
                
                // backup the document view
                let documentView = superClipView.documentView
                
                let clipView = PullRefreshableClipView.init(frame: superClipView.frame)
                self.contentView = clipView;
                clipView.documentView = documentView
                
                superClipView = super.contentView
            }
            return superClipView;
        }
        set {
            super.contentView = newValue
        }
    }
    
    private func sendScroll(wheel1: Int32 = 0, wheel2: Int32 = 0) {
        guard let cgEvent = CGEvent.init(scrollWheelEvent2Source: nil, units: CGScrollEventUnit.line, wheelCount: 2, wheel1: wheel1, wheel2: wheel2, wheel3: 0) else { return }
        
        guard let scrollEvent = NSEvent.init(cgEvent: cgEvent) else { return }
        self.scrollWheel(with: scrollEvent)
    }
    
    public func endAction(onEdge edge: ViewEdge) {
        if edge == .top {
            top.resetScroll()
        }
        if edge == .bottom {
            bottom.resetScroll()
        }
    }
    
    public func endActions() {
        top.resetScroll()
        bottom.resetScroll()
    }
}
