defmodule GruppieWeb.Structs.Error400Response do
  @derive Jason.Encoder
  defstruct code: 400, title: "Bad Request", message: "Please Check The Parameters"
end
