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
      track.get(use: detail)
    }
  }

  func geojson(req: Request) async throws -> GeoJsonResponse {
    guard let track = try await Track.find(req.parameters.get("trackID"), on: req.db) else {
      throw Abort(.notFound)
    }
    try await track.$points.load(on: req.db)

    return track.geoJson
  }

  func detail(req: Request) async throws -> View {
    guard let track = try await Track.find(req.parameters.get("trackID"), on: req.db) else {
      throw Abort(.notFound)
    }
    let body = IndexBody(title: "Sailing Events", tracks: [track])
    return try await req.view.render("detail", body)

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
