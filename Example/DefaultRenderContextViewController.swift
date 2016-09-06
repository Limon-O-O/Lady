//
//  DefaultContextViewController.swift
//  Lady
//
//  Created by Limon on 8/3/16.
//  Copyright © 2016 Lady. All rights reserved.
//

import UIKit
import Lady
import MobileCoreServices.UTType

class DefaultRenderContextViewController: UIViewController {

    private let context: CIContext = {
        let eaglContext = EAGLContext(API: .OpenGLES2)
        let options = [kCIContextWorkingColorSpace: CGColorSpaceCreateDeviceRGB()!]
        return CIContext(EAGLContext: eaglContext, options: options)
    }()

    private let filter = HighPassSkinSmoothingFilter()
    
    @IBOutlet private weak var imageView: UIImageView!

    @IBOutlet private weak var amountSlider: UISlider!

    private var sourceImage: UIImage! {
        didSet {
            self.inputCIImage = CIImage(CGImage: self.sourceImage.CGImage!)
        }
    }

    private var processedImage: UIImage?
    
    private var inputCIImage: CIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sourceImage = UIImage(named: "SampleImage")!
        self.processImage(byInputAmount: self.amountSlider.value)
    }

    @IBAction private func amountSliderTouchUp(sender: UISlider) {
        self.processImage(byInputAmount: sender.value)
    }

    private func processImage(byInputAmount inputAmount: Float) {

        filter.inputImage = inputCIImage
        filter.inputAmount = inputAmount
        filter.inputRadius = Float(7.0 * inputCIImage.extent.width/750.0)

        let outputCIImage = filter.outputImage!

        let outputCGImage = context.createCGImage(outputCIImage, fromRect: outputCIImage.extent)
        let outputUIImage = UIImage(CGImage: outputCGImage, scale: self.sourceImage.scale, orientation: sourceImage.imageOrientation)
        
        self.processedImage = outputUIImage
        self.imageView.image = outputUIImage
    }
    
    @IBAction private func handleImageViewLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .Began {
            self.imageView.image = self.sourceImage
        } else if (sender.state == .Ended || sender.state == .Cancelled) {
            self.imageView.image = self.processedImage
        }
    }

    @IBAction private func chooseImageBarButtonItemTapped(sender: AnyObject) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.view.backgroundColor = UIColor.whiteColor()
        imagePickerController.delegate = self
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
}

extension DefaultRenderContextViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {

        if let mediaType = info[UIImagePickerControllerMediaType] as? String {

            switch mediaType {
            case String(kUTTypeImage):
                if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                    self.sourceImage = image
                    self.processImage(byInputAmount: self.amountSlider.value)
                }
            default:
                break
            }
        }

        dismissViewControllerAnimated(true, completion: nil)
    }
}
