defmodule GruppieWeb.Structs.Error500Response do
  @derive Jason.Encoder
  defstruct code: 500, title: "Internal Server Error", message: "Something Went Wrong"
end
