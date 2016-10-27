//
//  DrawView.swift
//  TouchTracker
//
//  Created by Marc O'Neill on 24/10/2016.
//  Copyright © 2016 marcondev. All rights reserved.
//

import UIKit

class DrawView: UIView {
    
    var currentLines = [NSValue:Line]()
    var finishedLines = [Line]()
    
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
    }
    
    func tap(gestureRecogniser: UIGestureRecognizer) {
        print("Tap recognised")
    }
    
    func doubleTap(gestureRecognizer: UIGestureRecognizer) {
        print("Recognised a double tap")
        
        currentLines.removeAll(keepCapacity: false)
        finishedLines.removeAll(keepCapacity:  false)
        setNeedsDisplay()
    }
    
    func strokeLine(line: Line) {
        let path = UIBezierPath()
        path.lineWidth = lineThickness
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
    }
    
    // MARK: UIResponders
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print(#function)
        
        for touch in touches {
            let location = touch.locationInView(self)
            let newLine = Line(begin: location, end: location)
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
    
    
    
    
    
    
    
}
