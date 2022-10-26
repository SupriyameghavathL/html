defmodule GruppieWeb.Api.V1.SecurityView do
  use GruppieWeb, :view

  def render("error.json", %{ error: changeset, status: code }) do
    errors = Enum.map(changeset, fn {field, detail} ->
      err = elem(detail, 0)
      %{
        "#{field}": err
      }
    end)

    %{errors: errors, status: code}
  end

  #post report reasons
  def render("post_report_reasons.json", %{ postReportReasons: postReportReasons }) do
    list = Enum.reduce(postReportReasons, [], fn k, acc ->
      map = %{
        reason: k["reason"],
        type: k["type"]
      }

      acc ++ [map]
    end)

    %{ data: list }
  end
end
