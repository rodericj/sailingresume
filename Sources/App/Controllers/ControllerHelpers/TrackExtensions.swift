import Vapor

extension Track {
  func addPoints(_ points: [PointEnvelope], on req: Request) -> EventLoopFuture<Void> {
    startDate = points.min { lhs, rhs in
      lhs.date < rhs.date
    }?.date ?? Date()

    endDate = points.max { lhs, rhs in
      lhs.date < rhs.date
    }?.date ?? Date()

    maxLongitude = points.reduce(Double(-100000)) { currentMaxLongitude, point in
      return max(currentMaxLongitude, point.longitude)
    }
    maxLatitude = points.reduce(Double(-100000)) { currentMaxLatitude, point in
      return max(currentMaxLatitude, point.latitude)
    }
    minLongitude = points.reduce(Double(100000)) { currentMinLongitude, point in
      return min(currentMinLongitude, point.longitude)
    }
    minLatitude = points.reduce(Double(100000)) { currentMinLatitude, point in
      return min(currentMinLatitude, point.latitude)
    }
    return self.save(on: req.db).flatMap { _ in
      return points.chunks(ofCount: 2000).map { chunk in
        Array(chunk)
      }.map { chunk -> EventLoopFuture<Void> in
        req
          .queue
          .dispatch(TrackCreationJob.self, TrackPointsCreationTask(points: chunk, track: self))
      }.flatten(on: req.eventLoop)

    }
  }
}
