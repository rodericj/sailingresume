import Fluent
import Vapor

final class DatasetReference: Model, Content {
  static let schema = "datasetreferences"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "datasetID")
  var datasetID: String

  init() { }

  init(id: UUID? = nil, datasetID: String) {
    self.id = id
    self.datasetID = datasetID
  }
}
