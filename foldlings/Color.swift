//
//  Color.swift
//  foldlings
//
//  Created by nook on 6/27/15.
//  Copyright (c) 2015 Marissa Allen, Nook Harquail, Tim Tregubov.  All Rights Reserved. All rights reserved.
//

import Foundation

class Color:UIColor{
    


    class func bluePaperColor() -> UIColor{
        return UIColor(red: 101/255.0, green: 115/255.0, blue: 191/255.0, alpha: 1.0)
    }
    class func greenPaperColor() -> UIColor{
        return UIColor(red: 138/255.0, green: 191/255.0, blue: 136/255.0, alpha: 1.0)
    }
    class func purplePaperColor() -> UIColor{
        return UIColor(red: 171/255.0, green: 99/255.0, blue: 187/255.0, alpha: 1.0)
    }
    class func yellowPaperColor() -> UIColor{
        return UIColor(red: 217/255.0, green: 195/255.0, blue: 84/255.0, alpha: 1.0)
    }
    class func orangePaperColor() -> UIColor{
        return UIColor(red: 242/255.0, green: 132/255.0, blue: 92/255.0, alpha: 1.0)
    }
    class func redPaperColor() -> UIColor{
        return UIColor(red: 217/255.0, green: 81/255.0, blue: 106/255.0, alpha: 1.0)
    }
    
    // converts a uicolor to hsv
    class func toHSV(color:UIColor) -> (hue:CGFloat,sat:CGFloat,val:CGFloat,alpha:CGFloat){
        
        var hue:CGFloat = 0
        var sat:CGFloat = 0
        var val:CGFloat = 0
        var alpha:CGFloat = 0
        color.getHue(&hue, saturation: &sat, brightness: &val, alpha: &alpha)

        return (CGFloat(hue),CGFloat(sat),CGFloat(val),CGFloat(alpha))
    }
    
    class func getOrientationColor(horizontal:Bool) -> UIColor{
        
        var warmColors: [UIColor] = [Color.orangePaperColor(), Color.yellowPaperColor(), Color.redPaperColor()]
        var coolColors: [UIColor] = [Color.bluePaperColor(), Color.greenPaperColor(), Color.purplePaperColor()]
        
        var rIndex: Int = Int(arc4random_uniform(3))
        
        if horizontal{
            return Color.shaded(warmColors[rIndex])
            
        }
        return Color.shaded(coolColors[rIndex])
    }
    
    // adds/subtracts a random float between 0.1 and -0.1 from the color's value
    class func shaded(color:UIColor) -> UIColor{
        // turn color to hsv
        let colorasHSV = Color.toHSV(color)
        // random between 0.1 and -0.1
        let randomFloat = CGFloat(Float(arc4random()) / 0xFFFFFFFF) * (0.1 + 0.1) - 0.1
        // transform color value
        let newVal = colorasHSV.val + randomFloat
        return UIColor(hue: colorasHSV.hue, saturation: colorasHSV.sat, brightness: newVal, alpha: 1.0)
    }

}