//
//  ViewController.swift
//  DraDro
//
//  Created by ichi on 2017/07/11.
//  Copyright © 2017 Hironytic. All rights reserved.
//

import UIKit
import os.log

class LabelDragInteractor: NSObject, UIDragInteractionDelegate {
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        let text = ((interaction.view as? UILabel)?.text ?? "") as NSString
        return [UIDragItem(itemProvider: NSItemProvider(object: text))]
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var draggableView: UIView!
    @IBOutlet weak var droppableView: UIView!
    @IBOutlet weak var draggableLabel: UILabel!
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var forbiddenView: UIView!
    
    let labelDragInteractor = LabelDragInteractor()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        infoLabel.text = ""
        
        draggableView.addInteraction(UIDragInteraction(delegate: self))
        droppableView.addInteraction(UIDropInteraction(delegate: self))
        draggableLabel.addInteraction(UIDragInteraction(delegate: labelDragInteractor))
        
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
                let dragItem = UIDragItem(itemProvider: NSItemProvider(object: text))
                dragItem.localObject = labelView
                return [dragItem]
            }
        }
        return []
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, previewForLifting item: UIDragItem, session: UIDragSession) -> UITargetedDragPreview? {
        let point = session.location(in: draggableView)
        guard let labelView = item.localObject as? UILabel else { return nil }

        let previewView = UILabel()
        previewView.text = "🚚" + (labelView.text ?? "")
        previewView.font = UIFont.systemFont(ofSize: 42)
        previewView.sizeToFit()
        
        let target = UIDragPreviewTarget(container: draggableView, center: point)

        return UITargetedDragPreview(view: previewView,
                                     parameters: UIDragPreviewParameters(),
                                     target: target)
    }
    
}

extension ViewController: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        let point = session.location(in: droppableView)
        guard forbiddenView != droppableView.hitTest(point, with: nil) else { return UIDropProposal(operation: .forbidden) }
        
        if session.canLoadObjects(ofClass: NSString.self) {
            return UIDropProposal(operation: .copy)
        } else {
            return UIDropProposal(operation: .cancel)
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        for item in session.items {
            if item.itemProvider.canLoadObject(ofClass: NSString.self) {
                item.itemProvider.loadObject(ofClass: NSString.self) { (object, error) in
                    if let string = object as? NSString {
                        DispatchQueue.main.async {
                            self.infoLabel.text = String(format: "Dropped string - %@", string)
                        }
                    }
                }
            }
        }
    }
}
