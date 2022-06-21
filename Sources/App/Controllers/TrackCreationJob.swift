import Vapor
import Foundation
import Queues

enum TrackJobError: Error {
  case noTrackID
  case trackQueriedAndNotFound
}
struct PointEnvelope: Codable {
  let date: Date
  let latitude: Double
  let longitude: Double
}
struct TrackPointsCreationTask: Codable {
  let points: [PointEnvelope]
  let track: Track
}

struct TrackCreationJob: Job {
  typealias Payload = TrackPointsCreationTask

  func dequeue(_ context: QueueContext, _ payload: TrackPointsCreationTask) -> EventLoopFuture<Void> {
    let track = payload.track
    let db = context.application.db
    let points = payload.points.map { envelope in
      Point(time: envelope.date, latutude: envelope.latitude, longitude: envelope.longitude, trackID: try! track.requireID())
    }
    return points.create(on: db).flatMap { _ in
      return Track.find(track.id, on: db).flatMap { track in
        guard let track = track else {
          return context.eventLoop.makeFailedFuture(TrackJobError.trackQueriedAndNotFound)
        }
        return track.update(on: db)
      }
    }
  }

  func error(_ context: QueueContext, _ error: Error, _ payload: TrackPointsCreationTask) -> EventLoopFuture<Void> {
    // If you don't want to handle errors you can simply return a future. You can also omit this function entirely.
    print("we got an error \(error)")
    return context.eventLoop.future()
  }
}
