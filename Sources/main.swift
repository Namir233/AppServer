//
//  main.swift
//  AppServer
//
//  Created by 王振旺 on 2017/6/28.
//
//

import Foundation
import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import PerfectMustache

var version: String? = nil

var routes = Routes()
routes.add(method: .get, uri: "/") { (request, response) in
    request.path = "/index.html"
    StaticFileHandler(documentRoot: "./Static").handleRequest(request: request, response: response)
}

routes.add(method: .get, uri: "/res/**") { (request, response) in
    let path = request.path
    let index = path.index(path.startIndex, offsetBy: 4)
    request.path = path.substring(from: index)
    StaticFileHandler(documentRoot: "./Resource").handleRequest(request: request, response: response)
}

routes.add(method: .get, uri: "/files/**") { (request, response) in
    let path = request.path
    let index = path.index(path.startIndex, offsetBy: 6)
    request.path = path.substring(from: index)
    StaticFileHandler(documentRoot: "./Static").handleRequest(request: request, response: response)
}

func runCommand(launchPath: String, arguments: [String]) -> String {
    let pipe = Pipe()
    let file = pipe.fileHandleForReading
    
    let task = Process()
    task.launchPath = launchPath
    task.arguments = arguments
    task.standardOutput = pipe
    task.launch()
    
    let data = file.readDataToEndOfFile()
    return String(data: data, encoding: .utf8)!
}

func loadIPAVersion() -> String {
    if version == nil {
        version = runCommand(launchPath: "/usr/bin/python", arguments: ["./Static/Wolf/ipa_plist.py", "./Static/Wolf/WolfManKill.ipa"])
    }
    return version ?? ""
}

struct WolfHandler: MustachePageHandler {
    func extendValuesForResponse(context contxt: MustacheWebEvaluationContext, collector: MustacheEvaluationOutputCollector) {
        var values = MustacheEvaluationContext.MapType()
        values["version"] = loadIPAVersion()
        contxt.extendValues(with: values)
        do {
            try contxt.requestCompleted(withCollector: collector)
        } catch {
            let response = contxt.webResponse
            response.status = .internalServerError
            response.appendBody(string: "\(error)")
            response.completed()
        }
    }
}

let wolfIndexHander = { (request, response) in
    mustacheRequest(request: request, response: response, handler: WolfHandler(), templatePath: "./Mustache/wolf.html")
}

routes.add(method: .get, uri: "/Wolf", handler: wolfIndexHander)

routes.add(method: .get, uri: "/Wolf/upload") { (request, response) in
    request.path = "/upload.html"
    StaticFileHandler(documentRoot: "./Static").handleRequest(request: request, response: response)
}

routes.add(method: .post, uri: "/Wolf/upload") { (request, response) in
    if let uploads = request.postFileUploads, let upload = uploads.first {
        let ipaPath = "./Static/Wolf/WolfManKill.ipa"
        let ipaFile = File(ipaPath)
        if ipaFile.exists {
            ipaFile.delete()
        }
        let uploadFile = File(upload.tmpFileName)
        
        do {
            let _ = try uploadFile.moveTo(path: ipaPath)
        } catch {
            print(error)
        }
        version = nil
        response.setHeader(.contentType, value: "text/html")
        response.appendBody(string: "{}")
        response.completed()
    }
}

routes.add(method: .get, uri: "/Wolf/**") { (request, response) in
    if request.path == "/Wolf/" {
        wolfIndexHander(request, response)
    } else {
        StaticFileHandler(documentRoot: "./Static").handleRequest(request: request, response: response)
    }
}

let server = HTTPServer()

server.addRoutes(routes)
server.serverPort = 8055

do {
    // Launch the servers based on the configuration data.
    try server.start()
} catch {
    fatalError("\(error)") // fatal error launching one of the servers
}

