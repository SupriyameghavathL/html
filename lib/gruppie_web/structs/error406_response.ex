defmodule GruppieWeb.Structs.Error406Response do
  @derive Jason.Encoder
  defstruct code: 406, title: "Not Accepted", message: "Not Acceptable"
end
