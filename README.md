foldlings
=========

Crafting a 3D paper pop-up can be a lot of fun for the whole family, but designing the cuts and folds is often a trial and error process.  Inspired by paper art in the Rauner collection at Dartmouth and our own difficulty in constructing popups, we created an iOS application that makes the process easy and fun (Heimann).   Foldlings is a tool that assists in the exploratory process of creating a pop-up by allowing a user to simply draw lines and be guided in creating a well-defined pop-ups.  Sketches start with a blank drawing with a single driving fold. From this base, users touch screen to define a popup using our four tools: erase, fold, cut, and tab.  Cut and fold define new edges of planes.  During simulation, we detect fold orientation, so the user does not have to specify fold direction.  Our system also detects holes (enclosed paths) within planes.  The tab tool generates a plane that make the current design a valid 90-degree popup.

key methods and classes
=========

Smoothing User Input 
-----------------------------------
func getSubdivisions(elements:NSArray, increments:CGFloat = kBezierIncrements) -> [CGPoint] in Bezier.swift

Plane Detection
-----------------------------------
func getPlanes() in Sketch.swift

Plane Parenting and Doubly-Connected Edge List
-----------------------------------
func createPlaneTree(plane: Plane, hill:Bool, recurseCount:Int) -> SCNNode? in GameViewController.swift

Generating Tabs
-----------------------------------
func buildTabs() -> Bool in Sketch.swift

3D Planes
-----------------------------------
func createPlaneTree(plane: Plane, hill:Bool, recurseCount:Int) -> SCNNode? in GameViewController.swift
