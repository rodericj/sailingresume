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
    if bearer.token == "PXa4W1B8PwtulijcIj5jSg==" {
      let user = User(name: "", email: "hello@vapor.codes", passwordHash: "")
      request.auth.login(user)
    }
  }
}
