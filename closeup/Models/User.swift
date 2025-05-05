//
//  User.swift
//  closeup
//
//  Created by Weston Cadena on 5/4/25.
//

import Foundation

struct User: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var profileImage: String // URL or asset name
}
