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

    private var inputCIImage = CIImage(CGImage: UIImage(named: "SampleImage")!.CGImage!)

    override func viewDidLoad() {
        super.viewDidLoad()

        let eaglContext = EAGLContext(API: .OpenGLES2)

        context = {
            let eaglContext = EAGLContext(API: .OpenGLES2)
            return CIContext(EAGLContext: eaglContext, options: [kCIContextWorkingColorSpace: CGColorSpaceCreateDeviceRGB()!])
        }()

        glkView.context = eaglContext
    }

    override func glkView(view: GLKView, drawInRect rect: CGRect) {

        let amount = abs(sin(NSDate().timeIntervalSinceDate(self.startDate)) * 0.7)

        title = String(format: "Input Amount: %.3f", amount)

        filter.inputImage = inputCIImage
        filter.inputAmount = CGFloat(amount)
        filter.inputRadius = 7.0 * inputCIImage.extent.width/750.0
        filter.inputSharpnessFactor = 0

        let outputCIImage = filter.outputImage!
        
        context.drawImage(outputCIImage, inRect: AVMakeRectWithAspectRatioInsideRect(outputCIImage.extent.size, CGRectApplyAffineTransform(self.view.bounds, CGAffineTransformMakeScale(UIScreen.mainScreen().scale, UIScreen.mainScreen().scale))), fromRect: outputCIImage.extent)
    }
}
