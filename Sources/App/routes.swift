import Fluent
import Vapor

struct IndexBody: Content {
  let title: String
  let tracks: [Track]
}

func routes(_ app: Application) throws {
  app.get { req async throws -> View in
    let tracks = try await Track.query(on: req.db).sort(\.$startDate).all()
    let body = IndexBody(title: "Sailing Events", tracks: tracks.reversed())
    return try await req.view.render("index", body)
  }
  app.routes.defaultMaxBodySize = "10mb"

  let trackController = TrackController()
  app.on(.POST, "upload", body: .collect(maxSize: "10mb"), use:trackController.create)
  app.on(.POST, "bulkUpload", body: .collect(maxSize: "10mb"), use:trackController.bulkCreate)
  try app.register(collection: trackController)
  print(app.routes.all)

}
