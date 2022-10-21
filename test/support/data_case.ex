defmodule Gruppie.DataCase do

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Gruppie.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Gruppie.DataCase
    end
  end


  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
