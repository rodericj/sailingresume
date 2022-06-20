import Fluent
import Vapor
import CoreGPX

struct GeoJsonResponse: Content {
  struct Feature: Content {
    struct Geometry: Content {
      var type: String = "LineString"
      let coordinates: [[Double]]
    }
    var type: String = "Feature"
    let geometry: Geometry
  }
  var type: String = "FeatureCollection"
  let features: [Feature]
}

extension Track {
  var geoJson: GeoJsonResponse {
    let coordinatePairs = self.points
      .sorted(by: { a, b in
        a.date < b.date
      })
      .map({ point in
      return [point.longitude, point.latitude]
    })
    return .init(features: [.init(geometry: .init(coordinates: coordinatePairs))])
  }
}

struct TrackController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let tracks = routes.grouped("tracks")
    tracks.get(use: index)
    tracks.group(":trackID") { track in
      track.delete(use: delete)
      track.get("geojson", use: geojson)
    }
  }

  func geojson(req: Request) async throws -> GeoJsonResponse {
    guard let track = try await Track.find(req.parameters.get("trackID"), on: req.db) else {
      throw Abort(.notFound)
    }
    try await track.$points.load(on: req.db)

    return track.geoJson
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
    return track.create(on: self.db).flatMap ({ _ in
      return track.addPoints(from: parser, on: self)
    })
  }
}

extension Track {
  func addPoints(from parsedData: GPXRoot, on req: Request) -> EventLoopFuture<Void> {
    let points = parsedData.tracks.first?.segments.first?.points.compactMap({ waypoint -> PointEnvelope? in
      guard let time = waypoint.time, let latitude = waypoint.latitude, let longitude = waypoint.longitude else { return nil }
      return PointEnvelope(date: time, latitude: latitude, longitude: longitude)
    }) ?? []
    let jobs = points.chunks(ofCount: 2000).map { chunk in
      Array(chunk)
    }.map { chunk -> EventLoopFuture<Void> in
      req
        .queue
        .dispatch(TrackCreationJob.self, TrackPointsCreationTask(points: chunk, track: self))
    }.flatten(on: req.eventLoop)
    return jobs
  }
}
