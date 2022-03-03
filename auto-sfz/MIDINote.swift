//
//  Note.swift
//  auto-sfz
//
//  Created by Chris Maier on 2/22/20.
//  Copyright © 2020 Chris Maier. All rights reserved.
//
 

enum MIDINote {
    static func note(drum: String) -> MIDINote {
        switch drum {
        case "snare": return D(1)
        case "floor": return F(1)
        case "kick": return C(1)
        case "ride": return C_sharp(2)
        case "crash": return D_sharp(2)
        case "hi": return F_sharp(1)
        default: return C(100)
        }
    }
    
    static func note(input: String) -> MIDINote? { 
        var iterator: String = input
        guard let first = iterator.first else { return nil }
        var noteName: String = String(first)
        iterator.removeFirst()
        if iterator.first == "#" {
            noteName.append("#")
            iterator.removeFirst()
        }
        guard let octave_char = iterator.first else { return nil }
        guard let octave: Int = Int(String(octave_char)) else { return nil }
        
        switch noteName {
        case "C": return C(octave)
        case "C#": return C_sharp(octave)
        case "D": return D(octave)
        case "D#": return D_sharp(octave)
        case "E": return E(octave)
        case "F": return F(octave)
        case "F#": return F_sharp(octave)
        case "G": return G(octave)
        case "G#": return G_sharp(octave)
        case "A": return A(octave)
        case "A#": return A_sharp(octave)
        case "B": return B(octave)
        default: return C(100)
        }
    }
    
    static let all =  [C(0), D(0), E(0), F(0), G(0), A(0), B(0)]
    
    case C(_ octave: Int)
    case C_sharp(_ octave: Int)
    case D(_ octave: Int)
    case D_sharp(_ octave: Int)
    case E(_ octave: Int)
    case F(_ octave: Int)
    case F_sharp(_ octave: Int)
    case G(_ octave: Int)
    case G_sharp(_ octave: Int)
    case A(_ octave: Int)
    case A_sharp(_ octave: Int)
    case B(_ octave: Int)
    
    var string: String {
        switch self {
        case .C(let octave): return "\(self.noteName)\(octave)"
        case .C_sharp(let octave): return "\(self.noteName)\(octave)"
        case .D(let octave): return "\(self.noteName)\(octave)"
        case .D_sharp(let octave): return "\(self.noteName)\(octave)"
        case .E(let octave): return "\(self.noteName)\(octave)"
        case .F(let octave): return "\(self.noteName)\(octave)"
        case .F_sharp(let octave): return "\(self.noteName)\(octave)"
        case .G(let octave): return "\(self.noteName)\(octave)"
        case .G_sharp(let octave): return "\(self.noteName)\(octave)"
        case .A(let octave): return "\(self.noteName)\(octave)"
        case .A_sharp(let octave): return "\(self.noteName)\(octave)"
        case .B(let octave): return "\(self.noteName)\(octave)"
        }
    }
    
    var octave: Int {
        switch self {
        case .C(let octave): return octave
        case .C_sharp(let octave): return octave
        case .D(let octave): return octave
        case .D_sharp(let octave): return octave
        case .E(let octave): return octave
        case .F(let octave): return octave
        case .F_sharp(let octave): return octave
        case .G(let octave): return octave
        case .G_sharp(let octave): return octave
        case .A(let octave): return octave
        case .A_sharp(let octave): return octave
        case .B(let octave): return octave
        }
    }
    
    var noteName: String {
        switch self {
        case .C: return "C"
        case .C_sharp: return "C#"
        case .D: return "D"
        case .D_sharp: return "D#"
        case .E: return "E"
        case .F: return "F"
        case .F_sharp: return "F#"
        case .G: return "G"
        case .G_sharp: return "G#"
        case .A: return "A"
        case .A_sharp: return "A#"
        case .B: return "B"
        }
    }
    var offset: Int {
        switch self {
        case .C: return 0
        case .C_sharp: return 1
        case .D: return 2
        case .D_sharp: return 3
        case .E: return 4
        case .F: return 5
        case .F_sharp: return 6
        case .G: return 7
        case .G_sharp: return 8
        case .A: return 9
        case .A_sharp: return 10
        case .B: return 11
        }
    }
    
    var number: Int {
        return 24 + offset + self.octave * 12
    }
}
