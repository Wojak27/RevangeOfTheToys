//
//  WaveCompletedProtocol.swift
//  RevangeOfTheToys
//
//  Created by Karol Wojtulewicz on 2019-02-24.
//  Copyright © 2019 Karol Wojtulewicz. All rights reserved.
//

import Foundation

@objc protocol WaveControlerProtocol {
    func isCompleted()
}

@objc protocol MissileLounched {
    func missileLounched()
}
