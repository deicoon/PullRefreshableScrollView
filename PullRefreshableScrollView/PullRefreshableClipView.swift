//
//  PullRefreshableClipView.swift
//
//  Created by Perceval FARAMAZ on 25/03/2018.
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

public class PullRefreshableClipView: NSClipView {
    
    override public var isFlipped: Bool {
        get {
            return true
        }
    }
    
    override public var documentRect: NSRect {
        //this expands the scrollable area to include the accessory views, making scrollers match the full scrollable range – scrolling works as usual and feels less clunky
        var docRect = super.documentRect
        if (top.viewState == .stuck) {
            docRect.size.height += (top.accessoryView?.frame.size.height ?? 0)
            docRect.origin.y    -= (top.accessoryView?.frame.size.height ?? 0)
        }
        if (bottom.viewState == .stuck) {
            docRect.size.height += (bottom.accessoryView?.frame.size.height ?? 0)
        }
        return docRect
    }
    
    override public func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {// this method determines the "elastic" of the scroll view or how high it can scroll without resistence.
        let proposedNewOrigin = proposedBounds.origin
        var constrained = super.constrainBoundsRect(proposedBounds)
        let scrollValue = proposedNewOrigin.y // this is the y value where the top of the document view is
        let isTopOver = scrollValue <= top.minimumScroll
        let isBottomOver = scrollValue >= top.minimumScroll
        
        if (top.viewState == .stuck && scrollValue <= 0) { // if the accessory view is open
            constrained.origin.y = proposedNewOrigin.y
            if isTopOver { // and if we are scrolled above the refresh view
                //this check ensures that there is no weird effect while scrolling if the accessory view is open
                constrained.origin.y = top.minimumScroll // constrain us to the refresh view
            }
        }
        
        if (bottom.viewState == .stuck && scrollValue >= 0) { // if the accessory view is open
            constrained.size.height = proposedBounds.height
            if isBottomOver { // and if we are scrolled above the refresh view
                //but nothing to do, the documentRect change is enough
            }
        }
        
        return constrained
    }
    
    override public var enclosingScrollView: PullRefreshableScrollView? {
        get {
            return (super.enclosingScrollView as? PullRefreshableScrollView) ?? nil
        }
    }
    
    var top: PullRefreshableScrollView.TopEdgeParameters {
        get {
            return enclosingScrollView!.top
        }
    }
    
    var bottom: PullRefreshableScrollView.BottomEdgeParameters {
        get {
            return enclosingScrollView!.bottom
        }
    }
    
}

internal extension Comparable {
    func clamped(toMinimum minimum: Self, maximum: Self) -> Self {
        assert(maximum >= minimum, "Maximum clamp value can't be higher than the minimum")
        if self < minimum {
            return minimum
        } else if self > maximum {
            return maximum
        } else {
            return self
        }
    }
}
