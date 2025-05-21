//
//  Config.swift
//  closeup
//
//  Created by Weston Cadena on 5/15/25.
//

import Foundation

enum Config {
    static let googleClientId: String = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
            fatalError("GIDClientID not found in Info.plist")
        }
        return value
    }()
    
    static let supabaseUrl: String = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SupabaseUrl") as? String else {
            fatalError("SupabaseUrl not found in Info.plist")
        }
        return value
    }()
    
    static let supabaseAnonKey: String = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String else {
            fatalError("SupabaseAnonKey not found in Info.plist")
        }
        return value
    }()
} 