import Fluent

struct CreateDatasetReference: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("datasetreferences")
            .id()
            .field("datasetID", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("datasetreferences").delete()
    }
}
