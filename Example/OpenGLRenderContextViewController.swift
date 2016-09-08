//
//  OpenGLRenderContextViewController.swift
//  Lady
//
//  Created by Limon on 8/3/16.
//  Copyright © 2016 Lady. All rights reserved.
//

import UIKit
import GLKit
import Lady
import AVFoundation.AVUtilities

class OpenGLRenderContextViewController: GLKViewController {

    private var context: CIContext!

    private var glkView: GLKView! { return self.view as! GLKView }

    private var startDate: NSDate = NSDate()

    private var filter = HighPassSkinSmoothingFilter()

    private var inputCIImage = CIImage(cgImage: UIImage(named: "SampleImage")!.cgImage!)

    override func viewDidLoad() {
        super.viewDidLoad()

        let eaglContext = EAGLContext(api: .openGLES2)

        context = {
            return CIContext(eaglContext: eaglContext!, options: [kCIContextWorkingColorSpace: CGColorSpaceCreateDeviceRGB()])
        }()

        glkView.context = eaglContext!
    }

    override func glkView(_ view: GLKView, drawIn rect: CGRect) {

        let amount = abs(sin(NSDate().timeIntervalSince(self.startDate as Date)) * 0.7)

        title = String(format: "Input Amount: %.3f", amount)

        filter.inputImage = inputCIImage
        filter.inputAmount = Float(amount)
        filter.inputRadius = Float(7.0 * inputCIImage.extent.width/750.0)
        filter.inputSharpnessFactor = 0

        let outputCIImage = filter.outputImage!
        
        context.draw(outputCIImage, in: AVMakeRect(aspectRatio: outputCIImage.extent.size, insideRect: self.view.bounds.applying(CGAffineTransform(scaleX: UIScreen.main.scale, y: UIScreen.main.scale))), from: outputCIImage.extent)
    }
}
