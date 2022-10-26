defmodule GruppieWeb.Repo.CalendarRepo do
  import GruppieWeb.Handler.TimeNow

  @conn :mongo

  @calendar_events_col "calendar_db"




  def checkMonthAndYearDoc(groupObjectId, month, year) do
    filter = %{
      "groupId" => groupObjectId,
      "year" =>  year,
      "month" => month,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @calendar_events_col, filter, [projection: project])
  end


  def pushToExistedDoc(groupObjectId, month, year, changeset) do
    filter = %{
      "groupId" => groupObjectId,
      "year" =>  year,
      "month" => month,
      "isActive" => true,
    }
    update = %{
      "$push" => %{
        "events" => changeset
      },
      "$set" => %{
        "lastEventUpdatedAt" => bson_time()
      }
    }
    Mongo.update_one(@conn, @calendar_events_col, filter, update)
  end



  def addEventsCalendar(changeset) do
    Mongo.insert_one(@conn, @calendar_events_col, changeset)
  end


  def getCalendarEvents(groupObjectId, month, params) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "month" => month,
    }
    project = %{
      "events" => 1,
      "_id" => 0,
    }
    if !is_nil(params["page"]) do
      Mongo.find_one(@conn, @calendar_events_col, filter, [projection: project])
    else
      Mongo.find_one(@conn, @calendar_events_col, filter, [projection: project])
    end
  end


  def getCalendarEventsYear(groupObjectId, month, year, params) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "month" => month,
      "year" => year,
    }
    project = %{
      "events" => 1,
      "_id" => 0,
    }
    if !is_nil(params["page"]) do
      Mongo.find_one(@conn, @calendar_events_col, filter, [projection: project])
    else
      Mongo.find_one(@conn, @calendar_events_col, filter, [projection: project])
    end
  end


  def editEventAdd(groupObjectId, calendarId, changeset) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "events.CalendarId" => calendarId,
    }
    update = %{
      "$set" => %{
        "events.$" => changeset
      }
    }
    Mongo.update_one(@conn, @calendar_events_col, filter, update)
  end


  def deleteCalendarEvents(groupObjectId, calendarId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "events.CalendarId" => calendarId,
    }
    update = %{
     "$pull" => %{
      "events" => %{
        "CalendarId" => calendarId
      }
     }
    }
    Mongo.update_one(@conn, @calendar_events_col, filter, update)
  end
end
