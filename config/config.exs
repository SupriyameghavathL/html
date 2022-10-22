# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :gruppie,
  ecto_repos: [Gruppie.Repo]

# Configures the endpoint
config :gruppie, GruppieWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: GruppieWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Gruppie.PubSub,
  live_view: [signing_salt: "mRxj4r7+"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :gruppie, Gruppie.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :guardian, Guardian,
  allowed_algos: ["ES512"], #optional, algorithm used with secret key to sign
  verify_module: Guardian.JWT, #Provides a mechanism to setup your own validations for items in the token
  issuer: "Gruppie", #entry to put issuer of the token
  #ttl: {1, :days}, #ttl for token
  verify_issuer: true, #the issuer will be verified to be the same issuer as specified in the issuer field
  allowed_drift: 2000,
  #secret_key: %{"k" => "7duE1P9bnhUjeLuVCbe6CA", "kty" => "oct"},
  secret_key: %{"alg" => "ES512", "crv" => "P-521",
                  "d" => "AcmkDtWepfXO77LvtLJc3oYl6NavStm1MhyvEHPSgyzb7NznBPNI7w6v0rDIxWRpRF6_N5e5BQUKm4hahO24TlJW",
                  "kty" => "EC", "use" => "sig",
                  "x" => "ALrPX_9CAWLDlqPk1MBE9IAUOHbBE_jjE5uXSYGoBPDZFOAOt3fNh-qRMYNZ_WEnyuYSfLNrLbfu3ue0kcry-kd2",
                  "y" => "AFbIFegFODslhVO8XUFmGGxEqBFs96UTu9sbAeodryVVF1bYayS4hkoMRATH--2ehWTNu9MYpCq7Hk7cpM6nAkSW"
              },   #key used to sign token[link: https://github.com/ueberauth/guardian/issues/152]
  serializer: Gruppie.Serializer.GuardianSerializer #The serializer that serializes the 'sub' (Subject) field into and out of the token.


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
