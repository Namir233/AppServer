//
//  IPAManager.swift
//  AppServer
//
//  Created by 王振旺 on 2017/7/10.
//
//

import Foundation
import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import PerfectMustache
import PerfectZip
import PerfectThread

class IPAManager {
    static let s = IPAManager()
    var ipas: [String: [IPAFile]] = [:]
    
    init() {
        let dir = Dir(workDir + "Static/apps")
        try? dir.forEachEntry { (name) in
            let file = File(dir.path + name)
            if file.isDir {
                let appsDir = Dir(file.path)
                try? appsDir.forEachEntry(closure: { (ipaName) in
                    if ipaName.filePathExtension == "ipa" {
                        let ipa = IPAFile(file: File(appsDir.path + ipaName))
                        if ipa.exists {
                            handle(ipa: ipa)
                        }
                    }
                })
            }
        }
    }
    
    static let uploadHandler: PerfectHTTP.RequestHandler = {
        (request, response) in
        if let uploads = request.postFileUploads, let upload = uploads.first {
            let uploadFile = File(upload.tmpFileName)
            let manager = IPAManager.s
            if let ipa = manager.handleTempFile(file: uploadFile) {
                manager.uploadToPgyer(ipa: ipa)
                manager.handle(ipa: ipa)
                
                response.setHeader(.contentType, value: "text/html")
                response.appendBody(string: "{\"id\":\"\(ipa.identifier)\"}")
                response.completed()
            } else {
                response.setHeader(.contentType, value: "text/html")
                response.status = .expectationFailed
                response.appendBody(string: "failed")
                response.completed()
            }
        }
    }
    
    struct ListHandler: MustachePageHandler {
        func extendValuesForResponse(context contxt: MustacheWebEvaluationContext, collector: MustacheEvaluationOutputCollector) {
            var values = MustacheEvaluationContext.MapType()
            values["ipas"] = IPAManager.s.ipas.map { (k, v) -> Any in
                let ipa = v.last!
                var values: [String: Any] = [:]
                values["identifier"] = k
                values["name"] = ipa.displayName
                values["version"] = ipa.version
                values["icon"] = ipa.identifier + "/icon"
                values["time"] = ipa.time.toShortString()
                values["plistUrl"] = "https%3A%2F%2Ffile-1253689418.cosgz.myqcloud.com%2FTiantian_nami_20171012.plist"
                return values
            }
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
    
    static let listHandler: PerfectHTTP.RequestHandler = {
        (request, response) in
        mustacheRequest(request: request, response: response, handler: ListHandler(), templatePath: workDir + "Mustache/list.html")
    }
    
    struct AppHandler: MustachePageHandler {
        func extendValuesForResponse(context contxt: MustacheWebEvaluationContext, collector: MustacheEvaluationOutputCollector) {
            let packageName = contxt.webRequest.urlVariables["id"] ?? ""
            
            if let ipa = IPAManager.s.ipas[packageName]?.last {
                var values = MustacheEvaluationContext.MapType()
                values["identifier"] = ipa.identifier
                values["name"] = ipa.displayName
                values["version"] = ipa.version
                values["icon"] = "icon"
                values["time"] = ipa.time.toShortString()
                values["plistUrl"] = "https%3A%2F%2Ffile-1253689418.cosgz.myqcloud.com%2FTiantian_nami_20171012.plist"
                contxt.extendValues(with: values)
                
                do {
                    try contxt.requestCompleted(withCollector: collector)
                } catch {
                    let response = contxt.webResponse
                    response.status = .internalServerError
                    response.appendBody(string: "\(error)")
                    response.completed()
                }
            } else {
                let response = contxt.webResponse
                response.setHeader(.contentType, value: "text/html")
                response.status = .notFound
                response.appendBody(string: "Not found")
                response.completed()
            }
        }
    }
    
    static let appHandler: PerfectHTTP.RequestHandler = {
        (request, response) in
        mustacheRequest(request: request, response: response, handler: AppHandler(), templatePath: workDir + "Mustache/app.html")
    }
    
    func handleTempFile(file: File) -> IPAFile? {
        if let ipa = IPAFile(tempFile: file) {
            return ipa
        } else {
            return nil
        }
    }
    
    func handle(ipa: IPAFile) {
        var array = ipas[ipa.identifier]
        if array == nil {
            array = []
        }
        
        var index = array!.count
        for (i, item) in array!.enumerated() {
            if item.v == ipa.v {
                index = i
                array!.remove(at: i)
                break
            } else if item.v > ipa.v {
                index = i
                break
            }
        }
        array!.insert(ipa, at: index)
        ipas[ipa.identifier] = array
    }
    
    func uploadToPgyer(ipa: IPAFile) {
        runCommand(launchPath: "/usr/bin/curl", arguments: "https://w.laily.net/add -F version=\(ipa.version) -F url1=http://172.16.1.91:8055/\(ipa.identifier)/\(ipa.bundleName)_\(ipa.version).ipa -F url2=https://www.pgyer.com/yzL3".components(separatedBy: " "))
        runCommand(launchPath: workDir + "IPAUploader", arguments: [ipa.file.realPath])
    }
}
