//
//  Util.swift
//  AdamsHeart
//
//  Created by Adam Duston on 7/13/16.
//  Copyright © 2016 Adam Duston. All rights reserved.
//


func makeInt( bytes: inout [UInt8], offset: Int) -> UInt32 {
    return (UInt32(bytes[offset]) << 24) &
        (UInt32(bytes[offset + 1]) << 16) &
        (UInt32(bytes[offset + 2]) << 8) &
        UInt32(bytes[offset + 3])
}

func copyBytes(source: UInt32, destination: inout [UInt8], offset: Int) {
    destination[offset] = UInt8(source >> 24)
    destination[offset + 1] = UInt8(source >> 16)
    destination[offset + 2] = UInt8(source >> 8)
    destination[offset + 3] = UInt8(source)
}
