defmodule GruppieWeb.Structs.Error403Response do
  @derive Jason.Encoder
  defstruct code: 403, title: "Access Forbidden", message: "Current user not allowed to Access this resource"
end
