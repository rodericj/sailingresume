import Fluent
import Vapor
import CoreGPX

struct TrackController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let tracks = routes.grouped("tracks")
    tracks.get(use: index)
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
    //    req.fileio.writeFile($0, at: path)
    return req.body.collect()
      .unwrap(or: Abort(.noContent))
      .flatMap({ byteBuffer in
        req.fileio.writeFile(byteBuffer, at: path)
      })
      .flatMap({ _ in
        req.extractDataFromGPX(at: path)
      })
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

enum TrackError: Error {
  case FileNotWrittenToOrNotFound
}

extension Request {
  fileprivate func extractDataFromGPX(at path: String) -> EventLoopFuture<Void> {
    guard let parser = GPXParser(withPath: path )?.parsedData() else {
      return eventLoop.makeFailedFuture(TrackError.FileNotWrittenToOrNotFound)
    }
    let track = Track()
    return track.save(on: self.db).flatMap ({ _ in
      return track.addPoints(from: parser, on: self)
    })
  }
}

extension Track {
  func addPoints(from parsedData: GPXRoot, on req: Request) -> EventLoopFuture<Void> {
    let points = parsedData.tracks.first?.segments.first?.points.compactMap({ waypoint -> Point? in
      guard let time = waypoint.time, let latitude = waypoint.latitude, let longitude = waypoint.longitude else { return nil }
      return Point(time: time, latutude: latitude, longitude: longitude)
    }) ?? []
    print(points.count)

    let firstFew = points[0...1000] // TODO create a job to batch these up
    return self.$points.create(Array(firstFew), on: req.db).flatMap { _ in
      self.save(on: req.db)
    }
  }
}
