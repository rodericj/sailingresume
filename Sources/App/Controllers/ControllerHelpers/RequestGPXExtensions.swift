import CoreGPX
import Vapor

enum TrackError: Error {
  case FileNotWrittenToOrNotFound
}

extension Request {
  func extractDataFromGPX(at path: String) -> EventLoopFuture<Void> {
    guard let parser = GPXParser(withPath: path )?.parsedData() else {
      return eventLoop.makeFailedFuture(TrackError.FileNotWrittenToOrNotFound)
    }
    let track = Track()
    track.title = parser.tracks.first?.name ?? ""
    return track.create(on: self.db).flatMap ({ _ in
      return track.addPoints(parser.points, on: self)
    })
  }
}

extension GPXRoot {
  var points: [PointEnvelope] {
    return tracks.first?.segments.first?.points.compactMap({ waypoint -> PointEnvelope? in
      guard let time = waypoint.time, let latitude = waypoint.latitude, let longitude = waypoint.longitude else { return nil }
      return PointEnvelope(date: time, latitude: latitude, longitude: longitude)
    }) ?? []
  }
}
