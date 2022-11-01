defmodule GruppieWeb.Handler.GuardianAuthHandler do
  use Guardian.Plug.Pipeline, otp_app: :gruppie,
  module: GruppieWeb.Serializer.GuardianSerializer,
  error_handler: GruppieWeb.Serializer.GuardianError

  plug(Guardian.Plug.VerifyHeader)
  plug(Guardian.Plug.EnsureAuthenticated)
  plug(Guardian.Plug.LoadResource, ensure: true)



end
