//
//  FilterConstructor.swift
//  Example
//
//  Created by Limon on 8/3/16.
//  Copyright © 2016 Lady. All rights reserved.
//

import CoreImage

class FilterConstructor: NSObject {}

extension FilterConstructor: CIFilterConstructor {

    func filterWithName(name: String) -> CIFilter? {
        return fromClassName(name)
    }

    private func fromClassName(className: String) -> CIFilter {
        let className = NSBundle.mainBundle().infoDictionary!["CFBundleName"] as! String + "." + className
        let aClass = NSClassFromString(className) as! CIFilter.Type
        return aClass.init()
    }

}

