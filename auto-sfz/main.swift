//
//  main.swift
//  auto-sfz
//
//  Created by Chris Maier on 2/21/20.
//  Copyright © 2020 Chris Maier. All rights reserved.
//

import Foundation
import Files
import AVFoundation

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
        let components = file.name.split(separator: "_")
        for component in components {
            if let note = Note.note(input: String(component)) {
                return note.number
            }
        }
        return -1
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

var debug = true
var rootPath = "/Users/christophermaier/Dropbox/leftovers/drum-sampling/samples-raw-v1/snare"

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

// represents a region
class Sample {
    var file: File
    
    var number: Int {
        let components = file.nameExcludingExtension.split(separator: "-")
        return Int(components.last ?? "") ?? -1
    }
    
    var drum: String {
        let components = file.nameExcludingExtension.split(separator: "-")
        return String(components.first ?? "")

    }
    
    var velocity: Int = 0
    
    var mic: String {
        return ""
    }
    
    private var analyzedVolume: Float? = nil
    var volume: Float {
        //print("debug: analyzing volume")
        if let _volume = analyzedVolume {
            return _volume
        }
        
        let url = URL(fileURLWithPath: file.path)
        if let audioFile = try? AVAudioFile(forReading: url) {
            analyzedVolume = audioFile.peak?.amplitude ?? -1.0
            return analyzedVolume ?? -1.0
        }
        return -2.0
    }
    
    var scaledVolume: Float = 0.0
    
    init(file: File) {
        self.file = file
    }
     
    var codes = [OpCode]()
     
     
}

class Hit {
    var sampleNumber: Int = -1
    var samples = [Sample]()
    var volume: Float = -1
}

class Mic {
    var folder: Folder?
    var samples = [Sample]()
}
 
class Drum {
    var note: Note?
    var hits = [Int: Hit]()
 }

var hits = [Int: Hit]()
var mics = [Mic]()

 
for subfolder in folder.subfolders {
    let mic = Mic()
    mic.folder = folder
    mics.append(mic)
    //print("found a new mic~~~~~~")
    for file in subfolder.files {
        let sample = Sample(file: file) 
        mic.samples.append(sample)
        if let hit = hits[sample.number] {
            //print("matching a hit: \(sample.number)")
            hit.samples.append(sample)
        } else {
            let hit = Hit()
            //print("found a new hit: \(sample.number)")
            hit.sampleNumber = sample.number
            hit.samples.append(sample)
            hits[sample.number] = hit
        }
    }
    //print("number of hits: ", hits.values.count)
}

// scale volumes
for mic in mics {
    var min: Float = MAXFLOAT
    var max: Float = 0.0
    for sample in mic.samples {
        let volume = sample.volume
        if volume < min { min = volume }
        if volume > max { max = volume }
    }
    
    for sample in mic.samples {
        sample.scaledVolume = ( sample.volume - min ) / (max - min)
    }
}

for hit in hits.values {
    var sum: Float = 0.0
    for sample in hit.samples {
        sum = sum + sample.scaledVolume
    }
    hit.volume = sum / Float(hit.samples.count)
}

for (i, hit) in hits.values.sorted(by: { $0.volume < $1.volume } ).enumerated() {
    let ratio: Float = Float(i+1) / Float(hits.values.count)
    let velocity = ratio * 127
    for sample in hit.samples {
        sample.velocity = Int(round(velocity))
    }
}

// now lets sort all of the mics based on their new velocities
for mic in mics {
    mic.samples = mic.samples.sorted(by: { $0.velocity < $1.velocity })
}

if let mic = mics.first {
    for sample in mic.samples {
        print(sample.velocity)
    }
}
/*
drums:
produces 3 files, one for each mic
 
<group> round robbin for velocity = 1, note = c 
    region seq 1
    region seq 2
 
 
 */


// choose the


//
//let output = try folder.createFile(named: "files.sfz")
//try output.write("//// Instrument defined by folder: \(folder.name)\n\n\n")
//// output to the file
//for group in groups {
//    try output.append("\n\n\n//// Group defined by subfolder: \(group.folder!.name)\n")
//    try output.append(group.string)
//    for region in group.regions {
//        try output.append(region.string)
//    }
//}

exit(1)



