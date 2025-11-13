defmodule BloomFilterEx.Native do
  @moduledoc false
  version = Mix.Project.config()[:version]
  source_url = Mix.Project.config()[:source_url]

  use RustlerPrecompiled,
    otp_app: :bloom_filter_ex,
    crate: :bloomfilternif,
    base_url: "#{source_url}/releases/download/v#{version}",
    force_build: System.get_env("BLOOM_FILTER_BUILD") in ["1", "true"],
    version: version,
    targets: [
      "aarch64-apple-darwin",
      "aarch64-unknown-linux-gnu",
      "aarch64-unknown-linux-musl",
      "x86_64-apple-darwin",
      "x86_64-unknown-linux-gnu",
      "x86_64-unknown-linux-musl"
    ],
    nif_versions: ["2.17", "2.16"]

  def new(_capacity, _false_positive_rate), do: :erlang.nif_error(:nif_not_loaded)
  def add(_resource, _item), do: :erlang.nif_error(:nif_not_loaded)
  def member(_resource, _item), do: :erlang.nif_error(:nif_not_loaded)
  def clear(_resource), do: :erlang.nif_error(:nif_not_loaded)
  def stats(_resource), do: :erlang.nif_error(:nif_not_loaded)
end
