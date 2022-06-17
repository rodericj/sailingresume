import Fluent
import Vapor

final class FeaturesResponse: Content {
  let type: String
  let features: [Feature]
}
final class Feature: Content {
  let id: String
  let type: String
}

final class ErrorResponse: Content {
  let message: String
}
struct DatasetReferenceController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let tracks = routes.grouped("datasetReferences")
    tracks.get(use: index)
    tracks.put(":datasetReferenceID", use: populate)
    tracks.post(use: create)
    tracks.group(":datasetReferenceID") { track in
      track.delete(use: delete)
    }
  }

  func populate(req: Request) async throws -> HTTPStatus{
    let datasetReferenceID = req.parameters.get("datasetReferenceID")!
    let url = URI(string:"https://api.mapbox.com/datasets/v1/roderic/\(datasetReferenceID)/features/")
    print(url)
    let response = try await req.client.get(url) { req in
      // Encode access token query string to the request URL
      let accessToken = "abc"
      try req.query.encode(["access_token": accessToken])
    }
    do {
      let json = try response.content.decode(FeaturesResponse.self)
      print(json)
      for feature in json.features {
        print(feature.type)
      }
    } catch {
      print("There was an error \(error)")
      print(response)
      let errorResponse = try response.content.decode(ErrorResponse.self)
      print(errorResponse.message)
    }
    return response.status
  }

  func index(req: Request) async throws -> [DatasetReference] {
    try await DatasetReference.query(on: req.db).all()
  }

  func create(req: Request) async throws -> DatasetReference {
    let track = try req.content.decode(DatasetReference.self)
    try await track.save(on: req.db)
    return track
  }

  func delete(req: Request) async throws -> HTTPStatus {
    guard let datasetReference = try await DatasetReference.find(req.parameters.get("datasetReferenceID"), on: req.db) else {
      throw Abort(.notFound)
    }
    try await datasetReference.delete(on: req.db)
    return .noContent
  }
}

