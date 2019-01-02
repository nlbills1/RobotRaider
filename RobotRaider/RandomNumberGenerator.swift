//
//  RandomNumberGenerator.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 3/10/17.
//  Copyright © 2017 invasivemachines. All rights reserved.
//

import Foundation

class RandomNumberGenerator {
    static var randomNum: UInt64 = 0    // We use a static variable so that it is changed with each run of xorshift_randomgen but
                                        // the result is retained across all usage of the RandomNumberGenerator.  In that way we
                                        // should be constantly getting new random numbers within the same level.
    
    init (seed: Int) {
        RandomNumberGenerator.randomNum = UInt64(seed)
    }
    
    // From https://en.wikipedia.org/wiki/Xorshift  for fast random
    // number generation.
    func xorshift_randomgen() -> Int {
        
        RandomNumberGenerator.randomNum ^= RandomNumberGenerator.randomNum << 13
        RandomNumberGenerator.randomNum ^= RandomNumberGenerator.randomNum << 17
        RandomNumberGenerator.randomNum ^= RandomNumberGenerator.randomNum << 5
        // A couple of extra steps to limit the number to 2^32 - 1
        // and divide by 7 to add just a tiny bit more randomness.
        // We're seeing that the results, when the % operator is
        // applies, are not nearly as random as we would like.
        RandomNumberGenerator.randomNum %= 2 << 31
        RandomNumberGenerator.randomNum /= 7
        return Int(RandomNumberGenerator.randomNum)
        
    }

}
