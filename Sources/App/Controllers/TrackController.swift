import Fluent
import Vapor

struct TrackController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let tracks = routes.grouped("tracks")
    tracks.get(use: index)
//    tracks.post(use: create)
    tracks.group(":trackID") { todo in
      todo.delete(use: delete)
    }
  }

  func index(req: Request) async throws -> [Track] {
    try await Track.query(on: req.db).all()
  }

  func create(req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {
    // Need to do the file upload here
    let key = try req.query.get(String.self, at: "key")
    let path = req.application.directory.publicDirectory + key
    return req.body.collect()
                .unwrap(or: Abort(.noContent))
                .flatMap { req.fileio.writeFile($0, at: path) }
                .map { HTTPStatus.accepted }
  }

  func delete(req: Request) async throws -> HTTPStatus {
    guard let track = try await Track.find(req.parameters.get("trackID"), on: req.db) else {
      throw Abort(.notFound)
    }
    try await track.delete(on: req.db)
    return .noContent
  }
}

