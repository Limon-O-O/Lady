//
//  RGBToneCurveFilter.swift
//  Example
//
//  Created by Limon on 8/3/16.
//  Copyright © 2016 Lady. All rights reserved.
//

import CoreImage

class RGBToneCurveFilter {

    var inputImage: CIImage?

    var inputIntensity: Float = 1.0

    var inputRedControlPoints = RGBToneCurveFilter.defaultCurveControlPoints {
        didSet {
            redCurve = []
            toneCurveTexture = nil
        }
    }

    var inputGreenControlPoints = RGBToneCurveFilter.defaultCurveControlPoints {
        didSet {
            greenCurve = []
            toneCurveTexture = nil
        }
    }

    var inputBlueControlPoints = RGBToneCurveFilter.defaultCurveControlPoints {
        didSet {
            blueCurve = []
            toneCurveTexture = nil
        }
    }

    var inputRGBCompositeControlPoints = RGBToneCurveFilter.defaultCurveControlPoints {
        didSet {
            rgbCompositeCurve = []
            toneCurveTexture = nil
        }
    }

    private static let defaultCurveControlPoints = [CIVector(x: 0.0, y: 0.0), CIVector(x: 0.5, y: 0.5), CIVector(x: 1.0, y: 1.0)]

    private var toneCurveTexture: CIImage?

    private var redCurve = [Float](), greenCurve = [Float](), blueCurve = [Float](), rgbCompositeCurve = [Float]()

    private static let kernel: CIKernel = {

        let shaderPath = Bundle(for: RGBToneCurveFilter.self).path(forResource: "\(RGBToneCurveFilter.self)", ofType: "cikernel")

        guard let path = shaderPath, let kernelString = try? String(contentsOfFile: path, encoding: String.Encoding.utf8), let kernel = CIKernel(string: kernelString) else {

            fatalError("Unable to build RGBToneCurve Kernel")
        }

        return kernel
    }()

