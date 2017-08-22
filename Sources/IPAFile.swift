//
//  IPAFile.swift
//  AppServer
//
//  Created by 王振旺 on 2017/7/10.
//
//

import Foundation
import PerfectLib
import PerfectZip
import AppKit.NSImage
import Alamofire

class IPAFile {
    var version: String = ""
    var displayName: String = ""
    var identifier: String = ""
    var bundleName: String = ""
    var icon: String = ""
    var file: File
    var exists: Bool = false
    var v: Version!
    var time: Date!
    
    init(file: File) {
        self.file = file
        
        let appDirName = file.path.hasSuffix(".ipa") ? file.path.lastFilePathComponent.deletingFileExtension : file.path.lastFilePathComponent + "_"
        let appDir = Dir(file.path.deletingLastFilePathComponent + "/" + appDirName)
        if !appDir.exists {
            unzip(to: appDir)
            let ipaInfoPlist = File(appDir.path + "files/Info.plist")
            loadInfoFrom(plist: ipaInfoPlist)
            let infoPlist = File(appDir.path + "Info.plist")
            IPAFile.copyFile(from: ipaInfoPlist, to: infoPlist)
            IPAFile.copyImage(from: File(appDir.path + "files/" + icon), to: File(appDir.path + "icon.png"))
            icon = "icon.png"
        } else {
            loadInfoFrom(plist: File(appDir.path + "Info.plist"))
        }
    }
    
    convenience init?(tempFile: File) {
        let tmpFile = File(workDir + "Temp/" + tempFile.path.lastFilePathComponent)
        IPAFile.moveFile(from: tempFile, to: tmpFile)
        self.init(file: tmpFile)
        guard exists else {
            return nil
        }
        
        let dir = Dir(workDir + "Static/apps/\(identifier)/")
        try? dir.create()
        file = File(dir.path + "\(bundleName)_\(version).ipa")

        let tempAppDir = Dir(tmpFile.path.deletingLastFilePathComponent + "/" + tmpFile.path.lastFilePathComponent + "_")
        IPAFile.moveFile(from: tmpFile, to: file)
        let appDir = Dir(dir.path + "\(bundleName)_\(version)")
        IPAFile.moveFile(from: File(tempAppDir.path), to: File(appDir.path))
    }

    func unzip(to dir: Dir) {
        let zippy = Zip()
        let tempDir = Dir(dir.path + "temp")
        let ipaDir = File(dir.path + "files")
        let unZipResult = zippy.unzipFile(source: file.path, destination: tempDir.path, overwrite: true)
        guard unZipResult == .ZipSuccess else {
            return
        }
        
        let payLoadDir = Dir(tempDir.path + "Payload")
        guard payLoadDir.exists else {
            return
        }
        
        var appDir: Dir?
        try? payLoadDir.forEachEntry { (name) in
            if name.filePathExtension == "app" {
                appDir = Dir(payLoadDir.path + name)
            }
        }
        guard appDir != nil else {
            return
        }
        
        do {
            let _ = try File(appDir!.path).moveTo(path: ipaDir.path)
        } catch {
            print(error)
        }
        
        IPAFile.deleteFile(File(tempDir.path))
    }
    
    static func copyImage(from: File, to: File) {
        guard let image = NSImage(contentsOfFile: from.path) else {
            return
        }
        guard let imageData = image.tiffRepresentation else {
            return
        }
        guard let rep = NSBitmapImageRep(data: imageData) else {
            return
        }
        guard let savaData = rep.representation(using: .PNG, properties: [:]) else {
            return
        }
        try? savaData.write(to: URL(fileURLWithPath: to.path))
    }
    
    static func deleteFile(_ file: File) {
        if file.isDir {
            let dir = Dir(file.path)
            do {
                try dir.forEachEntry(closure: { (name) in
                    deleteFile(File(file.path + name))
                })
                try dir.delete()
            } catch {
                print("delete \(file.path)  failed")
                print(error)
            }
        } else {
            file.delete()
        }
    }
    
    static func copyFile(from: File, to: File) {
        if from.isDir {
            let fromDir = Dir(from.path)
            let toDir = Dir(to.path)
            if !toDir.exists {
                do {
                    try toDir.create()
                } catch {
                    print("create \(toDir.path)  failed")
                }
            }
            do {
                try fromDir.forEachEntry(closure: { (name) in
                    copyFile(from: File(from.path + name), to: File(to.path + name))
                })
            } catch {
                print("forEach \(from.path)  failed")
                print(error)
            }
        } else {
            do {
                let _ = try from.copyTo(path: to.path, overWrite: true)
            } catch {
                print("cp \(from.path) to \(to.path) failed")
                print(error)
            }
        }
    }
    
