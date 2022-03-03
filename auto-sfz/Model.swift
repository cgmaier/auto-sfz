//
//  Model.swift
//  auto-sfz
//
//  Created by Christopher Maier on 3/2/22.
//  Copyright © 2022 Chris Maier. All rights reserved.
//

import Foundation
import Files
import AVFoundation

class Note {
    var hits = [HitID: Hit]()
    var id: NoteID
    init(id: NoteID) {
        self.id = id
    }
    var velocityLayers = [VelocityLayer]()
}

class Hit {
    var noteID: NoteID
    var id: HitID
    
    init(id: HitID, noteID: NoteID) {
        self.id = id 
        self.noteID = noteID
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
    var scaledVolume: Float = 0.0
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
    
    init(file: File) {
        self.file = file
    }
}


enum HeaderType {
    case region
    case group
    case global
    
    var string: String {
        switch self {
        case .region: return "<region>"
        case .group: return "<group>"
        case .global: return "<global>"
        }
    }
}

class Header {
    var type: HeaderType = .region
    var opcodes = [OpCode]()
    var definition: String {
        var definition = type.string
        for code in opcodes {
            definition.append(" \(code.string)")
        }
        definition.append("\n")
        
        for subheader in subheaders {
            definition.append(subheader.definition)
        }
        return definition
    }
    var subheaders = [Header]()
}

class VelocityLayer {
    var note: MIDINote {
        return MIDINote.note(drum:hits.first?.noteID ?? "")
    }
     
    var vel_low: Int = 0
    var vel_high: Int = 0
    var hits = [Hit]()
    func header(micID: String) -> Header {
        let header = Header()
        header.type = .group
        
        // codes
        var codes = header.opcodes
        codes.append(.pitch_keycenter(note.number))
        codes.append(.seq_length(hits.count))
        codes.append(.lovel(vel_low))
        codes.append(.hivel(vel_high))
        
        // any subheaders
        
        for (i, hit) in hits.enumerated() {
            let subheader = Header()
            header.subheaders.append(subheader)
            
            var codes = subheader.opcodes
            subheader.type = .region
            codes.append(.seq_position(i))
            let sample = hit.samples[micID]
            let filename = sample!.file.parent!.name + "/" + sample!.file.name
            codes.append(OpCode.sample(filename))
        }
        
        return header
    }
}
