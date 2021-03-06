//
//  DrawView.swift
//  TouchTracker
//
//  Created by Marc O'Neill on 24/10/2016.
//  Copyright © 2016 marcondev. All rights reserved.
//

import UIKit

class DrawView: UIView , UIGestureRecognizerDelegate{
    
    var currentLines = [NSValue:Line]()
    var finishedLines = [Line]()
    var moveRecogniser = UIPanGestureRecognizer()
    var longPressRecogniser = UILongPressGestureRecognizer()
    var magnitude: CGFloat = 0.0
    
    var selectedLineIndex: Int? {
        didSet {
            if selectedLineIndex == nil {
                let menu = UIMenuController.sharedMenuController()
                menu.setMenuVisible(false, animated: true)
            }
        }
    }
    
    @IBInspectable var finishedLineColour: UIColor = UIColor.blackColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var currentLineColour: UIColor = UIColor.redColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var lineThickness: CGFloat = 10 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let doubleTapRecogniser = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
        doubleTapRecogniser.numberOfTapsRequired = 2
        doubleTapRecogniser.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecogniser)
        
        let tapRecogniser = UITapGestureRecognizer(target: self, action: #selector(tap))
        tapRecogniser.delaysTouchesBegan = true
        tapRecogniser.requireGestureRecognizerToFail(doubleTapRecogniser)
        addGestureRecognizer(tapRecogniser)
        
        longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        addGestureRecognizer(longPressRecogniser)
        
        moveRecogniser = UIPanGestureRecognizer(target: self, action: #selector(moveLine))
        moveRecogniser.cancelsTouchesInView = false
        moveRecogniser.delegate = self
        addGestureRecognizer(moveRecogniser)
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func tap(gestureRecogniser: UIGestureRecognizer) {
        let point = gestureRecogniser.locationInView(self)
        selectedLineIndex = indexOfSelectedLine(point)
        
        let menu = UIMenuController.sharedMenuController()
        
        if selectedLineIndex != nil {
            //Make DrawView the target of menu item actions
            becomeFirstResponder()
            
            //Create a new delete UIMenuItem
            let deleteItem = UIMenuItem(title: "Delete", action: #selector(deleteLine))
            menu.menuItems = [deleteItem]
            
            //Tell the menu where it should come from and show it
            menu.setTargetRect(CGRect(x: point.x, y: point.y, width: 2, height: 2), inView: self)
            menu.setMenuVisible(true, animated: true)
        } else {
            //Hide the menu if no line is selected
            menu.setMenuVisible(false, animated: true)
        }
        
        setNeedsDisplay()
    }
    
    func deleteLine() {
        if let index = selectedLineIndex {
            finishedLines.removeAtIndex(index)
            selectedLineIndex = nil
            setNeedsDisplay()
        }
    }
    
    func doubleTap(gestureRecognizer: UIGestureRecognizer) {
        print("Recognised a double tap")
        selectedLineIndex = nil
        currentLines.removeAll(keepCapacity: false)
        finishedLines.removeAll(keepCapacity:  false)
        setNeedsDisplay()
    }
    
    func longPress(gestureRecogniser: UIGestureRecognizer) {
        print("Long Press")
        if gestureRecogniser.state == .Began {
            let point = gestureRecogniser.locationInView(self)
            selectedLineIndex = indexOfSelectedLine(point)
            
            if selectedLineIndex != nil {
                currentLines.removeAll()
                let menu = UIMenuController.sharedMenuController()
                menu.setMenuVisible(false, animated: true)
            }
        } else if gestureRecogniser.state == .Ended {
            selectedLineIndex = nil
        }
        
        setNeedsDisplay()
    }
    
    func moveLine(gestureRecogniser: UIPanGestureRecognizer) {
        print("Recognised a pan")
        
        if longPressRecogniser.state != .Changed {
            return
        }
        
        //A line must be selected
        if let index = selectedLineIndex {
            //When the pan recognizer changes its position
            if gestureRecogniser.state == .Changed {
                //How far has it moved
                let translation = gestureRecogniser.translationInView(self)
                
                //Add translation to current points
                finishedLines[index].begin.x += translation.x
                finishedLines[index].begin.y += translation.y
                finishedLines[index].end.x += translation.x
                finishedLines[index].end.y += translation.y
                
                //Reset translation
                gestureRecogniser.setTranslation(CGPoint.zero, inView: self)
                setNeedsDisplay()
            } else {
                //If no line selected do nothing
                return
            }
        }
    }
    
    func strokeLine(line: Line) {
        let path = UIBezierPath()
        path.lineWidth = line.width
        path.lineCapStyle = CGLineCap.Round
        
        path.moveToPoint(line.begin)
        path.addLineToPoint(line.end)
        path.stroke()
    }
    
    override func drawRect(rect: CGRect) {
        finishedLineColour.setStroke()
        for line in finishedLines {
            strokeLine(line)
        }
        
        currentLineColour.setStroke()
        for (_, line) in currentLines {
            strokeLine(line)
        }
        
        if let index = selectedLineIndex {
            UIColor.greenColor().setStroke()
            let selectedLine = finishedLines[index]
            strokeLine(selectedLine)
        }
    }
    
    // MARK: UIResponders
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print(#function)
        
        for touch in touches {
            let location = touch.locationInView(self)
            let newLine = Line(begin: location, end: location, width: 10.0)
            let key = NSValue(nonretainedObject: touch)
            currentLines[key] = newLine
        }
        
        setNeedsDisplay()
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print(#function)
        
        for touch in touches {
            let key = NSValue(nonretainedObject: touch)
            currentLines[key]?.end = touch.locationInView(self)
            
            var width = currentLines[key]?.width
            let velocity = moveRecogniser.velocityInView(self)
            magnitude = sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
            
            if magnitude > 100.0 && magnitude < 500.0 {
                width = 20.0
            } else if magnitude >= 500.0 {
                width = 30.0
            }
            
            currentLines[key]?.width = width!
        }
        
        setNeedsDisplay()
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print(#function)
        
        for touch in touches {
            let key = NSValue(nonretainedObject: touch)
            if var line = currentLines[key] {
                line.end = touch.locationInView(self)
                finishedLines.append(line)
                currentLines.removeValueForKey(key)
            }
        }
        
        setNeedsDisplay()
    }
    
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        print(#function)
        
        currentLines.removeAll()
        setNeedsDisplay()
    }
    
    func indexOfSelectedLine(point: CGPoint) -> Int? {
        //find a line close to a point
        for(index, line) in finishedLines.enumerate() {
            let begin = line.begin
            let end = line.end
            
            for t in CGFloat(0).stride(to: 1.0, by: 0.05) {
                let x = begin.x + ((end.x - begin.x) * t)
                let y = begin.y + ((end.y - begin.y) * t)
                
                //if the tapped point is within 20 points return this line
                if hypot(x - point.x, y - point.y) < 20.0 {
                    return index
                }
            }
        }
        //if nothing is close enough to the tapped point then we didn't select a line
        return nil
    }
    
    
    
    
    
}
