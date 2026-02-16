//
//  main.swift
//  ScrcpyCameraExtension
//
//  Created by aditya on 16/02/26.
//

import Foundation
import CoreMediaIO

let providerSource = ScrcpyCameraExtensionProviderSource(clientQueue: nil)
CMIOExtensionProvider.startService(provider: providerSource.provider)

CFRunLoopRun()
