defmodule GruppieWeb.Api.V1.CalendarController do
  use GruppieWeb, :controller
  alias GruppieWeb.Structs.JsonErrorResponse
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Handler.CalendarHandler
  alias GruppieWeb.Calendar

  plug GruppieWeb.Plugs.GroupAccessAuth, %{ "group_id" => "group_id", "user_id" => "login_user_id" }



  # post "/groups/:group_id/calendar/events/add"
  def addCalendarEvents(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    changeset = Calendar.calendarEventAdd(%Calendar{}, params)
    if changeset.valid? do
      case CalendarHandler.addEventsCalendar(changeset.changes, group["_id"], params) do
        {:ok, _success} ->
          conn
          |> put_status(201)
          |> json(%{})
        {:error, _mongo_error}->
          conn
          |> put_status(500)
          |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
      end
    else
      conn
      |> put_status(400)
      |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end

  #get "/groups/:group_id/calendar/events/get"
  def getCalendarEvents(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    getCalendarEvents =  cond do
      params["year"] && params["month"] ->
        CalendarHandler.getCalendarEventsYear(group["_id"], params["month"], params["year"], params)
      params["month"] ->
        CalendarHandler.getCalendarEvents(group["_id"], params["month"], params)
      true ->
       []
    end
    render(conn, "calendarEvents.json", [getCalendarEvents: getCalendarEvents])
  end


  #put "/groups/:group_id/calendar/:calendar_id/events/edit"
  def editCalendarEvents(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "calendar_id" => calendar_id}) do
    group = GroupRepo.get(group_id)
    changeset =  Calendar.calendarEventAdd(%Calendar{}, params)
    if changeset.valid? do
      case CalendarHandler.editEventAdd(group["_id"], calendar_id, changeset.changes) do
        {:ok, _success} ->
          conn
          |> put_status(200)
          |> json(%{})
        {:error, _mongo_error}->
          conn
          |> put_status(500)
          |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
      end
    else
      conn
      |> put_status(400)
      |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


  # put "/groups/:group_id/calendar/:calendar_id/events/delete"
  def deleteCalendarEvents(conn, %{"group_id" => group_id, "calendar_id" => calendar_id})  do
    group = GroupRepo.get(group_id)
    case CalendarHandler.deleteCalendarEvents(group["_id"], calendar_id) do
      {:ok, _success} ->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _mongo_error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
    end
  end
end
