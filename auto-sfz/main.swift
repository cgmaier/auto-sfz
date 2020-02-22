//
//  main.swift
//  auto-sfz
//
//  Created by Chris Maier on 2/21/20.
//  Copyright © 2020 Chris Maier. All rights reserved.
//

import Foundation
import Files
   
protocol Entry {
    var string: String { get }
}

class Group {
    var folder: Folder?
    var regions = [Region]()
    
    func orderRegions() {
        self.regions = regions.sorted(by: { $0.key < $1.key })
        self.regions.first?.stretchTo(0)
        for (i, region) in self.regions.enumerated() {
            guard i+1 < self.regions.count else { break }
            self.regions[i+1].stretchTo(region.key)
        }
    }
}

extension Group: Entry {
    
    var string: String {
        return "<group>\n"
    }
}

class Region {
    var file: File!
    var key: Int {
        return Note.note(input: file.name).number
    }
    var codes = [OpCode]()
    
    func stretchTo(_ keyToStretchTo: Int) {
        let lokey = keyToStretchTo + 1
        if key == lokey {
            self.codes.append(OpCode.key(key))
        } else {
            self.codes.append(OpCode.pitch_keycenter(key))
            self.codes.append(OpCode.hikey(key))
            self.codes.append(OpCode.lokey(keyToStretchTo + 1))
        }
        self.codes.append(OpCode.sample(file!.parent!.name + "/" + file.name))
    }
}

extension Region: Entry {
    var string: String {
        var definition = "<region>"
        for code in codes {
            definition.append(" \(code.string)")
        }
        definition.append("\n")
        return definition
    }
}

var debug = false
var rootPath = "/Users/chrismaier/Dropbox/test_folder"

if !debug {
    print("Enter the root folder path:")
    guard let input = readLine(strippingNewline: true) else {
        print("aborting!")
        abort()
    }
    rootPath = input.trimmingCharacters(in: .whitespacesAndNewlines)
}

let folder = try Folder(path: rootPath)
var groups = [Group]()
 
for subfolder in folder.subfolders {
    let group = Group()
    group.folder = folder
    groups.append(group)
    for file in subfolder.files {
        let region = Region()
        region.file = file
        group.regions.append(region)
    }
    group.orderRegions()
}

let output = try folder.createFile(named: "files.sfz")
try output.write("//// Instrument defined by folder: \(folder.name)\n\n\n")
// output to the file
for group in groups {
    try output.append("\n\n\n//// Group defined by subfolder: \(group.folder!.name)\n")
    try output.append(group.string)
    for region in group.regions {
        try output.append(region.string)
    }
}

exit(1)



