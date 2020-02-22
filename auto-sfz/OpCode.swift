//
//  OpCode.swift
//  auto-sfz
//
//  Created by Chris Maier on 2/22/20.
//  Copyright © 2020 Chris Maier. All rights reserved.
//

enum OpCode {
    case sample(_ value: String)
    case key(_ value: Int)
    case seq_position(_ value: Int)
    case seq_length(_ value: Int)
    
    case lokey(_ value: Int)
    case hikey(_ value: Int)
    case pitch_keycenter(_ value: Int)
    
    case lovel(_ value: Int)
    case hivel(_ value: Int)
    case loop_mode(_ value: LoopMode)
    case offset(_ value: Int)
    
    var string: String {
        switch self {
        case .seq_position(let val):    return "seq_position=\(val)"
        case .seq_length(let val):      return "seq_length=\(val)"
        case .key(let val):             return "key=\(val)"
        case .lokey(let val):           return "lokey=\(val)"
        case .hikey(let val):           return "hikey=\(val)"
        case .pitch_keycenter(let val): return "pitch_keycenter=\(val)"
        case .lovel(let val):           return "lovel=\(val)"
        case .hivel(let val):           return "hivel=\(val)"
        case .sample(let val):          return "sample=\(val)"
        case .loop_mode(let val):       return "sample=\(val.string)"
        case .offset(let val):          return "offset=\(val)"
        }
    }
}

enum LoopMode {
    case one_shot
    var string: String {
        switch self {
        case .one_shot: return "one_shot"
        }
    }
}

