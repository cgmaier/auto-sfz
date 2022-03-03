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

var notes = [NoteID: Note]()
var mics = [Mic]()
 
parseFolders()
 
// represents a region
 
// creates both the notes/hits and mics structures
func parseFolders() {
    for subfolder in folder.subfolders {
        let mic = Mic()
        mic.folder = subfolder
        mic.id = subfolder.name
        mics.append(mic)
        print("mic id \(mic.id)")

        for file in subfolder.files {
            print("new file \(file.name)")
            let sample = Sample(file: file)
      
            let noteID = sample.noteID
            
            print(noteID)
            // check if we already have the note for the microphone
            if mic.samples[noteID] == nil {
                // create a new array of samples for the note
                print(noteID)
                mic.samples[noteID] = [Sample]()
            }
            // add the new sample to the array
            mic.samples[noteID]?.append(sample)
            
            // now check if we have the note covered in drums, perhaps by another microphone already parsed
            let note = notes[noteID] ?? Note(id:noteID)
            notes[noteID] = note
             
            // now see if we already have a hit (corresponding to the sample number) for this sample
            if let hit = note.hits[sample.hitID] {
                print(hit.id)
                print("found a hit \(hit.id)")

                hit.samples[mic.id] = sample

            } else {
                let hit = Hit(id: sample.hitID, noteID: sample.noteID)
                hit.samples[mic.id] = sample
                print("new hit \(hit.id)")
                note.hits[hit.id] = hit
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
 

// using the hit info, we can construct velocity layers
for note in notes.values {
    // sort the hits
    let hits = note.hits.values.sorted(by: { $0.velocity < $1.velocity } )
    
    var min = 0
    var max = 0
    var _velocityLayer: VelocityLayer?
    for hit in hits {
        
        if hit.velocity > max {
            min = max + 1
            max = hit.velocity
            
            // create a new velocity layer
            let velocityLayer = VelocityLayer()
            velocityLayer.hits.append(hit)
            velocityLayer.vel_low = min
            velocityLayer.vel_high = max
            note.velocityLayers.append(velocityLayer)
            _velocityLayer = velocityLayer
        } else {
            if let velocityLayer = _velocityLayer {
                velocityLayer.hits.append(hit)
            }
        }
        
    }
    
}

// create a new .sfz file for each microphone
 
for mic in mics {
    guard let parent = mic.folder?.parent, let folder = mic.folder else { continue }
    let output = try parent.createFile(named: folder.name + ".sfz")
    try output.write("//// Instrument defined by folder: \(folder.name)\n\n\n")
    for note in notes.values {
        for layer in note.velocityLayers  {
            let header = layer.header(micID: mic.id)
            try output.append(header.definition)
        }
    }
    
}
  



exit(1)
