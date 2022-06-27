import Fluent
import FluentPostgresDriver
import Leaf
import Vapor
import QueuesFluentDriver

// configures your application
public func configure(_ app: Application) throws {
  // uncomment to serve files from /Public folder
  // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

  app.databases.use(.postgres(
    hostname: Environment.get("DATABASE_HOST") ?? "localhost",
    port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
    username: Environment.get("DATABASE_USERNAME") ?? "roderic",
    password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
    database: Environment.get("DATABASE_NAME") ?? "sailingresume"
  ), as: .psql)

  let decoder = JSONEncoder()
  decoder.dateEncodingStrategy = .secondsSince1970
  ContentConfiguration.global.use(encoder: decoder, for: .html)

  app.migrations.add(CreateTracks())
  app.migrations.add(CreatePoints())
  app.migrations.add(JobModelMigrate())
  app.migrations.add(CreateUser())
  app.migrations.add(CreateUserToken())

  app.middleware.use(app.sessions.middleware)
  app.middleware.use(User.sessionAuthenticator())

  let trackJob = TrackCreationJob()
  app.queues.add(trackJob)

  app.queues.use(.fluent())

  try app.queues.startInProcessJobs(on: .default)

  app.views.use(.leaf)

  // register routes
  try routes(app)
}
