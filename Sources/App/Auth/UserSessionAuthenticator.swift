import Fluent
import Vapor

struct UserSessionAuthenticator: AsyncSessionAuthenticator {
  typealias User = App.User
  func authenticate(sessionID: UUID, for request: Request) async throws {
    let user = User(id: sessionID, name: "", email: "", passwordHash: "")
    request.auth.login(user)
  }
}

struct UserBearerAuthenticator: AsyncBearerAuthenticator {
  func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
    guard let user = try await UserToken.query(on: request.db)
      .filter(\.$value == bearer.token)
      .with(\.$user)
      .first()?
      .user else {
      throw Abort(.unauthorized)
    }
    request.auth.login(user)
  }
}
