defmodule GruppieWeb.Api.V1.SchoolFeeView do
  use GruppieWeb, :view
  alias GruppieWeb.Repo.SchoolFeeRepo
  import GruppieWeb.Repo.RepoHelper


  def render("getFeeClassList.json", %{getClassFeesList: classList}) do
    list = if classList != [] do
      Enum.reduce(classList, [], fn k, acc ->
        map = %{
          "teamId" => encode_object_id(k["_id"]),
          "name" => k["name"],
          "image" => k["image"],
        }
        acc ++ [map]
      end)
    else
      []
    end
    %{
      data: list
    }
  end


  def render("getFineAmountUser.json", %{getFineAmount: fineAmount}) do
    list = if fineAmount do
      [%{
        "fineAmount" => fineAmount
      }]
    else
      []
    end
    %{ data: list}
  end


  def render("totalFeeSchool.json", %{getTotalFeeSchool: getTotalFeeAndPaidAmount, params: params}) do
    list = if getTotalFeeAndPaidAmount do
      if params["teamId"] do
        [%{
          "totalClassFee" => getTotalFeeAndPaidAmount.totalFeeSchool,
          "totalAmountReceived" => getTotalFeeAndPaidAmount.totalAmountReceived,
          "totalBalanceAmount" => getTotalFeeAndPaidAmount.totalFeeSchool -  getTotalFeeAndPaidAmount.totalAmountReceived
        }]
      else
        [%{
          "totalSchoolFee" => getTotalFeeAndPaidAmount.totalFeeSchool,
          "totalAmountReceived" => getTotalFeeAndPaidAmount.totalAmountReceived,
          "totalBalanceAmount" => getTotalFeeAndPaidAmount.totalFeeSchool -  getTotalFeeAndPaidAmount.totalAmountReceived
        }]
      end
    else
      []
    end
    %{
      data: list
    }
  end


  def  render("feeReport.json",%{getFeeReportList: feeReportList,  groupObjectId: _groupId, teamObjectId: _teamObjectId}) do
    list = if feeReportList != [] do
      installmentsReport = hd(feeReportList)
      feeReportList = tl(feeReportList)
      userObjectIds = for userId <- feeReportList do
        userId["userId"]
      end
      #get phone number
      phoneList =  SchoolFeeRepo.getPhoneList(userObjectIds)
      feeReportList =  Enum.map(feeReportList, fn k ->
        nameMap = Enum.find(phoneList, fn v -> v["userId"] == k["userId"] end)
        if nameMap do
          Map.merge(k, nameMap)
        end
      end)
      list = Enum.reduce(feeReportList, [], fn k, acc ->
        map = %{
          "dueWisePayment" => k["dueWisePayment"],
          "name" => k["name"],
          "phone" => k["phone"],
          "fatherName" => k["fatherName"]
        }
        acc ++ [map]
      end)
      # IO.puts "#{list}"
      list = list
      |> Enum.sort_by(& String.downcase(&1["name"]))
      list ++ [installmentsReport]
    else
      []
    end
    %{
      data: list
    }
  end


  def render("classWiseFeeReport.json", %{getClassWiseFeeReport: classFeeReportList}) do
    list = if classFeeReportList != [] do
      for classFeeReport <- classFeeReportList do
        %{
          "className" => classFeeReport["name"],
          "totalAmountReceived" => classFeeReport["totalAmountReceivedClass"],
          "totalSchoolFee" => classFeeReport["totalFeeClass"],
          "totalBalanceAmount" => classFeeReport["totalBalanceAmount"],
          "teamId" => classFeeReport["teamId"]
        }
      end
    else
      []
    end
    list = list
    |> Enum.sort_by(& String.downcase(&1["className"]))
    %{
      data: list
    }
  end


  def render("schoolClassInstallment.json", %{getInstallmentList: installmentList}) do
    list = if installmentList do
      installmentList["dueDates"]
    else
      []
    end
    %{
      data: list
    }
  end


  def render("schoolClassInstallmentStudentDueList.json", %{getInstallmentStudentDueList: dueStudentList}) do
    list = if dueStudentList != [] do
      for studentDetails <- dueStudentList do
        map = %{
          "name" => studentDetails["name"],
          "userId" => encode_object_id(studentDetails["userId"]),
          "pushToken" => studentDetails["pushToken"]
        }
        if Map.has_key?(studentDetails, "dueAmount") do
         Map.put(map, "dueAmount", studentDetails["dueAmount"])
        else
          map
        end
      end
    else
      []
    end
    %{
      data: list
    }
  end


  def render("dueMap.json", %{getDueMap: dueMap}) do
    %{
      data: dueMap
    }
  end
end
