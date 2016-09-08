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
        let eaglContext = EAGLContext(api: .openGLES2)
        let options = [kCIContextWorkingColorSpace: CGColorSpaceCreateDeviceRGB()]
        return CIContext(eaglContext: eaglContext!, options: options)
    }()

    private let filter = HighPassSkinSmoothingFilter()
    
    @IBOutlet private weak var imageView: UIImageView!

    @IBOutlet fileprivate weak var amountSlider: UISlider!

    fileprivate var sourceImage: UIImage! {
        didSet {
            self.inputCIImage = CIImage(cgImage: self.sourceImage.cgImage!)
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

    fileprivate func processImage(byInputAmount inputAmount: Float) {

        filter.inputImage = inputCIImage
        filter.inputAmount = inputAmount
        filter.inputRadius = Float(7.0 * inputCIImage.extent.width/750.0)

        let outputCIImage = filter.outputImage!

        let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent)
        let outputUIImage = UIImage(cgImage: outputCGImage!, scale: self.sourceImage.scale, orientation: sourceImage.imageOrientation)
        
        self.processedImage = outputUIImage
        self.imageView.image = outputUIImage
    }
    
    @IBAction private func handleImageViewLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            self.imageView.image = self.sourceImage
        } else if (sender.state == .ended || sender.state == .cancelled) {
            self.imageView.image = self.processedImage
        }
    }

    @IBAction private func chooseImageBarButtonItemTapped(sender: AnyObject) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.view.backgroundColor = UIColor.white
        imagePickerController.delegate = self
        self.present(imagePickerController, animated: true, completion: nil)
    }
}

extension DefaultRenderContextViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {

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

        dismiss(animated: true, completion: nil)
    }
}