    fileprivate static let splineCurveCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()
        cache.name = "RGBToneCurveSplineCurveCache"
        cache.totalCostLimit = 40
        return cache
    }()

    var outputImage: CIImage? {

        guard let unwrappedInputImage = inputImage else { return nil }

        if toneCurveTexture == nil {
            updateToneCurveTexture()
        }

        guard let unwrappedToneCurveTexture = toneCurveTexture else { return nil }

        let arguments = [
            unwrappedInputImage,
            unwrappedToneCurveTexture,
            inputIntensity
        ] as [Any]

        return RGBToneCurveFilter.kernel.apply(withExtent: unwrappedInputImage.extent, roiCallback: { (index, destRect) -> CGRect in

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
            let b = fmin(fmax(Float(currentCurveIndex) + blueCurve[currentCurveIndex], 0), 255)
            let g = fmin(fmax(Float(currentCurveIndex) + greenCurve[currentCurveIndex], 0), 255)
            let r = fmin(fmax(Float(currentCurveIndex) + redCurve[currentCurveIndex], 0), 255)

            toneCurveBytes[currentCurveIndex * 4] = UInt8(fmin(fmax(b + rgbCompositeCurve[Int(b)], 0), 255))

            toneCurveBytes[currentCurveIndex * 4 + 1] = UInt8(fmin(fmax(g + rgbCompositeCurve[Int(g)], 0), 255))

            toneCurveBytes[currentCurveIndex * 4 + 2] = UInt8(fmin(fmax(r + rgbCompositeCurve[Int(r)], 0), 255))

            toneCurveBytes[currentCurveIndex * 4 + 3] = 255
        }

        let data = Data(bytesNoCopy: UnsafeMutablePointer<UInt8>(toneCurveBytes), count: length, deallocator: .free)

        toneCurveTexture = CIImage(bitmapData: data, bytesPerRow: length, size: CGSize(width: 256, height: 1), format: kCIFormatBGRA8, colorSpace: nil)
    }

    func setDefaults() {

        inputRedControlPoints = RGBToneCurveFilter.defaultCurveControlPoints
        inputGreenControlPoints = RGBToneCurveFilter.defaultCurveControlPoints
        inputBlueControlPoints = RGBToneCurveFilter.defaultCurveControlPoints
        inputRGBCompositeControlPoints = RGBToneCurveFilter.defaultCurveControlPoints

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

    fileprivate func getPreparedSplineCurve(_ points: [CIVector]) -> [Float] {

        if let cachedCurve = RGBToneCurveFilter.splineCurveCache.object(forKey: points as AnyObject) as? [Float] {

            return cachedCurve
        }

        if points.isEmpty {
            assert(false, "Empty")
            return []
        }

        // Sort the array.
        let sortedPoints = points.sorted { return $0.x < $1.x }

        // Convert from (0, 1) to (0, 255).
        var convertedPoints = [CIVector]()

        for index in 0..<sortedPoints.count {
            let point = sortedPoints[index]
            convertedPoints.append(CIVector(x: point.x * 255, y: point.y * 255))
        }

        var splinePoints = splineCurve(convertedPoints)

        // If we have a first point like (0.3, 0) we'll be missing some points at the beginning
        // that should be 0.

        let firstSplinePoint = splinePoints.first!

        if firstSplinePoint.x > 0 {

            for index in (0...Int(firstSplinePoint.x)).reversed() {

                splinePoints.insert(CIVector(x: CGFloat(index), y: 0.0), at: 0)
            }
        }

        // Insert points similarly at the end, if necessary.
        let lastSplinePoint = splinePoints.last!

        if lastSplinePoint.x < 255 {
            for index in (Int(lastSplinePoint.x) + 1)...255 {
                splinePoints.append(CIVector(x: CGFloat(index), y: 255))
            }
        }

        // Prepare the spline points.
        var preparedSplinePoints = [Float]()

        for index in 0..<splinePoints.count {

            let newPoint = splinePoints[index]
            let origPoint = CIVector(x: newPoint.x, y: newPoint.x)

            var distance = Float(sqrt(pow((origPoint.x - newPoint.x), 2.0) + pow((origPoint.y - newPoint.y), 2.0)))

            if origPoint.y > newPoint.y {
                distance = -distance
            }

            preparedSplinePoints.append(distance)
        }

        RGBToneCurveFilter.splineCurveCache.setObject(preparedSplinePoints as AnyObject, forKey: points as AnyObject, cost: 1)

        return preparedSplinePoints
    }

    private func splineCurve(_ points: [CIVector]) -> [CIVector] {

        let sd = secondDerivative(points)

        if sd.isEmpty {
            assert(false, "Empty")
            return []
        }

        // [points count] is equal to [sdA count]
        let n = sd.count

        var output = [CIVector]()

        for index in 0..<n-1 {

            let cur = points[index]
            let next = points[index+1]

            for x in Int(cur.x)..<Int(next.x) {

                let t: CGFloat = (CGFloat(x) - cur.x) / (next.x - cur.x)

                let a = 1.0 - t
                let b = t
                let h = next.x - cur.x

                // build time optimizations
                let part1: CGFloat = a * cur.y + b * next.y
                let part2: CGFloat = (h * h / 6.0)
                let part3: CGFloat = (a * a * a - a) * sd[index]
                let part4: CGFloat = (b * b * b - b) * sd[index+1]
                let part5: CGFloat = (part3 + part4)

                var y = part1 + part2 * part5
                y = min(y, 255.0)
                y = max(y, 0.0)

                let newPoint = CIVector(x: CGFloat(x), y: y)

                output.append(newPoint)
            }
        }

        // The above always misses the last point because the last point is the last next, so we approach but don't equal it.
        output.append(points.last!)
        return output
    }

    private func secondDerivative(_ points: [CIVector]) -> [CGFloat] {

        let n = points.count

        if n <= 1 {
            assert(false, "")
            return []
        }

        var matrix = Array(repeating: Array(repeating: CGFloat(), count: 3), count: n)

        var result = Array(repeating: CGFloat(), count: n)

        matrix[0][1] = 1

        // What about matrix[0][1] and matrix[0][0]? Assuming 0 for now (Brad L.)
        matrix[0][0] = 0
        matrix[0][2] = 0

        for index in 1..<n-1 {

            let P1 = points[index-1]
            let P2 = points[index]
            let P3 = points[index+1]

            matrix[index][0] = (P2.x-P1.x) / 6.0
            matrix[index][1] = (P3.x-P1.x) / 3.0
            matrix[index][2] = (P3.x-P2.x) / 6.0
            result[index] = (P3.y-P2.y)/(P3.x-P2.x) - (P2.y-P1.y)/(P2.x-P1.x)
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

            let denominator = matrix[index-1][1]
            let k: CGFloat = denominator == 0.0 ? 0.0 : matrix[index][0] / denominator

            matrix[index][1] -= k * matrix[index-1][2]
            matrix[index][0] = 0.0
            result[index] -= k * result[index-1]
        }

        // solving pass2 (down->up)
        for index in (0...n-2).reversed() {

            let denominator = matrix[index+1][1]
            let k: CGFloat = denominator == 0.0 ? 0.0 : matrix[index][2] / denominator

            matrix[index][1] -= k * matrix[index+1][0]
            matrix[index][2] = 0.0

            result[index] -= k * result[index+1]
        }
        
        var output = [CGFloat]()
        
        for index in 0..<n {
            let denominator = matrix[index][1]
            let value = matrix[index][1] == 0.0 ? 0.0 : result[index] / denominator
            output.append(value)
        }
        
        return output
    }
}

private extension UnsafeMutablePointer {
    static func calloc<T>(_ count: Int, initialValue: T) -> UnsafeMutablePointer<T> {
        let ptr = UnsafeMutablePointer<T>.allocate(capacity: count)
        ptr.initialize(to: initialValue, count: count)
        return ptr
    }
}

