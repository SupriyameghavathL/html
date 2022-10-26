defmodule GruppieWeb.Handler.CalendarHandler do
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.CalendarRepo
  import GruppieWeb.Handler.TimeNow


  def addEventsCalendar(changeset, groupObjectId, _params) do
    startDateArray = String.split(changeset.startDate, "-")
    endDateArray = String.split(changeset.endDate, "-")
    reverseStartDate = Enum.at(startDateArray, 2)<>"-"<>Enum.at(startDateArray, 1)<>"-"<>Enum.at(startDateArray, 0)
    reverseEndDate = Enum.at(endDateArray, 2)<>"-"<>Enum.at(endDateArray, 1)<>"-"<>Enum.at(endDateArray, 0)
    month = String.to_integer(Enum.at(startDateArray, 1))
    year = String.to_integer(Enum.at(startDateArray, 2))
    sortDate =  Enum.at(startDateArray, 2)<>Enum.at(startDateArray, 1)<>Enum.at(startDateArray, 0)
    |> String.to_integer()
    #check whether documnet is created for month
    {:ok, check} = CalendarRepo.checkMonthAndYearDoc(groupObjectId, month, year)
    if check == 0 do
      insertDoc = %{
        "groupId" => groupObjectId,
        "isActive" => true,
        "insertedAt" => bson_time(),
        "lastEventUpdatedAt" => bson_time(),
        "month" => month,
        "year" => year,
        "events" => [
          changeset
          |> Map.put(:date, String.to_integer(Enum.at(startDateArray, 0)))
          |> Map.put(:reverseStartDate, reverseStartDate)
          |> Map.put(:reverseEndDate, reverseEndDate)
          |> Map.put(:CalendarId, encode_object_id(new_object_id()))
          |> Map.put(:sortTime, sortTimeLogics(changeset))
          |> Map.put(:sortDate, sortDate)
        ]
      }
      CalendarRepo.addEventsCalendar(insertDoc)
    else
      changeset = changeset
      |> Map.put(:date, String.to_integer(Enum.at(startDateArray, 0)))
      |> Map.put(:reverseStartDate, reverseStartDate)
      |> Map.put(:reverseEndDate, reverseEndDate)
      |> Map.put(:CalendarId, encode_object_id(new_object_id()))
      |> Map.put(:sortTime, sortTimeLogics(changeset))
      |> Map.put(:sortDate, sortDate)
      CalendarRepo.pushToExistedDoc(groupObjectId, month, year, changeset)
    end
  end


  def sortTimeLogics(changeset) do
    if Map.has_key?(changeset, :startTime) do
      amPm = String.split(changeset.startTime, " ")
      hrsFormat = String.split(Enum.at(amPm, 0), ":")
      if String.downcase(Enum.at(amPm, 1)) == "am" do
        if String.to_integer(Enum.at(hrsFormat, 0)) == 12 do
          String.to_integer("00"<>Enum.at(hrsFormat, 1))
        else
          String.to_integer(Enum.at(hrsFormat, 0)<>Enum.at(hrsFormat, 1))
        end
      else
        if String.to_integer(Enum.at(hrsFormat, 0)) == 12 do
          String.to_integer("12"<>Enum.at(hrsFormat, 1))
        else
          1200 + String.to_integer(Enum.at(hrsFormat, 0)<>Enum.at(hrsFormat, 1))
        end
      end
    else
      2400
    end
  end


  def getCalendarEvents(groupObjectId, month, params) do
    CalendarRepo.getCalendarEvents(groupObjectId, String.to_integer(month), params)
  end


  def getCalendarEventsYear(groupObjectId, month, year, params) do
    CalendarRepo.getCalendarEventsYear(groupObjectId, String.to_integer(month), String.to_integer(year), params)
  end


  def editEventAdd(groupObjectId, calendarId, changeset) do
    startDateArray = String.split(changeset.startDate, "-")
    endDateArray = String.split(changeset.endDate, "-")
    reverseStartDate = Enum.at(startDateArray, 2)<>"-"<>Enum.at(startDateArray, 1)<>"-"<>Enum.at(startDateArray, 0)
    reverseEndDate = Enum.at(endDateArray, 2)<>"-"<>Enum.at(endDateArray, 1)<>"-"<>Enum.at(endDateArray, 0)
    changeset = changeset
    |> Map.put(:date, String.to_integer(Enum.at(startDateArray, 0)))
    |> Map.put(:reverseStartDate, reverseStartDate)
    |> Map.put(:reverseEndDate, reverseEndDate)
    |> Map.put(:CalendarId, calendarId)
    |> Map.put(:sortTime, sortTimeLogics(changeset))
    CalendarRepo.editEventAdd(groupObjectId, calendarId, changeset)
  end


  def deleteCalendarEvents(groupObjectId, calendarId) do
    CalendarRepo.deleteCalendarEvents(groupObjectId, calendarId)
  end
end
