# SpotifyAPIServer

**A server that handles the process of retrieving the authorization information and refreshing tokens for the Spotify web API on behalf of your frontend app. Supports the [Client Credentials Flow](https://developer.spotify.com/documentation/general/guides/authorization-guide/#client-credentials-flow),  [Authorization Code Flow](https://developer.spotify.com/documentation/general/guides/authorization-guide/#authorization-code-flow), and  [Authorization Code Flow with Proof Key for Code Exchange](https://developer.spotify.com/documentation/general/guides/authorization-guide/#authorization-code-flow-with-proof-key-for-code-exchange-pkce)**

Can be run as a local server directly from Xcode.

## Environment

Requires the following environment variables:

* `SPOTIFY_SWIFT_TESTING_CLIENT_ID`: Your client id from Spotify.

* `SPOTIFY_SWIFT_TESTING_CLIENT_SECRET`: Your client secret from Spotify.

* `REDIRECT_URI`: The URL that Spotify will redirect to after the user logs in to their account.

* `SECRET_KEY`: A randomly generated string that is used to generate a key for encryption. No specific length is required, but generally it should be at least 20 characters. **Warning**: If you change this value, then any previously-retrieved authorization information will be invalidated.
* `LOG_LEVEL`: Not required, but can be used to change the log level of the loggers used by Vapor. See [here](https://docs.vapor.codes/4.0/logging/#level) for more information.

## Deploying to Heroku

This server is pre-configured for deployment to [Heroku](https://www.heroku.com/about) (although any platform can be used).

First, sign up for a Heroku account, install the command-line tool, login, and create a Heroku application, as described [here](https://docs.vapor.codes/4.0/deploy/heroku/). Set your working directory to this package and run the following command:

```
heroku git:remote -a [app name]
```

where `app name` is the name of the application that you just created on Heroku. Next, set the buildpack to teach heroku how to deal with vapor:

```
heroku buildpacks:set vapor/vapor
```

Finally, deploy to Heroku by running the following:

```
git push heroku main
```

See [here](https://devcenter.heroku.com/articles/config-vars#using-the-heroku-dashboard) for how to configure the environment variables as described above on heroku.

