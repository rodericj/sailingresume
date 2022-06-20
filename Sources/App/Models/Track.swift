import Vapor
import CoreLocation
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
  init() {}
  
  static let schema = "tracks"

  @ID(key: .id)
  var id: UUID?

  @Children(for: \.$track)
  var points: [Point]

  init(with points: [Point]) {
    self.points = points
  }
}
