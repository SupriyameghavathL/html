defmodule Gruppie.Api.V1.SchoolCollegeRegisterView do
  use GruppieWeb, :view



  def render("getClassList.json", %{getClassList: classList}) do
    list = if classList != [] do
        [%{
        "classes" => classList["classes"],
        "board" => classList["board"],
        "subCategory" => classList["subCategory"]
      }]
    else
      []
    end
    %{ data: list}
  end


  def render("getCreatedClassList.json", %{getCreatedClassList: createdClassList}) do
    classlist = if createdClassList != [] do
      Enum.reduce(createdClassList, [], fn k, acc ->
       map = %{
         "className" => k
        }
        acc ++ [map]
      end)
    else
      []
    end
    %{
      data: classlist
    }
  end

  def render("getBoard.json", %{getBoardList: boardList}) do
    map = if boardList != %{} do
      [%{
        "boards" => boardList["boards"]
      }]
    else
      []
    end
    %{ data: map}
  end


  def render("getMedium.json", %{getMediumList: mediumList}) do
    map = if mediumList != %{} do
      [
        %{
          "medium" => mediumList["language"]
        }
      ]
    else
      []
    end
    %{ data: map}
  end


  def render("getUniversity.json", %{getUniversityList: universityList}) do
    map = if universityList != %{} do
       [ %{
          "university" => universityList["university"]
        }]
    else
      []
    end
    %{ data: map}
  end


  def render("getCampus.json", %{getCampusList: campusList}) do
    map = if campusList != %{} do
      [
        %{
          "typeOfCampus" => campusList["typeOfCampus"]
        }
      ]
    else
      []
    end
    %{ data: map}
  end


  def render("getClassListToCreate.json", %{getClassListToCreate: classListToAddClass}) do
    classList = if classListToAddClass != [] do
      [%{
        "classes" =>
        for classList <- classListToAddClass do
          %{
            "class" => classList["class"],
            "classTypeId" => classList["classTypeId"],
            "type" => classList["type"]
          }
        end
      }]
    else
      []
    end
    %{
      data: classList
    }
  end


  def render("getRemainingDays.json", %{getRemainingDays: getTrailPeriodRemainingDays}) do
    days = if getTrailPeriodRemainingDays != "" do
      [%{
        "noOfDaysRemaining" => getTrailPeriodRemainingDays
      }]
    else
      ""
    end
    %{
      data: days
    }
  end
end
