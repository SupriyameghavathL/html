defmodule GruppieWeb.Structs.JsonErrorResponse do
  @derive Jason.Encoder
  @enforce_keys [:code, :title, :message]
  defstruct @enforce_keys
end
