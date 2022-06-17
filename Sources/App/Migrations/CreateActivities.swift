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
        .init(title: "British Virgin Islands",
              date: Date(),
              datasetID: "cl4g3t9zs007a28paro9jt3mf",
              featureID: "872ed8cfb527f48449cd020886eb1592",
              user: "roderic",
              note: "This was our first time sailing out of BVI. It was one of the most lovely experiences I've ever had. We had perfect weather then entire time and the wind was flawless. No troubles getting out of the dock and anchoring was a breeze. Really loved how we saw so many fish. We had some wonderful food and all of the crew were happy and laughing the entire time."),
        .init(
          title: "Sailing around Catalina",
          date: Date(),
          datasetID: "cl4g3t9zs007a28paro9jt3mf",
          featureID: "872ed8cfb527f48449cd020886eb1592",
          user: "roderic",
          note: "This was our first time sailing around Catalina. Bob and Matt were crew. It was one of the most lovely experiences I've ever had. We had perfect weather then entire time though the wind was a little low. No troubles getting out of the dock and anchoring was a breeze. Really loved how we saw so many fish. We had some wonderful food and all of the crew were happy and laughing the entire time."),
        .init(title: "Daysail in Marina Del Rey",
              date: Date(),
              datasetID: "cl4g3t9zs007a28paro9jt3mf",
              featureID: "872ed8cfb527f48449cd020886eb1592",
              user: "roderic",
              note: "We had a really great time sailing. It was one of the better sailing days I've ever had."),

      ]
      for activity in activities {
         try await activity.create(on: database)
        
      }
    }

    func revert(on database: Database) async throws {
        try await database.schema("activities").delete()
    }
}
