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


  app.migrations.add(CreateTracks())
  app.migrations.add(CreatePoints())
  app.migrations.add(JobModelMigrate())

  let trackJob = TrackCreationJob()
  app.queues.add(trackJob)

  app.queues.use(.fluent())

  try app.queues.startInProcessJobs(on: .default)
//  try app.queues.startScheduledJobs()

  app.views.use(.leaf)

  // register routes
  try routes(app)
}