    static func moveFile(from: File, to: File) {
        if from.isDir {
            let fromDir = Dir(from.path)
            let toDir = Dir(to.path)
            if !toDir.exists {
                do {
                    try toDir.create()
                } catch {
                    print("create \(toDir.path)  failed")
                }
            }
            do {
                try fromDir.forEachEntry(closure: { (name) in
                    moveFile(from: File(from.path + name), to: File(to.path + name))
                })
            } catch {
                print("forEach \(from.path)  failed")
                print(error)
            }
        } else {
            do {
                let _ = try from.moveTo(path: to.path, overWrite: true)
            } catch {
                print("mv \(from.path) to \(to.path) failed")
                print(error)
            }
        }
        from.delete()
    }
    
    func loadInfoFrom(plist: File) {
        if let dict = NSDictionary(contentsOfFile: plist.path) as? [String: Any] {
            displayName = dict["CFBundleDisplayName"] as? String ?? "Unkown"
            version = dict["CFBundleVersion"] as? String ?? "Unkown"
            identifier = dict["CFBundleIdentifier"] as? String ?? "Unkown"
            bundleName = dict["CFBundleName"] as? String ?? "Unkown"
            icon = loadIconFrom(dir: Dir(plist.path.deletingLastFilePathComponent), dict: dict)
            time = Date(timeIntervalSince1970: TimeInterval(file.modificationTime))
            exists = true
            v = Version(version)
        }
    }
    
    func loadIconFrom(dir: Dir, dict: [String: Any]) -> String {
        let icons = dict["CFBundleIcons"] as? [String: Any] ?? [:]
        let primaryIcons = icons["CFBundlePrimaryIcon"] as? [String: Any] ?? [:]
        let iconFiles = primaryIcons["CFBundleIconFiles"] as? [String] ?? []
        let iconName = iconFiles.last ?? ""
        var iconFile = File(dir.path + iconName + "@3x.png")
        if iconFile.exists {
            return iconFile.path.lastFilePathComponent
        } else {
            iconFile = File(dir.path + iconName + "@2x.png")
            return iconFile.path.lastFilePathComponent
        }
    }
    
    static func getFile() {
        let fileName = "Tiantian_nami.plist"
        let url = URL(string: "https://file-1253689418.cosgz.myqcloud.com/\(fileName)")!
        let time = Int(Date().timeIntervalSince1970)
        let timeStr = "\(time);\(time + 60 * 60)"
        let authorization = "q-sign-algorithm=sha1&q-ak=AKIDIPIxNaVIo69xWrpqUt40hAON8dtuxART&q-sign-time=\(timeStr)&q-key-time=\(timeStr)&q-header-list=content-type;host&q-url-param-list=&q-signature=\(signature(timeStr: timeStr, fileName: fileName, method: "delete"))"
        Alamofire.request(url, method: .delete, parameters: nil, headers: ["Content-Type": "text/plain", "Host": "file-1253689418.cosgz.myqcloud.com", "Authorization": authorization]).response { (response) in
            print(response)
        }
    }
    
    static func postFileToQCloud() {
        let fileName = "test.txt"
        let url = URL(string: "https://file-1253689418.cosgz.myqcloud.com/\(fileName)")!
        let data = "12345678".data(using: .utf8)!
        let time = Int(Date().timeIntervalSince1970)
        let timeStr = "\(time);\(time + 60 * 60)"
        let authorization = "q-sign-algorithm=sha1&q-ak=AKIDIPIxNaVIo69xWrpqUt40hAON8dtuxART&q-sign-time=\(timeStr)&q-key-time=\(timeStr)&q-header-list=content-type;host&q-url-param-list=&q-signature=\(signature(timeStr: timeStr, fileName: fileName, method: "put"))"
        Alamofire.upload(data, to: url, method: .put, headers: ["Content-Type": "text/plain", "Host": "file-1253689418.cosgz.myqcloud.com" ,"Authorization": authorization, "Content-Length": "8"]).response { (response) in
            print(response)
        }
    }
    
    static func signature(timeStr: String, fileName: String, method: String) -> String {
        let signKey = hmacSha1(str: "uYw5yc080e5IGzUklX4MQFoFSQAfvvf9", key: timeStr)
        let httpString = "\(method)\n/\(fileName)\n\ncontent-type=text/plain&host=file-1253689418.cosgz.myqcloud.com\n"
        let stringToSign = "sha1\n\(timeStr)\n\(sha1(str: httpString))\n"
        let sighature = hmacSha1(str: signKey, key: stringToSign)
        return sighature
    }
    
    static func test() {
        let key = "Gu5t9xGARNpq86cd98joQYCN3Cozk1qA"
        let str = "GETcvm.api.qcloud.com/v2/index.php?Action=DescribeInstances&Nonce=11886&Region=ap-guangzhou&SecretId=AKIDz8krbsJ5yKBZQpn74WFkmLPx3gnPhESA&Timestamp=1465185768&InstanceIds.0=ins-09dx96dg"
        
        print(hmacSha1(str: str, key: key))
    }
    
    static func sha1(str: String) -> String {
        return SHA1().calculate(string: str)
    }
    
    static func hmacSha1(str: String, key: String) -> String {
        return try! HMAC(key: key).authenticate(str)
    }
}
