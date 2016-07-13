//
//  SessionData.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/13/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//

import Foundation

struct SessionMetadata {
    var onServer: Bool = false
    var committed: Bool = false
    var version: Int
    
    init(version: Int) {
        self.version = version
    }
    
    func toJson() -> Data? {
        // TODO: write me
        return nil
    }
    
    static func fromJson(json: Data) -> SessionMetadata? {
        // TODO: write me
        return nil
    }
}
