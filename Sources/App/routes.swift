import Fluent
import Vapor

struct IndexBody: Content {
  let title: String
  let activities: [Activity]
}

func routes(_ app: Application) throws {
  app.get { req async throws -> View in
    let activities = try await Activity.query(on: req.db).all()
    let body = IndexBody(title: "Sailing Events", activities: activities)
    return try await req.view.render("index", body)
  }
  app.routes.defaultMaxBodySize = "10mb"

  let trackController = TrackController()
  app.on(.POST, "upload", body: .collect(maxSize: "10mb"), use:trackController.create)
  try app.register(collection: TodoController())
  try app.register(collection: ActivityController())
  try app.register(collection: DatasetReferenceController())
  try app.register(collection: trackController)
}
