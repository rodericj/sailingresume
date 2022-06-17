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

      let activities: [Activity] = [
        .init(
          title: "test",
          date: Date(),
          datasetID: "cl4g3t9zs007a28paro9jt3mf",
          featureID: "872ed8cfb527f48449cd020886eb1592",
          user: "roderic",
          note: "Well that was fun"),
        .init(title: "Marina Del Rey",
              date: Date(),
              datasetID: "cl4g3t9zs007a28paro9jt3mf",
              featureID: "872ed8cfb527f48449cd020886eb1592",
              user: "roderic",
              note: "We had a really great time sailing. It was one of the better sailing days I've ever had.")
      ]
      for activity in activities {
         try await activity.create(on: database)
        
      }
    }

    func revert(on database: Database) async throws {
        try await database.schema("activities").delete()
    }
}
