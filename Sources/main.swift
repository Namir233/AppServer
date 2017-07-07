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

var ipaInfo: [String: Any]? = nil
//let workDir: String = File("/Users/namir/server/AppServer/").realPath
let workDir: String = File("~/server/AppServer/").realPath

var routes = Routes()
routes.add(method: .get, uri: "/") { (request, response) in
    request.path = "/index.html"
    StaticFileHandler(documentRoot: workDir + "Static").handleRequest(request: request, response: response)
}

routes.add(method: .get, uri: "/res/**") { (request, response) in
    let path = request.path
    let index = path.index(path.startIndex, offsetBy: 4)
    request.path = path.substring(from: index)
    StaticFileHandler(documentRoot: workDir + "Resource").handleRequest(request: request, response: response)
}

routes.add(method: .get, uri: "/files/**") { (request, response) in
    let path = request.path
    let index = path.index(path.startIndex, offsetBy: 6)
    request.path = path.substring(from: index)
    StaticFileHandler(documentRoot: workDir + "Static").handleRequest(request: request, response: response)
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

func loadIPAInfo() -> [String: Any] {
    if ipaInfo == nil {
        let result = runCommand(launchPath: "/usr/bin/python", arguments: [workDir + "Static/Wolf/ipa_plist.py", workDir + "Static/Wolf/WolfManKill.ipa"])
        let data = result.data(using: .utf8)!
        
        let jsonObj = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        ipaInfo = jsonObj != nil ? jsonObj! as? [String: Any] : nil
    }
    return ipaInfo ?? [:]
}

struct WolfHandler: MustachePageHandler {
    func extendValuesForResponse(context contxt: MustacheWebEvaluationContext, collector: MustacheEvaluationOutputCollector) {
        var values = MustacheEvaluationContext.MapType()
        values["version"] = loadIPAInfo()["CFBundleVersion"] ?? "?.?.?"
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
    mustacheRequest(request: request, response: response, handler: WolfHandler(), templatePath: workDir + "Mustache/wolf.html")
}

routes.add(method: .get, uri: "/Wolf", handler: wolfIndexHander)

routes.add(method: .get, uri: "/Wolf/api/update") { (request, response) in
    response.setHeader(.contentType, value: "text/json")
    response.appendBody(string: "{\"version\":\"\(loadIPAInfo()["CFBundleVersion"] ?? "?.?.?")\"}")
    response.completed()
}

routes.add(method: .get, uri: "/Wolf/upload") { (request, response) in
    request.path = "/upload.html"
    StaticFileHandler(documentRoot: workDir + "Static").handleRequest(request: request, response: response)
}

routes.add(method: .post, uri: "/Wolf/upload") { (request, response) in
    if let uploads = request.postFileUploads, let upload = uploads.first {
        let ipaPath = workDir + "Static/Wolf/WolfManKill.ipa"
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
        ipaInfo = nil
        response.setHeader(.contentType, value: "text/html")
        response.appendBody(string: "{}")
        response.completed()
    }
}

routes.add(method: .get, uri: "/Wolf/**") { (request, response) in
    if request.path == "/Wolf/" {
        wolfIndexHander(request, response)
    } else {
        StaticFileHandler(documentRoot: workDir + "Static").handleRequest(request: request, response: response)
    }
}

class MyObj {
    @objc func startHttpServer() {
        var httpRoutes = Routes()
        
        httpRoutes.add(method: .get, uri: "**") { (request, response) in
            if request.path == "//" {
                request.path = ""
            }
            response.setHeader(.contentType, value: "text/html")
            response.appendBody(string: "<html><head><meta http-equiv=\"Refresh\" content=\"0; url=https://namir.wang\(request.path)\"></head><body></body></html>")
            response.completed()
        }
        
        let httpServer = HTTPServer()
        httpServer.addRoutes(httpRoutes)
        httpServer.serverPort = 80
        httpServer.serverName = "namir.wang"
        
        do {
            // Launch the servers based on the configuration data.
            try httpServer.start()
        } catch {
            print(error)
            fatalError("\(error)") // fatal error launching one of the servers
        }
    }
    
    func start() {
        let thread = Thread(target: self, selector: #selector(startHttpServer), object: nil)
        thread.start()
    }
}

//MyObj().start()

let server = HTTPServer()

server.addRoutes(routes)
server.serverPort = 8055
//server.serverAddress = "namir.wang"
//server.ssl = (sslCert: "/Users/namir/certificate/2_namir.wang.crt", sslKey: "/Users/namir/certificate/3_namir.wang.key");

do {
    // Launch the servers based on the configuration data.
    try server.start()
} catch {
    print(error)
    fatalError("\(error)") // fatal error launching one of the servers
}
