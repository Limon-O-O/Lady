//
//  MetalRenderContextViewController.swift
//  Lady
//
//  Created by Limon on 8/3/16.
//  Copyright © 2016 Lady. All rights reserved.
//

import UIKit
import Lady

#if !(arch(i386) || arch(x86_64)) && (os(iOS) || os(watchOS) || os(tvOS))
import MetalKit

@available(iOS 9.0, *)
class MetalRenderContextViewController: UIViewController, MTKViewDelegate {

    @IBOutlet private weak var metalView: MTKView!
    
    private var context: CIContext!
    private var commandQueue: MTLCommandQueue!
    private var inputTexture: MTLTexture!

    private let filter = HighPassSkinSmoothingFilter()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let device = MTLCreateSystemDefaultDevice() else { return }
        metalView.device = device
        metalView.delegate = self
        metalView.framebufferOnly = false
        metalView.enableSetNeedsDisplay = true
 
        context = CIContext(mtlDevice: device, options: [kCIContextWorkingColorSpace:CGColorSpaceCreateDeviceRGB()])
        commandQueue = device.makeCommandQueue()

        inputTexture = try! MTKTextureLoader(device: self.metalView.device!).newTexture(with: UIImage(named: "SampleImage")!.cgImage!, options: nil)
    }

    func draw(in view: MTKView) {

        let commandBuffer = commandQueue.makeCommandBuffer()

        let inputCIImage = CIImage(mtlTexture: inputTexture, options: nil)

        filter.inputImage = inputCIImage
        filter.inputAmount = 0.7
        filter.inputRadius = Float(7.0 * (inputCIImage?.extent.width)!/750.0)

        let outputCIImage = filter.outputImage!
        
        let cs = CGColorSpaceCreateDeviceRGB()
        let outputTexture = view.currentDrawable?.texture

        context.render(outputCIImage, to: outputTexture!,
            commandBuffer: commandBuffer, bounds: outputCIImage.extent, colorSpace: cs)

        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        view.draw()
    }
}

#else

class MetalRenderContextViewController: UIViewController {
    @IBOutlet private weak var metalView: UIView!
}

#endif
