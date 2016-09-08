//
//  GreenBlueChannelOverlayBlendFilter.swift
//  Example
//
//  Created by Limon on 8/4/16.
//  Copyright © 2016 Lady. All rights reserved.
//

import CoreImage

class GreenBlueChannelOverlayBlendFilter: CIFilter {

    var inputImage: CIImage?

    override var outputImage: CIImage? {

        guard let unwrappedInputImage = inputImage else { return nil }

        return GreenBlueChannelOverlayBlendFilter.kernel.apply(withExtent: unwrappedInputImage.extent, arguments: [unwrappedInputImage])
    }

    private static let kernel: CIColorKernel = {

        let shaderPath = Bundle(for: GreenBlueChannelOverlayBlendFilter.self).path(forResource: "\(GreenBlueChannelOverlayBlendFilter.self)", ofType: "cikernel")

        guard let path = shaderPath, let kernelString = try? String(contentsOfFile: path, encoding: String.Encoding.utf8), let kernel = CIColorKernel(string: kernelString) else {

            fatalError("Unable to build GreenBlueChannelOverlayBlendFilter Kernel")
        }

        return kernel
    }()
}
