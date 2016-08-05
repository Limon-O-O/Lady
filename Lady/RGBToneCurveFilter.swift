//
//  RGBToneCurveFilter.swift
//  Example
//
//  Created by Limon on 8/3/16.
//  Copyright © 2016 Lady. All rights reserved.
//

import CoreImage

public class RGBToneCurveFilter: CIFilter {

    public var inputImage: CIImage?

    public var inputIntensity: CGFloat = 1.0

    var inputRedControlPoints = defaultCurveControlPoints {
        didSet {
            redCurve = []
            toneCurveTexture = nil
        }
    }

    var inputGreenControlPoints = defaultCurveControlPoints {
        didSet {
            greenCurve = []
            toneCurveTexture = nil
        }
    }

    var inputBlueControlPoints = defaultCurveControlPoints {
        didSet {
            blueCurve = []
            toneCurveTexture = nil
        }
    }

    var inputRGBCompositeControlPoints = defaultCurveControlPoints {
        didSet {
            rgbCompositeCurve = []
            toneCurveTexture = nil
        }
    }

    private var toneCurveTexture: CIImage?

    private var redCurve = [CGFloat](), greenCurve = [CGFloat](), blueCurve = [CGFloat](), rgbCompositeCurve = [CGFloat]()

    private static let kernel: CIColorKernel = {

        let shaderPath = NSBundle.mainBundle().pathForResource("\(self)", ofType: "cikernel")

        guard let path = shaderPath, kernelString = try? String(contentsOfFile: path), kernel = CIColorKernel(string: kernelString) else {

            fatalError("Unable to build RGBToneCurve Kernel")
        }

        return kernel
    }()

    private static let splineCurveCache: NSCache = {
        let cache = NSCache()
        cache.name = "RGBToneCurveSplineCurveCache"
        cache.totalCostLimit = 40
        return cache
    }()

    override public var outputImage: CIImage? {

        guard let unwrappedInputImage = inputImage else { return nil }

        if toneCurveTexture == nil {
            updateToneCurveTexture()
        }

        guard let unwrappedToneCurveTexture = toneCurveTexture else { return nil }

        let arguments = [
            unwrappedInputImage,
            unwrappedToneCurveTexture,
            self.inputIntensity
        ]

        return RGBToneCurveFilter.kernel.applyWithExtent(unwrappedInputImage.extent, roiCallback: { (index, destRect) -> CGRect in

            return index == 0 ? destRect : unwrappedToneCurveTexture.extent

        }, arguments: arguments)
    }

    private func updateToneCurveTexture() {

        if self.rgbCompositeCurve.count != 256 {
            self.rgbCompositeCurve = getPreparedSplineCurve(inputRGBCompositeControlPoints)
        }

        if self.redCurve.count != 256 {
            self.redCurve = getPreparedSplineCurve(inputRedControlPoints)
        }

        if self.greenCurve.count != 256 {
            self.greenCurve = getPreparedSplineCurve(inputGreenControlPoints)
        }

        if self.blueCurve.count != 256 {
            self.blueCurve = getPreparedSplineCurve(inputBlueControlPoints)
        }

        let length: Int = 256 * 4
        let toneCurveBytes = UnsafeMutablePointer<UInt8>.calloc(length, initialValue: UInt8(0))

        let _ = (0..<256).map { currentCurveIndex in

            // BGRA for upload to texture
            let b = fmin(fmax(CGFloat(currentCurveIndex) + blueCurve[currentCurveIndex], 0), 255)
            let g = fmin(fmax(CGFloat(currentCurveIndex) + greenCurve[currentCurveIndex], 0), 255)
            let r = fmin(fmax(CGFloat(currentCurveIndex) + redCurve[currentCurveIndex], 0), 255)

            toneCurveBytes[currentCurveIndex * 4] = UInt8(fmin(fmax(b + rgbCompositeCurve[Int(b)], 0), 255))

            toneCurveBytes[currentCurveIndex * 4 + 1] = UInt8(fmin(fmax(g + rgbCompositeCurve[Int(g)], 0), 255))

            toneCurveBytes[currentCurveIndex * 4 + 2] = UInt8(fmin(fmax(r + rgbCompositeCurve[Int(r)], 0), 255))

            toneCurveBytes[currentCurveIndex * 4 + 3] = 255
        }

        let data = NSData(bytesNoCopy: toneCurveBytes, length: length, freeWhenDone: true)
        toneCurveTexture = CIImage(bitmapData: data, bytesPerRow: length, size: CGSizeMake(256, 1), format: kCIFormatBGRA8, colorSpace: nil)
    }

    public override func setDefaults() {

        inputRedControlPoints = defaultCurveControlPoints
        inputGreenControlPoints = defaultCurveControlPoints
        inputBlueControlPoints = defaultCurveControlPoints
        inputRGBCompositeControlPoints = defaultCurveControlPoints

        inputIntensity = 1.0

        inputImage = nil

        toneCurveTexture = nil

        redCurve = []
        greenCurve = []
        blueCurve = []
        rgbCompositeCurve = []
    }

}

// MARK: - Curve calculation

extension RGBToneCurveFilter {

