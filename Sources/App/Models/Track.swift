import Vapor
import CoreLocation
import Fluent

public final class Point: Content, Model {
  public init() {}

  public static let schema = "point"

  @ID(key: .id)
  public var id: UUID?

  @Field(key: "latitude")
  var latitude: Double

  @Field(key: "longitude")
  var longitude: Double

  @Field(key: "time")
  var time: Date

  init(time: Date, latutude: Double, longitude: Double) {
    self.time = time
    self.latitude = latutude
    self.longitude = longitude
  }
}

final class Track: Model, Content {
  init() {}
  
  static let schema = "track"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "points") // this should be a reference to another type not a field
  var points: [Point]

}
