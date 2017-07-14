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
import PerfectZip

var ipaInfo: [String: Any]? = nil
let workDir: String = File("/Users/namir/server/AppServer/").realPath
//let workDir: String = File("~/server/AppServer/").realPath

var routes = Routes()

routes.add(method: .get, uri: "/res/**") { (request, response) in
    let path = request.path
    let index = path.index(path.startIndex, offsetBy: 4)
    request.path = path.substring(from: index)
    StaticFileHandler(documentRoot: workDir + "Resource").handleRequest(request: request, response: response)
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

routes.add(method: .get, uri: "/", handler: IPAManager.listHandler)

routes.add(method: .get, uri: "/Upload") { (request, response) in
    request.path = "/upload.html"
    StaticFileHandler(documentRoot: workDir + "Static").handleRequest(request: request, response: response)
}
routes.add(method: .post, uri: "/Upload", handler: IPAManager.uploadHandler)
routes.add(method: .get, uri: "/{id}/") { (request, response) in
    let packageName = request.urlVariables["id"] ?? ""
    
    if packageName == "Upload" {
        request.path = "/upload.html"
        StaticFileHandler(documentRoot: workDir + "Static").handleRequest(request: request, response: response)
        return
    }
    
    IPAManager.appHandler(request, response)
}

routes.add(method: .get, uri: "/{id}/icon") { (request, response) in
    let packageName = request.urlVariables["id"] ?? "";
    
    if let ipa = IPAManager.s.ipas[packageName]?.last {
        request.path = "\(ipa.identifier)/\(ipa.bundleName)_\(ipa.version)/\(ipa.icon)"
        StaticFileHandler(documentRoot: workDir + "Static/apps/").handleRequest(request: request, response: response)
    } else {
        response.setHeader(.contentType, value: "text/html")
        response.status = .notFound
        response.appendBody(string: "Not found")
        response.completed()
    }
}

routes.add(method: .get, uri: "/api/{id}/version") { (request, response) in
    let packageName = request.urlVariables["id"] ?? "";
    
    if let ipa = IPAManager.s.ipas[packageName]?.last {
        response.setHeader(.contentType, value: "text/json")
        response.appendBody(string: "{\"version\":\"\(ipa.version)\"}")
        response.completed()
    } else {
        response.setHeader(.contentType, value: "text/html")
        response.status = .notFound
        response.appendBody(string: "Not found")
        response.completed()
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
