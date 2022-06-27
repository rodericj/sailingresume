import Vapor
import Fluent

struct UserAuthenticator: AsyncBearerAuthenticator {
    typealias User = App.User

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) async throws {
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

