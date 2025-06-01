defmodule RainerBlogBackendWeb.Types.BaseResponse do
  @derive {Jason.Encoder, only: [:code, :message, :data]}
  defstruct code: 200, message: "success", data: nil

  @spec generate(integer(), String.t(), any()) :: %__MODULE__{}
  def generate(code, message, data) do
    %__MODULE__{
      code: code,
      message: message,
      data: data
    }
  end
end
