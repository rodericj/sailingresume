import Fluent

struct CreateTracks: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("tracks")
            .id()
            .create()

    }
  func revert(on database: Database) async throws {
      try await database.schema("tracks").delete()
  }
}

struct CreatePoints: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("points")
            .id()
            .field("track_id", .uuid, .required, .references("tracks", "id"))
            .field("date", .datetime, .required)
            .field("latitude", .float, .required)
            .field("longitude", .float, .required)
            .create()
    }
  func revert(on database: Database) async throws {
      try await database.schema("points").delete()
  }
}