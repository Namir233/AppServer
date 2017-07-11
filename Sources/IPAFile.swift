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

class IPAFile {
    var version: String = ""
    var displayName: String = ""
    var identifier: String = ""
    var bundleName: String = ""
    var icon: String = ""
    var file: File
    var exists: Bool = false
    var v: Version!
    
    init(file: File) {
        self.file = file
        
        let appDirName = file.path.hasSuffix(".ipa") ? file.path.lastFilePathComponent.deletingFileExtension : file.path.lastFilePathComponent + "_"
        let appDir = Dir(file.path.deletingLastFilePathComponent + "/" + appDirName)
        if !appDir.exists {
            unzip(to: appDir)
        }
        loadInfoFrom(plist: File(appDir.path + "Info.plist"))
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
        let tempFile = Dir(file.path + "_temp")
        let unZipResult = zippy.unzipFile(source: file.path, destination: tempFile.path, overwrite: true)
        guard unZipResult == .ZipSuccess else {
            return
        }
        
        let payLoadDir = Dir(tempFile.path + "Payload")
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
        
        IPAFile.copyFile(from: File(appDir!.path), to: File(dir.path))
        try? tempFile.delete()
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
            let iconName = loadIconFrom(dir: Dir(plist.path.deletingLastFilePathComponent), dict: dict)
            icon = "\(identifier)/\(bundleName)_\(version)/\(iconName)"
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
}
