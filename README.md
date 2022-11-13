# SpotifyAPIServer

**A server that handles the process of retrieving the authorization information and refreshing tokens for the Spotify web API on behalf of your frontend app. Supports the [Client Credentials Flow](https://developer.spotify.com/documentation/general/guides/authorization/client-credentials/),  [Authorization Code Flow](https://developer.spotify.com/documentation/general/guides/authorization/code-flow/), and  [Authorization Code Flow with Proof Key for Code Exchange](https://developer.spotify.com/documentation/general/guides/authorization/code-flow/)**.

Can be run as a local server directly from Xcode. It will run on `http://127.0.0.1:7000`.

This sever can be used with [SpotifyAPI](https://github.com/Peter-Schorn/SpotifyAPI). See [Using a Backend Server to Retrieve the Authorization Information](https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/additional-authorization-methods) for more information.

Can also be used with the [Spotify iOS SDK](https://developer.spotify.com/documentation/ios/guides/token-swap-and-refresh/). Assign [/authorization-code-flow/retrieve-tokens](#post-authorization-code-flowretrieve-tokens) to the "tokenSwapURL" and [/authorization-code-flow/refresh-tokens](#post-authorization-code-flowrefresh-tokens) to "tokenRefreshURL".

## Table of Contents

* **[Environment](#Environment)**
* **[Deploying to Heroku](#Deploying-to-Heroku)**
* **[Deploying to AWS](#Deploying to AWS)**
* **[Endpoints](#Endpoints)**
* **[Errors](#Errors)**

## Environment

Requires the following environment variables:

* `CLIENT_ID`: Your client id from Spotify.
* `CLIENT_SECRET`: Your client secret from Spotify.
* `REDIRECT_URI`:  The redirect URI. Can be omitted if this value is sent in the body of requests to the [/authorization-code-flow/retrieve-tokens](#post-authorization-code-flowretrieve-tokens) or [/authorization-code-flow-pkce/retrieve-tokens](#post-authorization-code-flow-pkceretrieve-tokens) endpoints. If both are present, then the value sent in the body of the request takes precedence. If you are using this server with the [Spotify iOS SDK](https://developer.spotify.com/documentation/ios/guides/token-swap-and-refresh), then you must set this value, as it will not be sent in the body of the request to the /authorization-code-flow/retrieve-tokens endpoint. 
* `SECRET_KEY`: A randomly generated string that is used to generate a key for encryption. No specific length is required, but generally it should be at least 20 characters. This key is used to encrypt and decrypt the refresh token returned by Spotify. **Warning**: If you change this value, then any previously-retrieved authorization information will be invalidated.
* `LOG_LEVEL`: Not required, but can be used to change the log level of the loggers used by Vapor (but not the ones used by `SpotifyAPI`). See [here](https://docs.vapor.codes/4.0/logging/#level) for more information. See [here](https://devcenter.heroku.com/articles/logging#log-retrieval-via-the-web-dashboard) for how to retrieve the logs from Heroku.

## Deploying to Heroku

This server is pre-configured for deployment to [Heroku](https://www.heroku.com/about) (although any platform can be used).

**One-Click Deployment**

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

**Manual Deployment**

First, sign up for a Heroku account, install the command-line tool, login, and create a Heroku application, as described [here](https://docs.vapor.codes/4.0/deploy/heroku/). Clone this repository and set it as the working directory. Then, run the following command:

```
heroku git:remote -a [app name]
```

where `app name` is the name of the application that you just created on Heroku. This command adds a custom remote to your repository called `heroku`; pushing to it causes your app to be deployed.

Next, set the buildpack to teach heroku how to deal with vapor:

```
heroku buildpacks:set vapor/vapor
```

Finally, deploy to Heroku by running the following:

```
git push heroku main
```

See [here](https://devcenter.heroku.com/articles/config-vars#using-the-heroku-dashboard) for how to configure the above-mentioned environment variables on heroku.

## Deploying to AWS

This server is also available as a docker image in the Amazon [ECR Public Gallery](https://gallery.ecr.aws/h4z3r8p2/spotify-api-server). Create an App Runner server [here](https://console.aws.amazon.com/apprunner#/create). Choose "Container registry" for "Repository type" and "Amazon ECR Public" for "Provider". For "Container image URI," use `public.ecr.aws/h4z3r8p2/spotify-api-server:latest`.  Then, click next. Configure the environment variables as described above. For "Port," use `8080`. Follow the prompts to create the service. Read more about App Runner [here](https://docs.aws.amazon.com/apprunner/latest/dg/what-is-apprunner.html).

## Endpoints

### GET /

Returns the text "success". Used to indicate that the server is online.

### POST /client-credentials-flow/retrieve-tokens

Retrieves the authorization information for the [Client Credentials Flow](https://developer.spotify.com/documentation/general/guides/authorization/client-credentials/).

A request to this endpoint can be made by [`ClientCredentialsFlowProxyBackend.makeClientCredentialsTokensRequest()`](https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/clientcredentialsflowproxybackend/makeclientcredentialstokensrequest()). Assign this endpoint to [`ClientCredentialsFlowProxyBackend.tokensURL`](https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/clientcredentialsflowproxybackend/tokensurl).

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
      <td><code>client_credentials</code></td>
    </tr>
  </tbody>
</table>

See [`ClientCredentialsTokensRequest`](https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/clientcredentialstokensrequest), which can be used to encode this data.

**Response** 

Header: `Content-Type: application/json`

Returns the authorization information as JSON data that can be decoded into [`AuthInfo`](https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/authinfo). The `accessToken` and `expirationDate` (which can be decoded from the "expires_in" JSON key) properties should be non-`nil`. For example:

```
{
    "access_token": "NgCXRKc...MzYjw",
    "token_type": "bearer",
    "expires_in": 3600,
}
```

Read more at the [Spotify web API reference](https://developer.spotify.com/documentation/general/guides/authorization/client-credentials/#request-authorization).

### POST /authorization-code-flow/retrieve-tokens

Retrieves the authorization information for the [Authorization Code Flow](https://developer.spotify.com/documentation/general/guides/authorization/code-flow/).

A request to this endpoint can be made by [`AuthorizationCodeFlowProxyBackend.requestAccessAndRefreshTokens(code:redirectURIWithQuery:)`](https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/authorizationcodeflowproxybackend/requestaccessandrefreshtokens(code:redirecturiwithquery:)). Assign this endpoint to [`AuthorizationCodeFlowProxyBackend.tokensURL`](https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/authorizationcodeflowproxybackend/tokensurl).

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
      <td><code>authorization_code</code></td>
    </tr>
    <tr>
      <td>code</td>
      <td>The authorization code returned from the initial request to the <code>/authorize</code> endpoint.</td>
    </tr>
    <tr>
      <td>redirect_uri</td>
      <td>The redirect URI, which must match the value your app supplied when requesting the authorization code. Can be omitted if this value is stored in the <code>REDIRECT_URI</code> environment variable.</td>
    </tr>
  </tbody>
</table>

See [`ProxyTokensRequest`](https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/proxytokensrequest), which can be used to encode this data.

**Response**

Header: `Content-Type: application/json`

Returns the authorization information as JSON data that can be decoded into [`AuthInfo`](https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/authinfo). The `accessToken`,`refreshToken`, and `expirationDate` (which can be decoded from the "expires_in" JSON key) properties should be non-`nil`. For example:

```
{
    "access_token": "NgCXRK...MzYjw",
    "token_type": "Bearer",
    "scope": "user-read-private user-read-email",
    "expires_in": 3600,
    "refresh_token": "NgAagA...Um_SHo"
}
```

Read more at the [Spotify web API reference](https://developer.spotify.com/documentation/general/guides/authorization/code-flow/#request-access-token).

### POST /authorization-code-flow/refresh-tokens

Refreshes the access token for the [Authorization Code Flow](https://developer.spotify.com/documentation/general/guides/authorization/code-flow/).

A request to this endpoint can be made by [`AuthorizationCodeFlowProxyBackend.refreshTokens(refreshToken:)`](https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/authorizationcodeflowproxybackend/refreshtokens(refreshtoken:)). Assign this endpoint to [`AuthorizationCodeFlowProxyBackend.tokenRefreshURL`](https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/authorizationcodeflowproxybackend/tokenrefreshurl).

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
      <td><code>refresh token</code></td>
    </tr>
    <tr>
      <td>refresh_token</td>
      <td>The refresh token returned from the authorization code exchange.</td>
    </tr>
  </tbody>
</table>

See [`RefreshTokensRequest`](https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/refreshtokensrequest), which can be used to encode this data.

**Response**

Header: `Content-Type: application/json`

Returns the authorization information as JSON data that can be decoded into [`AuthInfo`](https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/authinfo). The `accessToken` and `expirationDate` (which can be decoded from the "expires_in" JSON key) properties should be non-`nil`. For example:

```
{
   "access_token": "NgCXRK...MzYjw",
   "token_type": "Bearer",
   "scope": "user-read-private user-read-email",
   "expires_in": 3600
}
```

Read more at the [Spotify web API reference](https://developer.spotify.com/documentation/general/guides/authorization/code-flow/#request-a-refreshed-access-token).

### POST /authorization-code-flow-pkce/retrieve-tokens

Retrieves the authorization information for the [Authorization Code Flow with Proof Key for Code Exchange](https://developer.spotify.com/documentation/general/guides/authorization/code-flow/).

A request to this endpoint can be made by [`AuthorizationCodeFlowPKCEProxyBackend.requestAccessAndRefreshTokens(code:codeVerifier:redirectURIWithQuery:)`](https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/authorizationcodeflowpkceproxybackend/requestaccessandrefreshtokens(code:codeverifier:redirecturiwithquery:)). Assign this endpoint to [`AuthorizationCodeFlowPKCEProxyBackend.tokensURL`](https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/authorizationcodeflowpkceproxybackend/tokensurl).

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
      <td><code>authorization_code</code></td>
    </tr>
    <tr>
      <td>code</td>
      <td>The authorization code returned from the initial request to the <code>/authorize</code> endpoint.</td>
    </tr>
    <tr>
      <td>coder verifier</td>
      <td>The code verifier that you generated when creating the authorization URL</td>
    </tr>
    <tr>
      <td>redirect_uri</td>
      <td>The redirect URI, which must match the value your app supplied when requesting the authorization code. Can be omitted if this value is stored in the <code>REDIRECT_URI</code> environment variable.</td>
    </tr>
  </tbody>
</table>

See [`ProxyPKCETokensRequest`](https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/proxypkcetokensrequest), which can be used to encode this data.

**Response**

Header: `Content-Type: application/json`

Returns the authorization information as JSON data that can be decoded into [`AuthInfo`](https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/authinfo). The `accessToken`,`refreshToken`, and `expirationDate` (which can be decoded from the "expires_in" JSON key) properties should be non-`nil`. For example:

```
{
    "access_token": "NgCXRK...MzYjw",
    "token_type": "Bearer",
    "scope": "user-read-private user-read-email",
    "expires_in": 3600,
    "refresh_token": "NgAagA...Um_SHo"
}
```

Read more at the [Spotify web API reference](https://developer.spotify.com/documentation/general/guides/authorization/code-flow/#request-access-token).

### POST /authorization-code-flow-pkce/refresh-tokens

Refreshes the access token for the [Authorization Code Flow with Proof Key for Code Exchange](https://developer.spotify.com/documentation/general/guides/authorization/code-flow/).

A request to this endpoint can be made by [`AuthorizationCodeFlowPKCEProxyBackend.refreshTokens(refreshToken:)`](https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/authorizationcodeflowpkceproxybackend/refreshtokens(refreshtoken:)). Assign this endpoint to [`AuthorizationCodeFlowPKCEProxyBackend.tokenRefreshURL`](https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/authorizationcodeflowpkceproxybackend/tokenrefreshurl).

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
      <td><code>refresh token</code></td>
    </tr>
    <tr>
      <td>refresh_token</td>
      <td>The refresh token returned from the authorization code exchange.</td>
    </tr>
  </tbody>
</table>

See [`ProxyPKCERefreshTokensRequest`](https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/proxypkcerefreshtokensrequest), which can be used to encode this data.

**Response**

Header: `Content-Type: application/json`

This method returns the authorization information as JSON data that can be decoded into [`AuthInfo`](https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/authinfo). The `accessToken`, `refreshToken`, and `expirationDate` (which can be decoded from the "expires_in" JSON key) properties should be non-`nil`. For example:

```
{
    "access_token": "NgCXRK...MzYjw",
    "token_type": "Bearer",
    "scope": "user-read-private user-read-email",
    "expires_in": 3600,
    "refresh_token": "NgAagA...Um_SHo"
}
```

Read more at the [Spotify web API reference](https://developer.spotify.com/documentation/general/guides/authorization/code-flow/#request-a-refreshed-access-token).

## Errors

Any error that is received from the Spotify web API, along with the headers and status code, are forwarded directly to the client, as [SpotifyAPI](https://github.com/Peter-Schorn/SpotifyAPI) already knows how to decode these errors. Therefore, do not attempt to decode these errors yourself. If this server encounters an error (e.g., the request body could not be decoded into the expected type, or the refresh token could not be encrypted/decrypted), then the status code will be in the 4xx range, the headers will contain the "Content-Type: application/json" header, and the response body will be a JSON object with the following keys:

<table>
  <thead>
    <tr>
      <th>Key</th>
      <th>Type</th>
      <th>Value</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>error</td>
      <td>Boolean</td>
      <td>Always set to <code>true</code> to disambiguate this response from the JSON payload of a successful response.</td>
    </tr>
    <tr>
      <td>reason</td>
      <td>String</td>
      <td>A short description of the cause of this error.</td>
    </tr>
  </tbody>
</table>
