import Vapor
import Fluent

public final class Point: Content, Model {
  public init() {}

  public static let schema = "points"

  @ID(key: .id)
  public var id: UUID?

  @Parent(key: "track_id")
  var track: Track

  @Field(key: "latitude")
  var latitude: Double

  @Field(key: "longitude")
  var longitude: Double

  @Field(key: "date")
  var date: Date

  init(time: Date, latutude: Double, longitude: Double, trackID: Track.IDValue) {
    self.date = time
    self.latitude = latutude
    self.longitude = longitude
    self.$track.id = trackID
  }
}

final class Track: Model, Content {
  init() {
    maxLatitude = -10000
    maxLongitude = -10000
    minLatitude = 10000
    minLongitude = 10000
  }

  static let schema = "tracks"

  @ID(key: .id)
  var id: UUID?

  @Children(for: \.$track)
  var points: [Point]

  @Field(key: "max_latitude")
  var maxLatitude: Double

  @Field(key: "max_longitude")
  var maxLongitude: Double

  @Field(key: "min_latitude")
  var minLatitude: Double

  @Field(key: "min_longitude")
  var minLongitude: Double

}
