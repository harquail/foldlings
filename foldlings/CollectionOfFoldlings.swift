//
//

import UIKit

class CollectionOfFoldlings: UIViewController {
    
    
    @IBAction func oneButton(sender: UIButton) {
       makeSketch(0)
        
    }
    
    @IBAction func twoButton(sender: UIButton) {
        makeSketch(1)
    }
    
    @IBAction func threeButton(sender: UIButton) {
        makeSketch(2)
    }
    
    @IBAction func fourButton(sender: UIButton) {
        makeSketch(3)
    }
    
    @IBAction func fiveButton(sender: UIButton) {
      makeSketch(4)    }
    
    func makeSketch(num:Int){
        
        
        var vc = self.storyboard?.instantiateViewControllerWithIdentifier("sketchView") as SketchViewController
        self.presentViewController(vc, animated: true, completion: nil)

        
//        let viewC = SketchViewController()
//        viewC.sketchView = SketchView(frame: self.view.frame)
        println("reached makeSketch switch")
            
//        return viewC

        switch(num){
        case 0:
            break
        case 1:
            break
        case 2:
            break
        case 3:
            break
        case 4:
            break
        default:
            break
        }
        
//        return viewC
    }
    
    
}

