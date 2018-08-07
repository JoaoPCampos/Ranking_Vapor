//
//  GameController.swift
//  App
//
//  Created by João Campos on 01/08/2018.
//

import Vapor
import Crypto
import Foundation

final class GameController {

    static func create(_ request: Request) throws -> Future<Game.Public> {

        guard let contenderId = request.query[UUID.self, at: "id"] else {
            throw Abort(.badRequest, reason: "Missing contender id")
        }

        return try request
            .content
            .decode(Game.Create.self)
            .map({ game -> Future<Game> in
                return try create(game: game, versus: contenderId, request)
            }).flatMap({ (newGame) -> EventLoopFuture<Game.Public> in
                return newGame.convertToPublic()
            })
    }

    static func accept(_ request: Request) throws -> Future<Game.Public> {
        let player = try request.requireAuthenticated(Player.self)

        return Game
            .query(on: request)
            .all()
            .map({ games -> Game in
                guard let game = games.filter({ $0.contenderEmail == player.email }).first else {
                    throw Abort(.unauthorized, reason: "\(player.username) is not able to accept challenge")
                }

                
                let acceptedGame = Game(id: game.id,
                                        name: game.name,
                                        challengerEmail: game.challengerEmail,
                                        contenderEmail: game.contenderEmail,
                                        challenger: game.challenger,
                                        contender: game.contender,
                                        status: GameStatus.accepted.rawValue)
                return acceptedGame
            })
            .update(on: request).convertToPublic()
    }

    static func list(_ request: Request) throws -> Future<[Game.Public]> {
        let player = try request.requireAuthenticated(Player.self)

        return Game
            .query(on: request)
            .all()
            .map({ games -> [Game.Public] in
                return games
                    .filter({ $0.challengerEmail == player.email || $0.contenderEmail == player.email})
                    .map({ return $0.convertToPublic() })
            })
    }

//    static func winner(_ request: Request) throws -> Future<HTTPStatus> {
//        return try update(request, isWinner: true)
//    }
//
//    static func loser(_ request: Request) throws -> Future<HTTPStatus> {
//        return try update(request, isWinner: false)
//    }
}

extension GameController {

    private static func create(game: Game.Create, versus contenderId: UUID, _ request: Request) throws -> Future<Game> {
        let player = try request.requireAuthenticated(Player.self)

        guard player.id != contenderId else {
            throw Abort(.conflict, reason: "Challenger \(player.username) must be different from contender.")
        }

        return try PlayerController
            .getPlayer(request, byId: contenderId)
            .map({ contender -> Game in
                return Game(name: game.name,
                            challengerEmail: player.email,
                            contenderEmail: contender.email,
                            challenger: player.username,
                            contender: contender.username)
            }).create(on: request)
    }

//    private static func update(_ request: Request, isWinner: Bool) throws -> Future<HTTPStatus> {
//        let player = try request.requireAuthenticated(Player.self)
//
//        return Game
//            .query(on: request)
//            .all()
//            .map({ games -> Game in
//                guard let game = games.filter({ $0.challengerEmail == player.email }).first else {
//                    throw Abort(.unauthorized, reason: "\(player.username) is not able to update challenge")
//                }
//
//                let updatedGame = Game(id: game.id,
//                                       name: game.name,
//                                       challengerEmail: game.challengerEmail,
//                                       contenderEmail: game.contenderEmail,
//                                       challenger: game.challenger,
//                                       contender: game.contender,
//                                       status: GameStatus.completed.rawValue)
//
//                return updatedGame
//            })
//            .update(on: request)
//            .flatMap({ game -> EventLoopFuture<HTTPStatus> in
//                return try updateElo(request, game: game, isWinner: isWinner)
//            })
//    }

//    static func updateElo(_ request: Request, game: Game, isWinner: Bool) throws -> Future<HTTPStatus> {
//        let player = try request.requireAuthenticated(Player.self)
//
//        return try PlayerController
//            .getPlayer(request, byId: game.)
//            .flatMap({ (contender) -> EventLoopFuture<Player> in
//                let contenderRating = Rating(currentElo: CGFloat(contender.elo), winner: !isWinner)
//
//                let updatedContender = Player(username: contender.username,
//                                              email: contender.email,
//                                              password: contender.password,
//                                              elo: contenderRating.calculate(versusElo: player.elo),
//                                              wins: contender.wins,
//                                              losses: contender.losses)
//                return updatedContender.update(on: request)
//                    .flatMap({ newContender -> EventLoopFuture<Player> in
//
//                        let meRating = Rating(currentElo: CGFloat(player.elo), winner: isWinner)
//
//                        let updatedMe = Player(username: player.username,
//                                               email: player.email,
//                                               password: player.password,
//                                               elo: meRating.calculate(versusElo: contender.elo),
//                                               wins: player.wins,
//                                               losses: player.losses)
//                        return updatedMe.update(on: request)
//                    })
//            }).transform(to: .ok)
//    }
}
