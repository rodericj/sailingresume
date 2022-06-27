import Fluent
import Vapor

struct CreateUser: AsyncMigration {
  var name: String { "CreateUser" }

  func prepare(on database: Database) async throws {
    try await database.schema("users")
      .id()
      .field("name", .string, .required)
      .field("email", .string, .required)
      .field("password_hash", .string, .required)
      .unique(on: "email")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema("users").delete()
  }
}

extension User {
    struct Create: Content {
        var name: String
        var email: String
        var password: String
        var confirmPassword: String
    }
}

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}
