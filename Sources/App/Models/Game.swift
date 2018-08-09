//
//  Game.swift
//  App
//
//  Created by João Campos on 31/07/2018.
//

import Vapor
import Foundation
import FluentSQLite
//import FluentPostgreSQL

final class Game: Codable {
    var id: UUID?
    let name: String

    /// Relation 1 Game for * PlayerStats
    var playerStats: Children<Game, PlayerStats> {
        return children(\PlayerStats.gameId)
    }

    /// Relation 1 Game for * Matches
    var matches: Children<Game, Match> {
        return children(\Match.gameId)
    }

    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

extension Game: Migration {
    static func prepare(on connection: SQLiteConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.unique(on: \Game.name)
        } }
}

extension Game: SQLiteUUIDModel {}
extension Game: Content {}
extension Game: Parameter {}
