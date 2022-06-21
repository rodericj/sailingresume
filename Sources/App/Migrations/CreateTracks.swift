import Fluent

struct CreateTracks: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("tracks")
            .id()
            .field("max_longitude", .double)
            .field("min_longitude", .double)
            .field("max_latitude", .double)
            .field("min_latitude", .double)
            .field("start_date", .date)
            .field("end_date", .date)
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
            .field("track_id", .uuid, .required, .references("tracks", "id", onDelete: .cascade))
            .field("date", .datetime, .required)
            .field("latitude", .double, .required)
            .field("longitude", .double, .required)
            .create()
    }
  func revert(on database: Database) async throws {
      try await database.schema("points").delete()
  }
}
