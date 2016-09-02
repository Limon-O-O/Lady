//
//  HighPassSkinSmoothingMaskGenerator.swift
//  Example
//
//  Created by Limon on 8/5/16.
//  Copyright © 2016 Lady. All rights reserved.
//

import CoreImage

class HighPassSkinSmoothingMaskGenerator {

    var inputImage: CIImage?

    var inputRadius: CGFloat = 0.0

    var outputImage: CIImage? {

        guard let unwrappedInputImage = inputImage else { return nil }

        guard let exposureFilter = CIFilter(name: "CIExposureAdjust") else { return nil }

        exposureFilter.setValue(unwrappedInputImage, forKey: kCIInputImageKey)
        exposureFilter.setValue(-1.0, forKey: kCIInputEVKey)

        let channelOverlayFilter = GreenBlueChannelOverlayBlendFilter()
        channelOverlayFilter.inputImage = exposureFilter.outputImage

        let highPassFilter = HighPassFilter()
        highPassFilter.inputImage = channelOverlayFilter.outputImage
        highPassFilter.radius = inputRadius

        let hardLightFilter = HighPassSkinSmoothingMaskBoostFilter()
        hardLightFilter.inputImage = highPassFilter.outputImage

        return hardLightFilter.outputImage
    }
}

