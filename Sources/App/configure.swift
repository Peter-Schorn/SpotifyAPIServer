import Vapor

// configures your application
public func configure(_ app: Application) throws {

    if [.development, .testing].contains(app.environment) {
        // `RedirectListener` already uses 8080
       app.http.server.configuration.port = 7000
    }

    // register routes
    try routes(app)


}
