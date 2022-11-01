defmodule GruppieWeb.Structs.Error404Response do
  @derive Jason.Encoder
  defstruct code: 404, title: "Not Found", message: "Given Url Not Found"
end
