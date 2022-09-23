# Example styles to authorize rails with Okta

This project demonstrates different code organization approaches to authenticate with Okta with ruby on rails.

**Warning:** None of this code is production ready.  Things is missing code (like caching jwks responses), code duplication, missing test cases, etc, etc.

## Different Styles

### Fat Controller Style

The [Fat Controller.rb](app/controllers/fat_controller.rb) does all the authentication in one place.

One pro: it is easy to inspect, and learn how the Okta auth works.

Much of the logic is copied from [Okta's examples](https://developer.okta.com/docs/guides/sign-into-web-app-redirect/php/main/#define-a-callback-route).

### Service Style

This style uses two tightly coupled services [OktaAuthUri](app/services/okta_auth_uri.rb) and [OktaParseIdToken](app/services/okta_parse_id_token.rb).  The [ServiceController](app/controllers/service_controller.rb) is very thin, with a little bit of leaky abstractions on [line: 22](app/controllers/service_controller.rb#L22).

Future improvements:

* remove crufty bit in controller
* encapsulate coupling (like session keys)
* add jwks caching

### Model Style

Here we use a model with Active Record Validations.  The [auth model](app/models/okta_auth.rb) has a paired [validator](app/models/validator.rb).  The [controller](app/controllers/model_controller.rb) must call `valid?` to start the token validate process.  Very similar to the service method.  But with added `rescues` for the raised error to provide more(?) meaningful messages.

## Local Dev

To run this application:

1. Create an Okta developer account
1. Create an Okta 'web' application
1. Add three callback uris to your web application: ("#{config.redirect_uri}/fat/callback", "#{config.redirect_uri}/service/callback", "#{config.redirect_uri}/model/callback")
1. Add the below to your environment (I use `direnv`)
1. Run the app: `rails s`

```shell
# .envrc
## Replace 'XXXX' values appropriately
export OKTA_ISSUER="https://dev-XXXXXXXXX.okta.com/oauth2/default"
export OKTA_CLIENT_ID="XXXXXXXXXXXXXXXXX"
export OKTA_CLIENT_SECRET="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export OKTA_REDIRECT_URI="http://localhost:3000"
```
