import Fluent
import Vapor

final class Activity: Model, Content {
  static let schema = "activities"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "title")
  var title: String

  @Field(key: "date")
  var date: Date

  @Field(key: "datasetID")
  var datasetID: String

  @Field(key: "featureID")
  var featureID: String

  @Field(key: "user")
  var user: String

  @Field(key: "note")
  var note: String

  var geojson: String {
     "https://api.mapbox.com/datasets/v1/\(user)/\(datasetID)/features/\(featureID)?access_token=sk.eyJ1Ijoicm9kZXJpYyIsImEiOiJjbDRoN2R2MnkwMXdkM2NtcHVvaTRjZTI1In0.MFj96n_AhvvYpp3cxS7zCQ"
  }

  init() { }

  func encode(to encoder: Encoder)throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.user, forKey: .user)
    try container.encode(self.title, forKey: .title)
    try container.encode(self.note, forKey: .note)
    try container.encode(self.geojson, forKey: .geojson)
    try container.encode(self.date, forKey: .date)
    try container.encode(self.featureID, forKey: .featureID)
    try container.encode(self.datasetID, forKey: .datasetID)
  }

  enum CodingKeys: String, CodingKey {
    case date, title, featureID, user, note, id, geojson, datasetID
  }

  init(id: UUID? = nil,
       title: String,
       date: Date,
       datasetID: String,
       featureID: String,
       user: String,
       note: String) {
    self.id = id
    self.title = title
    self.date = date
    self.featureID = featureID
    self.datasetID = datasetID
    self.user = user
    self.note = note
  }
}
