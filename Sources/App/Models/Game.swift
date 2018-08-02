//
//  Game.swift
//  App
//
//  Created by João Campos on 31/07/2018.
//

import Vapor
import Foundation
import FluentSQLite

enum GameStatus: Int {
    case pending = 0
    case accepted
    case completed
    case aborted
}

final class Game: Codable {
    var id: Int?
    var challengerId: String
    let contenderId: String
    let name: String
    let challenger: String
    let contender: String
    let status: Int
    
    init(name: String, challengerId: String, contenderId: String, challenger: String, contender: String, status: Int = GameStatus.pending.rawValue) {
        self.name = name
        self.challengerId = challengerId
        self.contenderId = contenderId
        self.challenger = challenger
        self.contender = contender
        self.status = status
    }

    final class Create: Codable {
        let name: String

        init(name: String, contenderId: String) {
            self.name = name
        }
    }
    
    final class Public: Codable {
        let name: String
        let challenger: String
        let contender: String
        let status: Int
        
        init(name: String, challenger: String, contender: String, status: Int) {
            self.name = name
            self.challenger = challenger
            self.contender = contender
            self.status = status
        }
    }
}

extension Game: Model {
    typealias Database = SQLiteDatabase
    typealias ID = Int
    public static var idKey: IDKey = \Game.id
}
extension Game: Content {}
extension Game: Parameter {}
extension Game: Migration {}

extension Game.Public: Content {}

extension Game {
    func convertToPublic() -> Game.Public {
        return Game.Public(name: name, challenger: challenger, contender: contender, status: status)
    }
}

extension Future where T: Game {
    func convertToPublic() -> Future<Game.Public> {
        return self.map(to: Game.Public.self) { game in
            return game.convertToPublic()
        }
    }
}