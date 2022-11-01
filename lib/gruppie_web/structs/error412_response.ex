defmodule GruppieWeb.Structs.Error412Response do
  @derive Jason.Encoder
  defstruct code: 412, title: "Bad Request", message: "Only 200 Documents Supported"
end
