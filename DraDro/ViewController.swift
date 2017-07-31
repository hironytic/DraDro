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
    @IBOutlet weak var dropIcon: UIImageView!
    
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
        guard let hitView = draggableView.hitTest(point, with: nil) else { return [] }
        
        switch hitView {
        case let label as UILabel:
            let text = (label.text ?? "") as NSString
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: text))
            dragItem.localObject = label
            return [dragItem]
            
        case let imageView as UIImageView:
            let image = imageView.image!
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: image))
            dragItem.localObject = imageView
            return [dragItem]
            
        default:
            return []
        }
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, previewForLifting item: UIDragItem, session: UIDragSession) -> UITargetedDragPreview? {
        switch item.localObject {
        case let label as UILabel:
            let previewView = UILabel()
            previewView.text = /* "🚚" + */ (label.text ?? "")
            previewView.font = UIFont.systemFont(ofSize: 42)
            previewView.sizeToFit()
            
            let target = UIDragPreviewTarget(container: draggableView, center: label.center)
            
            return UITargetedDragPreview(view: previewView,
                                         parameters: UIDragPreviewParameters(),
                                         target: target)
        
        case let imageView as UIImageView:
            return UITargetedDragPreview(view: imageView)
            
        default:
            return nil
        }
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, previewForCancelling item: UIDragItem, withDefault defaultPreview: UITargetedDragPreview) -> UITargetedDragPreview? {
        guard let srcView = item.localObject as? UIView else { return defaultPreview }
        let target = UIDragPreviewTarget(container: srcView.superview!, center: srcView.center)
        return defaultPreview.retargetedPreview(with: target)
    }

    func dragInteraction(_ interaction: UIDragInteraction, willAnimateLiftWith animator: UIDragAnimating, session: UIDragSession) {
        for item in session.items {
            if let label = item.localObject as? UILabel {
                animator.addAnimations {
                    label.alpha = 0.5
                }
            }
        }
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, item: UIDragItem, willAnimateCancelWith animator: UIDragAnimating) {
        if let label = item.localObject as? UILabel {
            animator.addAnimations {
                label.alpha = 1
            }
        }
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, session: UIDragSession, didEndWith operation: UIDropOperation) {
        for item in session.items {
            if let label = item.localObject as? UILabel {
                label.alpha = 1
            }
        }
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, itemsForAddingTo session: UIDragSession, withTouchAt point: CGPoint) -> [UIDragItem] {
        guard let hitView = draggableView.hitTest(point, with: nil) else { return [] }

        // Don't add the item already being dragged
        guard !session.items.contains(where:{ ($0.localObject as? UIView) == hitView }) else {
            return []
        }
        
        switch hitView {
        case let label as UILabel:
            guard !session.items.contains(where: { !$0.itemProvider.canLoadObject(ofClass: NSString.self) }) else { return [] }
            let text = (label.text ?? "") as NSString
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: text))
            dragItem.localObject = label
            return [dragItem]
            
        case let imageView as UIImageView:
            guard !session.items.contains(where: { !$0.itemProvider.canLoadObject(ofClass: UIImage.self) }) else { return [] }
            let image = imageView.image!
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: image))
            dragItem.localObject = imageView
            return [dragItem]
            
        default:
            return []
        }
    }
}

extension ViewController: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSString.self)
    }
    
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
    
    func dropInteraction(_ interaction: UIDropInteraction, previewForDropping item: UIDragItem, withDefault defaultPreview: UITargetedDragPreview) -> UITargetedDragPreview? {
        let target = UIDragPreviewTarget(container: droppableView,
                                         center: dropIcon.center,
                                         transform: CGAffineTransform(scaleX: 0.2, y: 0.2))
        return defaultPreview.retargetedPreview(with: target)
    }
}
