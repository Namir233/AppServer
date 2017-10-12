//
//  Package.swift
//  AppServer
//
//  Created by 王振旺 on 2017/6/28.
//  Copyright © 2017年 Nami. All rights reserved.
//

import PackageDescription

let package = Package(
	name: "AppServer",
	targets: [],
	dependencies: [
		.Package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", majorVersion: 2),
		.Package(url: "https://github.com/PerfectlySoft/Perfect-Mustache.git",
        majorVersion: 2, minor: 0),
		.Package(url: "https://github.com/PerfectlySoft/Perfect-Zip.git", majorVersion: 2, minor: 0),
    ]
)
