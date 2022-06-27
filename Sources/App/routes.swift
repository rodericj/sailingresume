import Fluent
import Vapor

struct IndexBody: Content {
  let title: String
  let tracks: [Track]
  var page: Pagination? = nil
  var pageCount: Int? = nil
  var total: Int? = nil
}

struct Pagination: Content {
  var page: Int = 0
  var per: Int = 0
}
func routes(_ app: Application) throws {
  app
//    .grouped(User.redirectMiddleware(path: "/login?loginRequired=true"))
    .get { req async throws -> View in
    do {
      _ = try req.query.get(Int.self, at: "page")
      _ = try req.query.get(Int.self, at: "per")
    } catch {
      throw Abort.redirect(to: "/?page=1&per=10", type: .permanent)
    }
    let tracksPaginator = try await Track.query(on: req.db).sort(\.$startDate).paginate(for: req)
    let body = IndexBody(
      title: "Sailing Events",
      tracks: tracksPaginator.items.reversed(),
      page: try req.query.decode(Pagination.self),
      pageCount: tracksPaginator.metadata.pageCount,
      total: tracksPaginator.metadata.total
    )
    return try await req.view.render("index", body)
  }
  app.routes.defaultMaxBodySize = "10mb"

  let trackController = TrackController()
  app.on(.POST, "upload", body: .collect(maxSize: "10mb"), use:trackController.create)
  app.on(.POST, "bulkUpload", body: .collect(maxSize: "10mb"), use:trackController.bulkCreate)
  try app.register(collection: trackController)
  try app.register(collection: UserController())
  print(app.routes.all)

}
