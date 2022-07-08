import Fluent
import Vapor
import CoreGPX
import ZIPFoundation

struct GeoJsonResponse: Content {
  struct Feature: Content {
    struct Geometry: Content {
      var properties: [String: String] = [:]
      var type: String = "LineString"
      let coordinates: [[Double]]
    }
    var properties: [String: String] = [:]
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
      .map { point -> [Double] in
        return [point.longitude, point.latitude]
      }
    return .init(features: [.init(geometry: .init(coordinates: coordinatePairs))])
  }
}

struct TrackController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {

    // authenticated requests
    let protected = routes.grouped(UserAuthenticator())
    protected.on(.POST, "upload", body: .collect(maxSize: "10mb"), use: create)
    protected.on(.POST, "bulkUpload", body: .collect(maxSize: "10mb"), use: bulkCreate)

    // public requests
    let tracks = routes.grouped("tracks")
    tracks.get(use: index)
    tracks.group(":trackID") { track in
      track.get("geojson", use: geojson)
      track.get(use: detail)

      let authenticatedActionsOnASpecificTrack = track
        .grouped(UserAuthenticator())
        .grouped(User.guardMiddleware())
      authenticatedActionsOnASpecificTrack.delete(use: delete)
      authenticatedActionsOnASpecificTrack.post("delete", use: deleteFromWeb)
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

  func index(req: Request) async throws -> Page<Track> {
    try await Track.query(on: req.db).paginate(for: req)
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

  private func unzip(req: Request, source: URL, dest: URL) throws -> EventLoopFuture<Void> {
    let fileManager = FileManager()
    try fileManager.unzipItem(at: source, to: dest)
    return req.eventLoop.future()
  }

  private func findGPXFilesAndExtract(req: Request, dest: URL) -> EventLoopFuture<Void>{
    let fileManager = FileManager()
    do {
      let contents = try fileManager.contentsOfDirectory(atPath: dest.path)
      return contents.filter { filePath in
        filePath.hasSuffix(".gpx")
      }.map { gpxFile in
        var gpxFileURL = dest
        gpxFileURL.appendPathComponent(gpxFile)
        return req.extractDataFromGPX(at: gpxFileURL.path).flatMap { _ in
          do {
            try fileManager.removeItem(at: gpxFileURL)
          } catch {
            return req.eventLoop.future(error: error)
          }
          return req.eventLoop.future()
        }
      }.flatten(on: req.eventLoop)
    } catch {
      return req.eventLoop.makeFailedFuture(error)
    }
  }

  func bulkCreate(req: Request) throws -> EventLoopFuture<HTTPResponseStatus> {
    // Need to do the file upload here
    let key = try req.query.get(String.self, at: "key")
    let path = req.application.directory.publicDirectory + key
    let sourceURL = URL(fileURLWithPath: path)
    var destURL = sourceURL
    destURL.deleteLastPathComponent()

    return req.body.collect()
      .unwrap(or: Abort(.noContent))
      .flatMap({ byteBuffer in
        req.fileio.writeFile(byteBuffer, at: path)
      })
      .flatMapThrowing({ _ in
        try unzip(req: req, source: sourceURL, dest: destURL)
      })
      .flatMap({ _ -> EventLoopFuture<Void> in
        findGPXFilesAndExtract(req: req, dest: destURL)
      })
      .map { HTTPStatus.accepted }
  }

  func deleteFromWeb(_ req: Request) async throws -> Response {
    guard let track = try await Track.find(req.parameters.get("trackID"), on: req.db) else {
      return Response(status: .badRequest)
    }
    try await track.delete(on: req.db)
    return req.redirect(to: "/", type: .permanent)
  }

  func delete(req: Request) async throws -> HTTPStatus {
    guard let track = try await Track.find(req.parameters.get("trackID"), on: req.db) else {
      throw Abort(.notFound)
    }
    try await track.delete(on: req.db)
    return .noContent
  }
}
