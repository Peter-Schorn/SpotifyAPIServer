# SpotifyAPIServer

**A server that handles the process of retrieving the authorization information and refreshing tokens for the Spotify web API on behalf of your frontend app. Supports the [Client Credentials Flow](https://developer.spotify.com/documentation/general/guides/authorization-guide/#client-credentials-flow),  [Authorization Code Flow](https://developer.spotify.com/documentation/general/guides/authorization-guide/#authorization-code-flow), and  [Authorization Code Flow with Proof Key for Code Exchange](https://developer.spotify.com/documentation/general/guides/authorization-guide/#authorization-code-flow-with-proof-key-for-code-exchange-pkce)**

Can be run as a local server directly from Xcode. It will run on `http://127.0.0.1:7000`.

## Table of Contents

* **[Endpoints](#Endpoints)**
* **[Environment](#Environment)**
* **[Deploying to Heroku](#Deploying-to-Heroku)**

## Endpoints

### GET /

Returns the text "success". Used to indicate that the server is online.

### POST /client-credentials-tokens

**Request**

Header: `Content-Type: application/x-www-form-urlencoded`

The body must contain the following in x-www-form-urlencoded format:

<table>
  <thead>
    <tr>
      <th>Request Body Parameter</th>
      <th>Value</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>grant_type</td>
      <td><code>client_credentials</code>.</td>
    </tr>
  </tbody>
</table>

 see [`ClientCredentialsTokensRequest`](https://peter-schorn.github.io/SpotifyAPI/Structs/ClientCredentialsTokensRequest.html).

**Response** 

Header: `Content-Type: application/json`

Returns the authorization information as JSON data that can be decoded into `AuthInfo`. The `accessToken` and `expirationDate` (which can be decoded from the "expires_in" JSON key) properties should be non-`nil`. For example:

```
{
    "access_token": "NgCXRKc...MzYjw",
    "token_type": "bearer",
    "expires_in": 3600,
}
```

Read more at the [Spotify web API reference](https://developer.spotify.com/documentation/general/guides/authorization-guide/#:~:text=the%20request%20is%20sent%20to%20the%20%2Fapi%2Ftoken%20endpoint%20of%20the%20accounts%20service%3A).

### POST /authorization-code-flow/retrieve-tokens

**Request**

Header: `Content-Type: application/x-www-form-urlencoded`

The body must contain the following in x-www-form-urlencoded format:

<table>
  <thead>
    <tr>
      <th>Request Body Parameter</th>
      <th>Value</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>grant_type</td>
      <td><code>authorization_code</code>.</td>
    </tr>
    <tr>
      <td>code</td>
      <td>The authorization code returned from the initial request to the <code>/authorize</code> endpoint.</td>
    </tr>
  </tbody>
</table>

See [`ProxyTokensRequest`](https://peter-schorn.github.io/SpotifyAPI/Structs/ProxyTokensRequest.html).

**Response**

Header: `Content-Type: application/json`

Returns the authorization information as JSON data that can be decoded into `AuthInfo`. The `accessToken`,`refreshToken`, and `expirationDate` (which can be decoded from the "expires_in" JSON key) properties should be non-`nil`. For example:

```
{
    "access_token": "NgCXRK...MzYjw",
    "token_type": "Bearer",
    "scope": "user-read-private user-read-email",
    "expires_in": 3600,
    "refresh_token": "NgAagA...Um_SHo"
}
```

Read more at the [Spotify web API reference](https://developer.spotify.com/documentation/general/guides/authorization-guide/#:~:text=2.%20have%20your%20application%20request%20refresh%20and%20access%20tokens%3B%20spotify%20returns%20access%20and%20refresh%20tokens).

### POST /authorization-code-flow/refresh-tokens

**Request**

Header: `Content-Type: application/x-www-form-urlencoded`

The body must contain the following in x-www-form-urlencoded format:

<table>
  <thead>
    <tr>
      <th>Request Body Parameter</th>
      <th>Value</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>grant_type</td>
      <td><code>refresh token</code>.</td>
    </tr>
    <tr>
      <td>refresh_token</td>
      <td>The refresh token returned from the authorization code exchange.</td>
    </tr>
  </tbody>
</table>

See [`RefreshTokensRequest`](https://peter-schorn.github.io/SpotifyAPI/Structs/RefreshTokensRequest.html).

**Response**

Header: `Content-Type: application/json`

Returns the authorization information as JSON data that can be decoded into `AuthInfo`. The `accessToken` and `expirationDate` (which can be decoded from the "expires_in" JSON key) properties should be non-`nil`. For example:

```
{
   "access_token": "NgCXRK...MzYjw",
   "token_type": "Bearer",
   "scope": "user-read-private user-read-email",
   "expires_in": 3600
}
```

Read more at the [Spotify web API reference](https://developer.spotify.com/documentation/general/guides/authorization-guide/#:~:text=4.%20requesting%20a%20refreshed%20access%20token%3B%20spotify%20returns%20a%20new%20access%20token%20to%20your%20app).

### POST /authorization-code-flow-pkce/retrieve-tokens

**Request**

Header: `Content-Type: application/x-www-form-urlencoded`

The body must contain the following in x-www-form-urlencoded format:

<table>
  <thead>
    <tr>
      <th>Request Body Parameter</th>
      <th>Value</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>grant_type</td>
      <td><code>authorization_code</code>.</td>
    </tr>
    <tr>
      <td>code</td>
      <td>The authorization code returned from the initial request to the <code>/authorize</code> endpoint.</td>
    </tr>
    <tr>
      <td>coder verifier</td>
      <td>The code verifier that you generated when creating the authorization URL</td>
    </tr>
  </tbody>
</table>

See [`ProxyPKCETokensRequest`](https://peter-schorn.github.io/SpotifyAPI/Structs/ProxyPKCETokensRequest.html).

**Response**

Header: `Content-Type: application/json`

Returns the authorization information as JSON data that can be decoded into `AuthInfo`. The `accessToken`,`refreshToken`, and `expirationDate` (which can be decoded from the "expires_in" JSON key) properties should be non-`nil`. For example:

```
{
    "access_token": "NgCXRK...MzYjw",
    "token_type": "Bearer",
    "scope": "user-read-private user-read-email",
    "expires_in": 3600,
    "refresh_token": "NgAagA...Um_SHo"
}
```

Read more at the [Spotify web API reference](https://developer.spotify.com/documentation/general/guides/authorization-guide/#:~:text=4.%20your%20app%20exchanges%20the%20code%20for%20an%20access%20token).

### POST /authorization-code-flow-pkce/refresh-tokens

**Request**

Header: `Content-Type: application/x-www-form-urlencoded`

The body must contain the following in x-www-form-urlencoded format:

<table>
  <thead>
    <tr>
      <th>Request Body Parameter</th>
      <th>Value</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>grant_type</td>
      <td><code>refresh token</code>.</td>
    </tr>
    <tr>
      <td>refresh_token</td>
      <td>The refresh token returned from the authorization code exchange.</td>
    </tr>
  </tbody>
</table>

See [`ProxyPKCERefreshTokensRequest`](https://peter-schorn.github.io/SpotifyAPI/Structs/RefreshTokensRequest.html).

**Response**

Header: `Content-Type: application/json`

This method returns the authorization information as JSON data that can be decoded into `AuthInfo`. The `accessToken`, `refreshToken`, and `expirationDate` (which can be decoded from the "expires_in" JSON key) properties should be non-`nil`. For example:

```
{
    "access_token": "NgCXRK...MzYjw",
    "token_type": "Bearer",
    "scope": "user-read-private user-read-email",
    "expires_in": 3600,
    "refresh_token": "NgAagA...Um_SHo"
}
```

Read more at the [Spotify web API reference](https://developer.spotify.com/documentation/general/guides/authorization-guide/#:~:text=6.%20requesting%20a%20refreshed%20access%20token).

## Environment

Requires the following environment variables:

* `SPOTIFY_SWIFT_TESTING_CLIENT_ID`: Your client id from Spotify.

* `SPOTIFY_SWIFT_TESTING_CLIENT_SECRET`: Your client secret from Spotify.

* `REDIRECT_URI`: The URL that Spotify will redirect to after the user logs in to their account.

* `SECRET_KEY`: A randomly generated string that is used to generate a key for encryption. No specific length is required, but generally it should be at least 20 characters. This key is used to encrypt and decrypt the refresh token returned by Spotify. **Warning**: If you change this value, then any previously-retrieved authorization information will be invalidated.
* `LOG_LEVEL`: Not required, but can be used to change the log level of the loggers used by Vapor (but not the ones used by `SpotifyAPI`). See [here](https://docs.vapor.codes/4.0/logging/#level) for more information. See [here](https://devcenter.heroku.com/articles/logging#log-retrieval-via-the-web-dashboard) for how to retrieve the logs from Heroku.

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

