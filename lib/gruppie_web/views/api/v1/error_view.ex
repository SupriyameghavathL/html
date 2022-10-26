defmodule GruppieWeb.Api.V1.ErrorView do
  use GruppieWeb, :view
  alias GruppieWeb.Structs.Error404Response
  alias GruppieWeb.Structs.Error500Response
  alias GruppieWeb.Structs.Error401Response
  alias GruppieWeb.Structs.Error403Response
  alias GruppieWeb.Structs.Error400Response
  alias GruppieWeb.Structs.Error406Response

  @doc """
  function handles 404 errors
  """
  def render("error404.json", _ ) do
    %Error404Response{}
  end

  @doc """
  template/function render 500 errors
  """
  def render("error500.json", _) do
    %Error500Response{}
  end

  @doc """
  template/function render 401 errors
  """
  def render("error401.json", _) do
    %Error401Response{}
  end

  @doc """
  template/function render 403 errors
  """
  def render("error403.json", _) do
    %Error403Response{}
  end

  @doc """
  template/function render 400 errors
  """
  def render("error400.json", _) do
    %Error400Response{}
  end

  @doc """
  template/function render 406 errors
  """
  def render("error406.json", _) do
    %Error406Response{}
  end

end
