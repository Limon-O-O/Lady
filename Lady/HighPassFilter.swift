//
//  HighPassFilter.swift
//  Example
//
//  Created by Limon on 8/3/16.
//  Copyright © 2016 Lady. All rights reserved.
//

import CoreImage

class HighPassFilter: CIFilter {

    var inputImage: CIImage?

    /// A number value that controls the radius (in pixel) of the filter. The default value of this parameter is 1.0.
    var radius: CGFloat = 1.0

    private static let kernel: CIColorKernel = {

        let shaderPath = NSBundle(forClass: HighPassFilter.self).pathForResource("\(HighPassFilter.self)", ofType: "cikernel")

        guard let path = shaderPath, kernelString = try? String(contentsOfFile: path, encoding: NSUTF8StringEncoding), kernel = CIColorKernel(string: kernelString) else {

            fatalError("Unable to build HighPassFilter Kernel")
        }

        return kernel
    }()

    override var outputImage: CIImage? {

        guard let unwrappedInputImage = inputImage else { return nil }

        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else { return nil }

        blurFilter.setValue(unwrappedInputImage.imageByClampingToExtent(), forKey: kCIInputImageKey)
        blurFilter.setValue(radius, forKey: kCIInputRadiusKey)

        guard let outputImage = blurFilter.outputImage else { return nil }

        return HighPassFilter.kernel.applyWithExtent(unwrappedInputImage.extent, arguments: [unwrappedInputImage, outputImage])
    }

    override func setDefaults() {
        inputImage = nil
        radius = 1.0
    }

}
