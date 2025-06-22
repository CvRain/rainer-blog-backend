defmodule RainerBlogBackend.AwsService do
  require Logger
  alias RainerBlogBackend.UserConfig

  @doc """
  Initializes the ExAws configuration from CubDB.
  This should be called when the application starts.
  """
  def init_config do
    Logger.info("Initializing AWS configuration...")

    with %{
           access_key_id: access_key_id,
           secret_access_key: secret_access_key,
           region: region
         } <- UserConfig.get_aws_config() do
      if access_key_id != "" and secret_access_key != "" and region != "" do
        new_config = [
          access_key_id: access_key_id,
          secret_access_key: secret_access_key,
          region: region
        ]

        # Merges the new config into the global ExAws configuration
        :ok = ExAws.Config.put(:default, new_config)
        Logger.info("AWS configuration loaded successfully.")
      else
        Logger.warn("AWS configuration is missing from UserConfig. S3 operations will fail.")
      end
    else
      _ -> Logger.error("Failed to get AWS configuration from UserConfig.")
    end
  end

  @doc """
  Uploads a file to the S3 bucket specified in the config.

  - `file_path`: The local path to the file to upload.
  - `s3_path`: The destination path and filename in the S3 bucket.
  """
  def upload_file(file_path, s3_path) do
    bucket = UserConfig.get_aws_config()[:bucket]

    if bucket == "" do
      Logger.error("S3 bucket is not configured.")
      {:error, :bucket_not_configured}
    else
      Logger.info("Uploading #{file_path} to S3 bucket '#{bucket}' at #{s3_path}...")
      # ExAws.S3.put_object(bucket, s3_path, File.stream!(file_path))
      # |> ExAws.request()
      Logger.warn("S3 upload functionality is not yet fully implemented.")
      {:ok, "Upload not implemented"}
    end
  end
end
