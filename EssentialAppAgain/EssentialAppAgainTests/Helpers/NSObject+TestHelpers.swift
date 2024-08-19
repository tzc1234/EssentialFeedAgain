//
//  NSObject+TestHelpers.swift
//  EssentialAppAgainTests
//
//  Created by Tsz-Lung on 19/08/2024.
//

import Foundation

extension NSObject {
    static func initClass() -> Self {
        let name = String(describing: Self.self)
        let klass = NSClassFromString(name) as? NSObject.Type
        return klass?.init() as! Self
    }
}
