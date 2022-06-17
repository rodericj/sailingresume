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

  init() { }

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
