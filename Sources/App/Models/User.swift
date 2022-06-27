import Fluent
import Vapor

final class User: Model, Content, Authenticatable {
  init() {}

  static let schema = "users"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "name")
  var name: String

  @Field(key: "email")
  var email: String

  @Field(key: "password_hash")
  var passwordHash: String

  init(id: UUID? = nil, name: String, email: String, passwordHash: String) {
      self.id = id
      self.name = name
      self.email = email
      self.passwordHash = passwordHash
  }

}

extension User: ModelAuthenticatable, ModelCredentialsAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

extension User {
    func generateToken() throws -> UserToken {
        try .init(
            value: [UInt8].random(count: 16).base64,
            userID: self.requireID()
        )
    }
}

extension User: ModelSessionAuthenticatable {}
