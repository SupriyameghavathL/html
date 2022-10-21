defmodule GruppieWeb.PageController do
  use GruppieWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
