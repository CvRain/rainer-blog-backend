defmodule RainerBlogBackend.AwsService do
  require Logger
  alias RainerBlogBackend.UserConfig

  @doc """
  Initializes the ExAws configuration from CubDB.
  This should be called when the application starts.
  """
  def init_config do
    Logger.info("Initializing AWS/OBS configuration...")

    with %{
           access_key_id: access_key_id,
           secret_access_key: secret_access_key,
           region: region,
           bucket: _bucket,
           endpoint: endpoint
         } <- RainerBlogBackend.UserConfig.get_aws_config() do
      if access_key_id != "" and secret_access_key != "" and region != "" and endpoint != "" do
        Application.put_env(:ex_aws, :access_key_id, access_key_id)
        Application.put_env(:ex_aws, :secret_access_key, secret_access_key)
        Application.put_env(:ex_aws, :region, region)
        Application.put_env(:ex_aws, :s3, [
          scheme: "https://",
          host: endpoint,
          region: region
        ])
        Logger.info("AWS/OBS configuration loaded successfully.")
      else
        Logger.warning("AWS/OBS configuration is missing from UserConfig. S3 operations will fail.")
      end
    else
      _ -> Logger.error("Failed to get AWS/OBS configuration from UserConfig.")
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
      Logger.warning("S3 upload functionality is not yet fully implemented.")
      {:ok, "Upload not implemented"}
    end
  end

  @doc """
  直接上传字符串内容到 S3，返回 aws_key
  - content: 文件内容
  - s3_path: S3 路径
  """
  def upload_content(content, s3_path) do
    bucket = UserConfig.get_aws_config()[:bucket]
    if bucket == "" do
      Logger.error("S3 bucket is not configured.")
      {:error, :bucket_not_configured}
    else
      Logger.info("Uploading content to S3 bucket '#{bucket}' at #{s3_path}...")
      case ExAws.S3.put_object(bucket, s3_path, content) |> ExAws.request() do
        {:ok, _resp} -> {:ok, s3_path}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  根据aws_key从S3下载内容
  """
  def download_content(s3_path) do
    bucket = UserConfig.get_aws_config()[:bucket]
    if bucket == "" do
      Logger.error("S3 bucket is not configured.")
      {:error, :bucket_not_configured}
    else
      Logger.info("Downloading content from S3 bucket '#{bucket}' at #{s3_path}...")
      case ExAws.S3.get_object(bucket, s3_path) |> ExAws.request() do
        {:ok, %{body: body}} -> {:ok, body}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  删除S3上的文件
  """
  def delete_content(s3_path) do
    bucket = UserConfig.get_aws_config()[:bucket]
    if bucket == "" do
      Logger.error("S3 bucket is not configured.")
      {:error, :bucket_not_configured}
    else
      Logger.info("Deleting content from S3 bucket '#{bucket}' at #{s3_path}...")
      case ExAws.S3.delete_object(bucket, s3_path) |> ExAws.request() do
        {:ok, _} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  生成S3对象的预签名URL
  - s3_path: S3路径
  - expires_in: 过期时间（秒），默认3600秒（1小时）
  """
  def generate_presigned_url(s3_path, expires_in \\ 3600) do
    bucket = UserConfig.get_aws_config()[:bucket]
    if bucket == "" do
      Logger.error("S3 bucket is not configured.")
      {:error, :bucket_not_configured}
    else
      try do
        # 生成预签名URL
        url = ExAws.S3.presigned_url(
          ExAws.Config.new(:s3),
          :get,
          bucket,
          s3_path,
          expires_in: expires_in
        )
        {:ok, url}
      rescue
        e ->
          Logger.error("Error generating presigned URL: #{inspect(e)}")
          {:error, :url_generation_failed}
      end
    end
  end

  @doc """
  获取S3对象的Base64编码内容
  - s3_path: S3路径
  """
  def get_base64_content(s3_path) do
    case download_content(s3_path) do
      {:ok, content} ->
        base64_content = Base.encode64(content)
        {:ok, base64_content}
      {:error, reason} ->
        {:error, reason}
    end
  end
end