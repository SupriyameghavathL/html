defmodule GruppieWeb.Structs.Error401Response do
  @derive Jason.Encoder
  defstruct code: 401, title: "unauthenticated", message: "user not logged in"
end
