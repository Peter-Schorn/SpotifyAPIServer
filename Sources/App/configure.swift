import Vapor

// configures your application
public func configure(_ app: Application) throws {

    if app.environment == .development {
        // `RedirectListener` already uses 8080
        app.http.server.configuration.port = 7000
    }

    // register routes
    try routes(app)

}
