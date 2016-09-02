//
//  HighPassSkinSmoothingFilter.swift
//  Example
//
//  Created by Limon on 8/4/16.
//  Copyright © 2016 Lady. All rights reserved.
//

import CoreImage

public class HighPassSkinSmoothingFilter: CIFilter {

    /**
     The input image.
     */
    public var inputImage: CIImage?

    /**
     A number value that controls the intensity of the `Curve Adjustment` step and the sharpness of the final `Sharpen` step. You use this value to control the overall filter strength. Valid from 0 to 1.0. The default value is 0.75.
     */
    public var inputAmount: CGFloat = 0.75

    /**
     A number value that controls the radius (in pixel) of the `High Pass` filter. The default value of this parameter is 8.0. Try adjusting this value according to the resolution of the input image and the level of detail you want to preserve.
     */
    public var inputRadius: CGFloat = 8.0

    /**
     A array of `CIVector` that defines the control points of the curve in `Curve Adjustment` step. The default value of this parameter is [(0,0), (120/255.0,146/255.0), (1,1)].
     */
    public var inputToneCurveControlPoints = HighPassSkinSmoothingFilter.defaultInputToneCurveControlPoints {
        didSet {
            skinToneCurveFilter.inputRGBCompositeControlPoints = inputToneCurveControlPoints.isEmpty ? HighPassSkinSmoothingFilter.defaultInputToneCurveControlPoints : inputToneCurveControlPoints
        }
    }

    public static let defaultInputToneCurveControlPoints = [CIVector(x: 0.0, y: 0.0), CIVector(x: 120/255.0, y: 146/255.0), CIVector(x: 1.0, y: 1.0)]

    /**
     A number value that controls the sharpness factor of the final `Sharpen` step. The sharpness value is calculated as `inputAmount * inputSharpnessFactor`. The default value for this parameter is 0.6.
     */
    public var inputSharpnessFactor: CGFloat = 0.6

    override public var outputImage: CIImage? {

        guard let unwrappedInputImage = inputImage else { return nil }

        let maskGenerator = HighPassSkinSmoothingMaskGenerator()
        maskGenerator.inputRadius = inputRadius
        maskGenerator.inputImage = unwrappedInputImage

        skinToneCurveFilter.inputImage = unwrappedInputImage
        skinToneCurveFilter.inputIntensity = inputAmount

        guard let blendWithMaskFilter = CIFilter(name: "CIBlendWithMask") else { return nil }

        blendWithMaskFilter.setValue(unwrappedInputImage, forKey: kCIInputImageKey)

        if let skinToneCurveFilterOutImage = skinToneCurveFilter.outputImage {
            blendWithMaskFilter.setValue(skinToneCurveFilterOutImage, forKey: kCIInputBackgroundImageKey)
        }

        if let skinSmoothingOutImage = maskGenerator.outputImage {
            blendWithMaskFilter.setValue(skinSmoothingOutImage, forKey: kCIInputMaskImageKey)
        }

        let sharpnessValue = inputSharpnessFactor * inputAmount

        if sharpnessValue > 0 {

            let shapenFilter = CIFilter(name: "CISharpenLuminance")
            shapenFilter?.setValue(sharpnessValue, forKey: "inputSharpness")
            shapenFilter?.setValue(blendWithMaskFilter.outputImage, forKey: kCIInputImageKey)

            return shapenFilter?.outputImage

        } else {

            return blendWithMaskFilter.outputImage
        }
    }

    private lazy var skinToneCurveFilter: RGBToneCurveFilter = {
        let filter = RGBToneCurveFilter()
        filter.inputRGBCompositeControlPoints = HighPassSkinSmoothingFilter.defaultInputToneCurveControlPoints
        return filter
    }()

    public override func setDefaults() {
        inputImage = nil
        inputRadius = 8.0
        inputAmount = 0.75
        inputSharpnessFactor = 0.6
        inputToneCurveControlPoints = HighPassSkinSmoothingFilter.defaultInputToneCurveControlPoints
    }

}
