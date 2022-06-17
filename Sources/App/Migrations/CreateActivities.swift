import Fluent
import Foundation
struct CreateActivities: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("activities")
            .id()
            .field("title", .string, .required)
            .field("date", .datetime, .required)
            .field("datasetID", .string, .required)
            .field("featureID", .string, .required)
            .field("user", .string, .required)
            .field("note", .string)
            .create()

      let activity = Activity(
        id: nil,
        title: "test",
        date: Date(),
        datasetID: "cl4g3t9zs007a28paro9jt3mf",
        featureID: "872ed8cfb527f48449cd020886eb1592",
        user: "roderic",
        note: "Well that was fun")

      try await activity.create(on: database)
    }

    func revert(on database: Database) async throws {
        try await database.schema("activities").delete()
    }
}
