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
            if let note = MIDINote.note(input: String(component)) {
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
parseFolders()


var groups = [Group]()

// represents a region
class Sample {
    var file: File
    
    var hitID: HitID {
        let components = file.nameExcludingExtension.split(separator: "-")
        return Int(components.last ?? "") ?? -1
    }
    
    var noteID: String {
        let components = file.nameExcludingExtension.split(separator: "-")
        return String(components.first ?? "")
    }
    
    private var analyzedVolume: Float? = nil
    var volume: Float {
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
}
 
class Note {
    var hits = [Int: Hit]()
    var noteID: NoteID = ""
    var velocityLayers = [VelocityLayer]()
}

class Hit {
    var noteID: NoteID {
        return samples.values.first?.noteID ?? ""
    }
    var hitID: HitID {
        return samples.values.first?.hitID ?? -1
    }
    var samples = [MicID: Sample]()
    var volume: Float = -1
    var velocity: Int = 0
}

class Mic {
    var id: String = ""
    var folder: Folder?
    var samples = [NoteID: [Sample]]()
}

typealias NoteID = String
typealias MicID = String
typealias HitID = Int

 
var notes = [NoteID: Note]()
var mics = [Mic]()

// creates both the notes/hits and mics structures
func parseFolders() {
    for subfolder in folder.subfolders {
        let mic = Mic()
        mic.folder = folder
        mic.id = folder.name
        mics.append(mic)
        
        for file in subfolder.files {
            let sample = Sample(file: file)
      
            let noteID = sample.noteID
            // check if we already have the note for the microphone
            if mic.samples[noteID] == nil {
                // create a new array of samples for the note
                mic.samples[noteID] = [Sample]()
            }
            // add the new sample to the array
            mic.samples[noteID]?.append(sample)
            
            // now check if we have the note covered in drums, perhaps by another microphone already parsed
            let note = notes[noteID] ?? Note()
            note.noteID = sample.noteID
             
            // now see if we already have a hit (corresponding to the sample number) for this sample
            if let hit = note.hits[sample.hitID] {
                hit.samples[mic.id] = sample

            } else {
                let hit = Hit()
                hit.samples[mic.id] = sample
                note.hits[sample.hitID] = hit
            }
        }
    }
}
 
// analyze the sample volumes
for mic in mics {
    for sampleArray in mic.samples.values {
        var min: Float = MAXFLOAT
        var max: Float = 0.0
        
        for sample in sampleArray {
            // analyze the volume
            let volume = sample.volume
            if volume < min { min = volume }
            if volume > max { max = volume }
        }
         
        for sample in sampleArray {
            sample.scaledVolume = ( sample.volume - min ) / (max - min)
        }
    }
}

for note in notes.values { 
    // now apply the analysis to the the hits construct
    for hit in note.hits.values {
        var sum: Float = 0.0
        for sample in hit.samples.values {
            sum = sum + sample.scaledVolume
        }
        hit.volume = sum / Float(hit.samples.count)
    }
    
    //define a velocity for each hit
    for (i, hit) in note.hits.values.sorted(by: { $0.volume < $1.volume } ).enumerated() {
        let ratio: Float = Float(i+1) / Float(note.hits.values.count)
        let velocity = ratio * 127
        hit.velocity = Int(round(velocity))
    }
     

}
  

class VelocityLayer {
    var note: MIDINote?
    var vel_low: Int?
    var vel_high: Int?
    var hits = [Hit]()
}

// using the hit info, we can construct velocity layers
for note in notes.values {
    // sort the hits
    let hits = note.hits.values.sorted(by: { $0.velocity < $1.velocity } )
    
    var prevVelocity = 0
    var velocityLayer = VelocityLayer()
    for hit in hits {
        
        
        note.velocityLayers.append(velocityLayer)
        
    }
    
    
    
    velocityLayer.note = MIDINote.note(drum: note.noteID)
     
}

 
 
// create a new .sfz file for each microphone
 
for mic in mics {
    guard let folder = mic.folder else { continue }
    let output = try folder.createFile(named: folder.name + ".sfz")
    try output.write("//// Instrument defined by folder: \(mic.folder?.name ?? "")\n\n\n")
    for note in mic.samples.keys {
        
        //create a group for each velocity
        
        
    }
    
}
 
 
for group in groups {
    try output.append("\n\n\n//// Group defined by subfolder: \(group.folder!.name)\n")
    try output.append(group.string)
    for region in group.regions {
        try output.append(region.string)
    }
}

exit(1)



