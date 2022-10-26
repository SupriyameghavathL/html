defmodule GruppieWeb.ConstituencyAnalysis do
  use Ecto.Schema
  import Ecto.Changeset
  import GruppieWeb.Handler.TimeNow

  @primary_key{:id, :binary_id, autogenerate: true}

  @add_fields [:name, :zpIncharge, :phone, :countryCode, :image]

  @update_fields [:name, :zpIncharge, :phone, :countryCode, :image]

  schema "zillaPanchayat" do
    field :name, :string
    field :countryCode, :string
    field :zpIncharge, :string
    field :phone, :string
    field :image, :string
    field :insertedAt, :string
    field :updatedAt, :string
    field :isActive, :boolean
  end


  #zillaPanchayat,tp,ward add
  def changeset_add_zp_tp(struct, params \\%{}) do
  struct
  |> cast(params, @add_fields)
  |> validate_required(:name, [message: "Name Must Not Be Empty"])
  |> validate_required(:zpIncharge, [message: "ZP Name Must Not Be Empty"])
  |> validate_required(:phone, [message: "Phone No is Required "])
  |> set_time()
  |> valid_phone_number
  |> put_change(:isActive, true)
  end

  #zillaPanchayat,tp,ward edit
  def changeset_edit_zp_tp(struct, params \\%{})  do
    struct
    |> cast(params, @update_fields)
    |> validate_required(:name, [message: "Name Must Not Be Empty"])
    |> validate_required(:zpIncharge, [message: "ZP Name Must Not Be Empty"])
    |> validate_required(:phone, [message: "Phone No is Required "])
    |> set_time()
    |> valid_phone_number
  end


  #check phone is valid or not
  defp valid_phone_number(struct) do
    if struct.valid? do
      countryCode = get_field(struct, :countryCode) #get_field used to get values from struct
      phone = get_field(struct, :phone)
      case ExPhoneNumber.parse(phone, countryCode) do
        {:ok, phone_number} ->
          e164_number = ExPhoneNumber.format(phone_number, :e164)
          struct
          |> delete_change(:countryCode)
          |> put_change(:phone, e164_number)
        {:error, _}->
          add_error(struct, :phone, "Invalid CountryCode/Phone Given")
      end
    else
      struct
    end
  end


  defp set_time(struct) do
    struct
    |> put_change( :insertedAt, bson_time() )
    |> put_change( :updatedAt, bson_time() )
  end
end
