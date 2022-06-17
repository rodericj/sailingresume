import Fluent
import Vapor

struct ActivityController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let activities = routes.grouped("activities")
    activities.get(use: index)
    activities.post(use: create)
    activities.group(":activityID") { todo in
      todo.delete(use: delete)
    }
  }

    func index(req: Request) async throws -> [Activity] {
        try await Activity.query(on: req.db).all()
    }

    func create(req: Request) async throws -> Activity {
        let activity = try req.content.decode(Activity.self)
        try await activity.save(on: req.db)
        return activity
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let activity = try await Activity.find(req.parameters.get("activityID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await activity.delete(on: req.db)
        return .noContent
    }
}

