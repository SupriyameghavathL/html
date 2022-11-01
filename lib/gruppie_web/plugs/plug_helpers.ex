defmodule GruppieWeb.Plugs.PlugHelpers do
  import Plug.Conn
  alias Phoenix.Controller
  alias GruppieWeb.Api.V1.ErrorView

  @template404 :error404

  @template500 :error500

  @template401 :error401

  @template403 :error403

  @template406 :error406

  @doc """
  function resposible for error view 404
  """
  def render404(conn) do
    case get_format(conn) do
      "json"->
        conn
        |> put_status(404)
        |> Controller.render(ErrorView, @template404)
        |> halt
      "html"->
        IO.puts "am in 404 html"
    end
  end

  @doc """
  function resposible for error view 500
  """
  def render500(conn) do
    case get_format(conn) do
      "json"->
        conn
        |> put_status(500)
        |> Controller.render(ErrorView,@template500)
        |> halt
      "html"->
        IO.puts "am in html"
    end
  end

  @doc """
  function resposible for error view 401
  """
  def render401(conn) do
    case get_format(conn) do
      "json"->
        conn
        |> put_status(401)
        |> Controller.render(ErrorView, @template401)
        |> halt
      "html"->
        IO.puts "am in html"
    end
  end

  @doc """
  function resposible for error view 403
  """
  def render403(conn) do
    case get_format(conn) do
      "json"->
        conn
        |> put_status(403)
        |> Controller.render(ErrorView, @template403)
        |> halt
      "html"->
        IO.puts "am in html"
    end
  end


  @doc """
  function resposible for error view 406
  """
  def render406(conn) do
    case get_format(conn) do
      "json"->
        conn
        |> put_status(406)
        |> Controller.render(ErrorView, @template406)
        |> halt
      "html"->
        IO.puts "am in html"
    end
  end


  defp get_format(conn) do
    conn.private[:phoenix_format] || conn.params["_format"]
  end

end
