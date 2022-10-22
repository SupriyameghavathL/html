defmodule GruppieWeb.ChangePassword do
  use Ecto.Schema
  import Ecto.Changeset

  schema "change_password" do
    field :oldPassword, :string
    field :newPasswordFirst, :string
    field :newPasswordSecond, :string
    field :password, :string
    field :confirmPassword, :string
    field :countryCode, :string
    field :phone, :string
    field :otp, :string
  end

  def changeset_password_change(struct, params \\%{}) do
    struct
    |> cast(params, [:oldPassword, :newPasswordFirst, :newPasswordSecond])
    |> validate_required(:newPasswordSecond, [message: "Repeat Password Must Not be Empty "])
    |> validate_required(:newPasswordFirst, [message: "Enter The New Password"])
    |> validate_required(:oldPassword, [message: "Enter The Current Password"])
    |> compare_new_passwords
  end


  def changeset_create_password(struct, params \\%{}) do
    struct
    |> cast(params, [:password, :confirmPassword, :countryCode, :phone, :otp])
    |> validate_required(:confirmPassword, [message: "Please Confirm Your Password"])
    |> validate_required(:password, [message: "Password Must Not be Empty"])
    |> compare_passwords
    |> e164_mobile_number_format
  end

  defp compare_new_passwords(struct) do
    password_first = get_field(struct, :newPasswordFirst)
    password_second = get_field(struct, :newPasswordSecond)
    if (password_first == password_second) do
      struct
    else
      add_error(struct, :newPasswordFirst, "Password Doesn't Match")
    end
  end

  defp compare_passwords(struct) do
    password_first = get_field(struct, :password)
    password_second = get_field(struct, :confirmPassword)
    if (password_first == password_second) do
      struct
    else
      add_error(struct, :password, "Password Doesn't Match")
    end
  end



  defp e164_mobile_number_format(struct) do
    if struct.valid? do
      countryCode = get_field(struct, :countryCode) #get required valuen from struct
      phone = get_field(struct, :phone)
      if is_nil(countryCode) || is_nil(phone) do
        struct
      else
        case ExPhoneNumber.parse(phone, countryCode) do
          {:ok, phone_number}->
           # if ExPhoneNumber.is_valid_number?(phone_number) do
              e164_number = ExPhoneNumber.format(phone_number, :e164)
              struct
              |> delete_change(:countryCode)
              |> put_change(:phone, e164_number)
           # else
           #   add_error(struct, :phone, "Invalid Phone Number")
           # end
          {:error, _}->
            add_error(struct, :phone, "Invalid Phone Number Or Country")
        end
      end
    else
      struct
    end
  end

end