    private func getPreparedSplineCurve(points: [CIVector]) -> [CGFloat] {

        if let cachedCurve = RGBToneCurveFilter.splineCurveCache.objectForKey(points) as? [CGFloat] {
            return cachedCurve
        }

        if points.isEmpty {
            assert(false, "Empty")
            return []
        }

        // Sort the array.
        let sortedPoints = points.sort { return $0.X > $1.X }

        // Convert from (0, 1) to (0, 255).
        var convertedPoints = Array(count: sortedPoints.count, repeatedValue: CIVector())

        for index in 0..<sortedPoints.count {
            let point = sortedPoints[index]
            convertedPoints.append(CIVector(x: point.X * 255, y: point.Y * 255))
        }

        var splinePoints = splineCurve(convertedPoints)

        // If we have a first point like (0.3, 0) we'll be missing some points at the beginning
        // that should be 0.

        let firstSplinePoint = splinePoints.first!

        if firstSplinePoint.X > 0 {

            for index in (0..<Int(firstSplinePoint.X)).reverse() {
                splinePoints.insert(CIVector(x: CGFloat(index), y: 0.0), atIndex: 0)
            }
        }

        // Insert points similarly at the end, if necessary.
        let lastSplinePoint = splinePoints.last!

        if lastSplinePoint.X < 255 {
            for index in (Int(lastSplinePoint.X) + 1)...255 {
                splinePoints.append(CIVector(x: CGFloat(index), y: 255))
            }
        }

        // Prepare the spline points.
        var preparedSplinePoints = Array(count: splinePoints.count, repeatedValue: CGFloat())

        for index in 0..<preparedSplinePoints.count {

            let newPoint = splinePoints[index]
            let origPoint = CIVector(x: newPoint.X, y: newPoint.X)

            var distance = sqrt(pow((origPoint.X - newPoint.X), 2.0) + pow((origPoint.Y - newPoint.Y), 2.0))

            if origPoint.Y > newPoint.Y {
                distance = -distance
            }

            preparedSplinePoints.append(distance)
        }

        RGBToneCurveFilter.splineCurveCache.setObject(preparedSplinePoints, forKey: points, cost: 1)

        return preparedSplinePoints
    }

    private func splineCurve(points: [CIVector]) -> [CIVector] {

        let sd = secondDerivative(points)

        if sd.isEmpty {
            assert(false, "Empty")
            return []
        }

        // [points count] is equal to [sdA count]
        let n = sd.count

        var output = Array(count: n+1, repeatedValue: CIVector())

        for index in 0..<n-1 {

            let cur = points[index]
            let next = points[index+1]

            for x in Int(cur.X)..<Int(next.X) {

                let t = (CGFloat(x)-cur.X)/(next.X-cur.X)

                let a = 1-t
                let b = t
                let h = next.X-cur.X

                let part1 = a * cur.Y + b * next.Y
                let part2 = (h * h / 6)
                let part3 = ((a * a * a - a) * sd[index] + (b * b * b - b) * sd[index+1])

                var y = part1 + part2 * part3
                y = min(y, 255.0)
                y = max(y, 0.0)

                output.append(CIVector(x: CGFloat(x), y: y))
            }
        }

        // The above always misses the last point because the last point is the last next, so we approach but don't equal it.
        output.append(points.last!)
        return output
    }

    private func secondDerivative(points: [CIVector]) -> [CGFloat] {

        let n = points.count

        if n <= 1 {
            assert(false, "")
            return []
        }

        var matrix = Array(count: n, repeatedValue: Array(count: 3, repeatedValue: CGFloat()))

        var result = Array(count: n, repeatedValue: CGFloat())

        matrix[0][1] = 1

        // What about matrix[0][1] and matrix[0][0]? Assuming 0 for now (Brad L.)
        matrix[0][0] = 0
        matrix[0][2] = 0

        for index in 1..<n-1 {

            let P1 = points[index-1]
            let P2 = points[index]
            let P3 = points[index+1]

            matrix[index][0] = (P2.X-P1.X)/6
            matrix[index][1] = (P3.X-P1.X)/3
            matrix[index][2] = (P3.X-P2.X)/6
            result[index] = (P3.Y-P2.Y)/(P3.X-P2.X) - (P2.Y-P1.Y)/(P2.X-P1.X)
        }

        // What about result[0] and result[n-1]? Assuming 0 for now (Brad L.)
        result[0] = 0
        result[n-1] = 0

        matrix[n-1][1] = 1
        // What about matrix[n-1][0] and matrix[n-1][2]? For now, assuming they are 0 (Brad L.)
        matrix[n-1][0] = 0
        matrix[n-1][2] = 0

        // solving pass1 (up->down)
        for index in 1..<n {
            let k = matrix[index][0]/matrix[index-1][1]
            matrix[index][1] -= k*matrix[index-1][2]
            matrix[index][0] = 0
            result[index] -= k*result[index-1]
        }

        // solving pass2 (down->up)
        
        for index in (0..<n-2).reverse() {
            
            let k = matrix[index][2]/matrix[index+1][1]
            matrix[index][1] -= k*matrix[index+1][0]
            matrix[index][2] = 0
            result[index] -= k*result[index+1]
        }
        
        var output = Array(count: n, repeatedValue: CGFloat())
        
        for index in 0..<n {
            output[index] = result[index]/matrix[index][1]
        }
        
        return output
    }

}


private extension UnsafeMutablePointer {

    static func calloc<T>(count: Int, initialValue: T) -> UnsafeMutablePointer<T> {
        let ptr = UnsafeMutablePointer<T>.alloc(count)
        ptr.initializeFrom(Repeat(count: count, repeatedValue: initialValue))
        return ptr
    }
}

