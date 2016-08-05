//
//  DefaultContextViewController.swift
//  Lady
//
//  Created by Limon on 8/3/16.
//  Copyright © 2016 Lady. All rights reserved.
//

import UIKit
import Lady

class DefaultRenderContextViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    let context = CIContext(options: [kCIContextWorkingColorSpace: CGColorSpaceCreateDeviceRGB()!])
    let filter = HighPassSkinSmoothingFilter()
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var amountSlider: UISlider!

    var sourceImage: UIImage! {
        didSet {
            self.inputCIImage = CIImage(CGImage: self.sourceImage.CGImage!)
        }
    }

    var processedImage: UIImage?
    
    var inputCIImage: CIImage!
    
    @IBAction func chooseImageBarButtonItemTapped(sender: AnyObject) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.view.backgroundColor = UIColor.whiteColor()
        imagePickerController.delegate = self
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.sourceImage = image
        self.processImage(byInputAmount: self.amountSlider.value)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sourceImage = UIImage(named: "SampleImage")!
        self.processImage(byInputAmount: self.amountSlider.value)
    }

    @IBAction func amountSliderTouchUp(sender: UISlider) {
        self.processImage(byInputAmount: sender.value)
    }

    func processImage(byInputAmount inputAmount: Float) {

        self.filter.inputImage = inputCIImage
        self.filter.inputAmount = CGFloat(inputAmount)
        self.filter.inputRadius = 7.0 * inputCIImage.extent.width/750.0

        let outputCIImage = filter.outputImage!

        let outputCGImage = context.createCGImage(outputCIImage, fromRect: outputCIImage.extent)
        let outputUIImage = UIImage(CGImage: outputCGImage, scale: self.sourceImage.scale, orientation: sourceImage.imageOrientation)
        
        self.processedImage = outputUIImage
        self.imageView.image = outputUIImage
    }
    
    @IBAction func handleImageViewLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .Began {
            self.imageView.image = self.sourceImage
        } else if (sender.state == .Ended || sender.state == .Cancelled) {
            self.imageView.image = self.processedImage
        }
    }
}
