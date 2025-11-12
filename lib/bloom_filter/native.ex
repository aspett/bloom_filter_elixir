defmodule BloomFilter.Native do
  @moduledoc false
  version = Mix.Project.config()[:version]

  use RustlerPrecompiled,
    otp_app: :bloom_filter,
    crate: :bloomfilternif, base_url:
      "https://github.com/aspett/bloom_filter_elixir/releases/download/v#{version}",
    force_build: System.get_env("RUSTLER_PRECOMPILATION_BLOOM_FILTER_BUILD") in ["1", "true"],
    version: version

  def new(_capacity, _false_positive_rate), do: :erlang.nif_error(:nif_not_loaded)
  def add(_resource, _item), do: :erlang.nif_error(:nif_not_loaded)
  def member(_resource, _item), do: :erlang.nif_error(:nif_not_loaded)
  def clear(_resource), do: :erlang.nif_error(:nif_not_loaded)
  def stats(_resource), do: :erlang.nif_error(:nif_not_loaded)
end
