import Vapor
struct UserController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.post("users", use: createUser)
    routes
      .grouped(User.authenticator())
      .post("login", use: login)
    guard let app = routes as? Application else {
      return
    }

    routes
      .grouped([
        UserToken.authenticator(),
        UserSessionAuthenticator(),
        app.sessions.middleware,
        UserBearerAuthenticator(),
        User.guardMiddleware()
      ])
      .get("me", use: me)
  }

  func me(_ req: Request) async throws -> User {
    try req.auth.require(User.self)
  }

  func login(_ req: Request) async throws -> UserToken {
    let user = try req.auth.require(User.self)
    let token = try user.generateToken()
    try await token.save(on: req.db)
    return token
  }

  func createUser(_ req: Request) async throws -> User {
    try User.Create.validate(content: req)
    let create = try req.content.decode(User.Create.self)
    guard create.password == create.confirmPassword else {
        throw Abort(.badRequest, reason: "Passwords did not match")
    }
    let user = try User(
        name: create.name,
        email: create.email,
        passwordHash: Bcrypt.hash(create.password)
    )
    try await user.save(on: req.db)
    return user
  }
}
