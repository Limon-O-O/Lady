//
//  ViewController.swift
//  Example
//
//  Created by Limon on 8/3/16.
//  Copyright © 2016 Lady. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // creates 100 UInt8s initialized to 0

//        bits.initializeFrom(Array<UInt8>(count: (256 * 4), repeatedValue: 0))


        let firstSplinePoint = 10


        for index in (0..<Int(firstSplinePoint)).reverse() {
            print(index)
        }

        let bits = UnsafeMutablePointer<UInt8>.calloc(256 * 4, initialValue: UInt8(0))

//        let _ = (0..<256).map { index in
//            bits[index] = UInt8(1)
//        }
    }
}

private extension UnsafeMutablePointer {

    // version that takes any kind of type for initial value

    static func calloc<T>(count: Int, initialValue: T) -> UnsafeMutablePointer<T> {
        let ptr = UnsafeMutablePointer<T>.alloc(count)
        ptr.initializeFrom(Repeat(count: count, repeatedValue: initialValue))
        return ptr
    }

    // convenience version for integer-literal-creatable types
    // that initializes to zero of that type
    static func calloc<I: IntegerLiteralConvertible> (count: Int) -> UnsafeMutablePointer<I> {
        return UnsafeMutablePointer<I>.calloc(count, initialValue: 0)
    }
}



