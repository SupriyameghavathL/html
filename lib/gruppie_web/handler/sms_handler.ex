defmodule GruppieWeb.Handler.SmsHandler do

  @sms_url "http://sms99.co.in/pushsms.php?"

  # @sms_url_2 "http://www.resellerbulksms.com/sendsmsapi.php?"

  @sms_url_textlocal "https://api.textlocal.in/send?"

  @auth %{
    "username" => "trramji",
    "password" => "sms123",
    "sender" => "GRUPIE"
  }

  # @auth_2 %{
  #   "username" => "Vivid",
  #   "password" => "sms123",
  #   "senderid" => "GRUPIE",
  #   "route" => "trans",
  #   "lang" => "english"
  # }

  @auth_3 %{
    "apikey" => "MWJhZWQ4MjNlOTUyY2IzOTJkYjEwMDQ0ODgwNGM0OGI=",
    "sender" => "GRUPIE",
  }

  @auth_4 %{
    "apiKey" => "NjQ3ODM0NzU0YjQ5NDc2YjQ4NDc2MTY1NjQ2YzU1NmY=",
    "sender" => "GRUPIE"
  }





  def sendAbsentMessage(map) do
    #currentTime =  bson_time()
    #{ok, datetime, 0} = DateTime.from_iso8601(currentTime)
    #time = to_string(DateTime.to_time(datetime))
    time1 = NaiveDateTime.utc_now
    time2 = NaiveDateTime.add(time1, 19800)    # to IST +5:30hrs = 19800 seconds , Add 19800 sec to time1
    hour = String.slice("0"<>""<>to_string(time2.hour), -2, 2)
    minute = String.slice("0"<>""<>to_string(time2.minute), -2, 2)
    #IO.puts "#{"0"<>""<>to_string(time2.day)}"
    day = String.slice("0"<>""<>to_string(time2.day), -2, 2)
    month = String.slice("0"<>""<>to_string(time2.month), -2, 2)
    year = to_string(time2.year)
    #message = "Dear Parent, Your Son/Daughter is absent for class at: "<>hour<>":"<>minute<>" on: "<>day<>"/"<>month<>"/"<>year
    message = "Dear Parent, Your Son/Daughter is absent for class at: "<>hour<>":"<>minute<>", on: "<>day<>"/"<>month<>"/"<>year
    #send_attendance_sms(map, message)
    send_attendance_sms_tl(map, message)
  end



  def sendAbsentMessageWithSubject(map, subjectName) do
    time1 = NaiveDateTime.utc_now
    time2 = NaiveDateTime.add(time1, 19800)    # to IST +5:30hrs = 19800 seconds , Add 19800 sec to time1
    # hour = String.slice("0"<>""<>to_string(time2.hour), -2, 2)
    # minute = String.slice("0"<>""<>to_string(time2.minute), -2, 2)
    #IO.puts "#{"0"<>""<>to_string(time2.day)}"
    day = String.slice("0"<>""<>to_string(time2.day), -2, 2)
    month = String.slice("0"<>""<>to_string(time2.month), -2, 2)
    year = to_string(time2.year)
    #message = "Dear Parent, Your Son/Daughter is absent for "<>subjectName<>" class on: "<>day<>"/"<>month<>"/"<>year
    message = "Dear Parent, Your Son/Daughter is absent for "<>subjectName<>" class on: "<>day<>"/"<>month<>"/"<>year<>"."
    #send_attendance_sms(map, message)
    send_attendance_sms_tl(map, message)
  end


  def register(map, otp) do
    message = "Hi, Registration Successful, your OTP is "<>otp<>" \n Regards,\n Gruppie."
    send_sms(map, message)
  end


  def changeMobileNumber(map, otp, newPhoneNumber) do
    phone = String.slice(map["phone"], -10, 10)
    finalMap = %{ phone: phone }
    message = "Mobile Number Changed Successfully from "<>phone<>" to "<>newPhoneNumber<>". Your OTP is "<>otp<>" to login with new Number \n Regards,\n Gruppie."
    send_sms(finalMap, message)
  end


  def add_friend(user, _referrer) do
    message = "Hi, your otp is "<>user.otp<>"";
    send_sms(user, message)
  end

  def forgot_password_1(map) do
    #message = "Hi, Your OTP for "<>map.phone<>" is: "<>map.otp<>".\n\nRegards \nGruppie."
    message = "Hi, Your school/college app OTP for "<>map.phone<>" is: "<>map.otp<>". Regards, Gruppie."
    #IO.puts "#{message}"
   # send_sms(map, message)
    #send_sms_2(map, message)
    ####send_sms_tl(map, message)
    send_sms_otp_tl(map, message)
  end


  #def forgot_password_2(map) do
  #  message = "Hi, Your OTP for "<>map.phone<>" is: "<>map.otp<>"\n Regards \n Gruppie."
  #  send_sms_2(map, message)
  #end

  def forgot_password_3(map) do
    #IO.puts "#{map}"
    #message = "Hi, Your OTP for "<>map.phone<>" is: "<>map.otp<>".\n\nRegards \nGruppie."
    message = "Hi, Your school/college app OTP for "<>map.phone<>" is: "<>map.otp<>". Regards, Gruppie."
    ####send_sms_tl(%{otp: map.otp, phone: "+919538732882"}, message)
    send_sms_otp_tl(%{otp: map.otp, phone: "+919538732882"}, message)
  end


  def forgot_password_individual_app(map, _appName, smsKey) do
    message = if is_nil(smsKey) do
      #message = appName<>" OTP for "<>map.phone<>" is "<>map.otp<>"."
      #message = appName<>" OTP for "<>map.phone<>" is "<>map.otp<>"."
      "Hi, Your school/college app OTP for "<>map.phone<>" is: "<>map.otp<>". Regards, Gruppie."
    else
      #message = "<#> "<>appName<>" OTP for "<>map.phone<>" is "<>map.otp<>"."
      "Hi, Your school/college app OTP for "<>map.phone<>" is: "<>map.otp<>". Regards, Gruppie."
    end
    #send_sms(map, message)
    ####send_sms_tl(map, message)
    send_sms_otp_tl(map, message)
  end


  #def forgot_password_individual_app_2(map, appName, smsKey) do
  #  if is_nil(smsKey) do
  #    message = appName<>" OTP for "<>map.phone<>" is "<>map.otp<>"."
  #  else
  #    message = "<#> "<>appName<>" OTP for "<>map.phone<>" is "<>map.otp<>". "<>smsKey<>""
  #  end
  #  send_sms_2(map, message)
  #end


  defp send_sms(map, message) do
    new_map = %{numbers: map.phone, message: message}
    query = Map.merge(@auth, new_map)
    link = @sms_url<>URI.encode_query(query)
    case HTTPoison.get(link) do
      {:ok, response}->
        {:ok, response}
      {:error, reason}->
        {:error, reason}
    end
  end


  # defp send_sms_2(map, message) do
  #   new_map = %{mobileno: map.phone, message: message}
  #   query = Map.merge(@auth_2, new_map)
  #   link = @sms_url_2<>URI.encode_query(query)
  #   case HTTPoison.get(link) do
  #     {:ok, response}->
  #       {:ok, response}
  #     {:error, reason}->
  #       {:error, reason}
  #   end
  # end



  # defp send_attendance_sms(map, message) do
  #   joinMap = Enum.join(map.phone, ",")
  #   new_map = %{numbers: joinMap, message: message}
  #   query = Map.merge(@auth, new_map)
  #   link = @sms_url<>URI.encode_query(query)
  #   case HTTPoison.get(link) do
  #     {:ok, response}->
  #       {:ok, response}
  #     {:error, reason}->
  #       {:error, reason}
  #   end
  # end



  # defp send_sms_tl(map, message) do
  #   #IO.puts "#{message}"
  #   #message1 = "Dear parent, \nmeeting tomorrow at 12PM. \nRegards ,\nPrincipal, RPAPUC"
  #   new_map = %{numbers: map.phone, message: message}
  #   query = Map.merge(@auth_3, new_map)
  #   link = @sms_url_textlocal<>URI.encode_query(query)
  #   #test = HTTPoison.get(link)
  #   #IO.puts "#{test}"
  #   case HTTPoison.get(link) do
  #     {:ok, response}->
  #       {:ok, response}
  #     {:error, reason}->
  #       {:error, reason}
  #   end
  # end

  defp send_sms_otp_tl(map, message) do
    #IO.puts "#{message}"
    #message1 = "Dear parent, \nmeeting tomorrow at 12PM. \nRegards ,\nPrincipal, RPAPUC"
    new_map = %{numbers: map.phone, message: message}
    query = Map.merge(@auth_4, new_map)
    link = @sms_url_textlocal<>URI.encode_query(query)
    #test = HTTPoison.get(link)
    #IO.puts "#{test}"
    case HTTPoison.get(link) do
      {:ok, response}->
        {:ok, response}
      {:error, reason}->
        {:error, reason}
    end
  end


  defp send_attendance_sms_tl(map, message) do
    joinMap = Enum.join(map.phone, ",")
    new_map = %{numbers: joinMap, message: message}
    query = Map.merge(@auth_3, new_map)
    link = @sms_url_textlocal<>URI.encode_query(query)
    case HTTPoison.get(link) do
      {:ok, response}->
        {:ok, response}
      {:error, reason}->
        {:error, reason}
    end
  end



end
