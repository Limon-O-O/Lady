//
//  HighPassSkinSmoothingMaskBoostFilter.swift
//  Example
//
//  Created by Limon on 8/4/16.
//  Copyright © 2016 Lady. All rights reserved.
//

import CoreImage

class HighPassSkinSmoothingMaskBoostFilter: CIFilter {

    var inputImage: CIImage?

    override var outputImage: CIImage? {

        guard let unwrappedInputImage = inputImage else { return nil }

        return HighPassSkinSmoothingMaskBoostFilter.kernel.applyWithExtent(unwrappedInputImage.extent, arguments: [unwrappedInputImage])
    }

    private static let kernel: CIColorKernel = {

        let shaderPath = NSBundle(forClass: HighPassSkinSmoothingMaskBoostFilter.self).pathForResource("\(HighPassSkinSmoothingMaskBoostFilter.self)", ofType: "cikernel")

        guard let path = shaderPath, kernelString = try? String(contentsOfFile: path, encoding: NSUTF8StringEncoding), kernel = CIColorKernel(string: kernelString) else {

            fatalError("Unable to build HighPassSkinSmoothingMaskBoostFilter Kernel")
        }

        return kernel
    }()
}
