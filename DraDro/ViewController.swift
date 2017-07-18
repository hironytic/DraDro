//
//  ViewController.swift
//  DraDro
//
//  Created by ichi on 2017/07/11.
//  Copyright © 2017 Hironytic. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var draggableView: UIView!
    @IBOutlet weak var droppableView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        draggableView.addInteraction(UIDragInteraction(delegate: self))
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension ViewController: UIDragInteractionDelegate {
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        let point = session.location(in: draggableView)
        if let hitView = draggableView.hitTest(point, with: nil) {
            if let labelView = hitView as? UILabel {
                let text = (labelView.text ?? "") as NSString
                return [UIDragItem(itemProvider: NSItemProvider(object: text))]
            }
        }
        return []
    }
}
