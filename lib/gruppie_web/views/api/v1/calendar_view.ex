defmodule GruppieWeb.Api.V1.CalendarView do
  use GruppieWeb, :view


  def render("calendarEvents.json", %{getCalendarEvents: getCalendarEvents}) do
    list = if getCalendarEvents == [] do
      []
    else
      if getCalendarEvents do
        for events <- getCalendarEvents["events"] do
          %{
            "title" => events["title"],
            "startTime" => events["startTime"],
            "endTime" => events["endTime"],
            "startDate" => events["startDate"],
            "endDate" => events["endDate"],
            "venue" => events["venue"],
            "reminder" => events["reminder"],
            "location" => events["location"],
            "id" => events["CalendarId"],
            "startReverseDate" => events["reverseStartDate"],
            "endReverseDate" => events["reverseEndDate"],
            "sortDate" => events["sortDate"],
            "sortTime" => events["sortTime"]
            # "groupId" => encode_object_id(events["groupId"])
          }
        end
        |> Enum.sort_by(& (&1["sortTime"]), &<=/2)
        |> Enum.sort_by(& (&1["sortTime"]), &<=/2)
      else
        []
      end
    end
    %{
      data: list,
      totalNumberOfPages: 1
    }
  end
end
