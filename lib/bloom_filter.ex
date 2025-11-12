defmodule BloomFilter do
  @moduledoc """
  A space-efficient probabilistic data structure for membership testing.

  A Bloom filter can tell you with certainty that an item has **not** been seen,
  but can only tell you with high probability that an item **has** been seen
  (there is a small chance of false positives).

  This implementation uses the blazingly fast [fastbloom](https://github.com/tomtomwombat/fastbloom)
  Rust library, which provides:
  - Optimal sizing formulas: `m = -n × ln(p) / (ln(2))²` and `k = (m/n) × ln(2)`
  - Double hashing (Kirsch-Mitzenmacher 2006): generates k hash functions from 2
  - Hash composition: derives multiple hash functions from a single source hash
  - Highly optimized bit array operations for maximum performance

  ## Examples

      # Create a Bloom filter for 1M items with 1% false positive rate
      iex> bloom = BloomFilter.new(1_000_000, 0.01)
      iex> bloom.size > 9_500_000
      true
      iex> bloom.hash_count
      6

      # Add items
      iex> bloom = BloomFilter.new(1000, 0.01)
      iex> bloom = BloomFilter.add(bloom, "user@example.com")
      iex> bloom = BloomFilter.add(bloom, "192.168.1.1")
      iex> BloomFilter.member?(bloom, "user@example.com")
      true
      iex> BloomFilter.member?(bloom, "not-added@example.com")
      false

      # Check statistics
      iex> bloom = BloomFilter.new(100, 0.01)
      iex> bloom = BloomFilter.add(bloom, "item1")
      iex> stats = BloomFilter.stats(bloom)
      iex> stats.inserted_count
      1
      iex> stats.capacity
      100

  ## No False Negatives

  If an item was added to the filter, `member?/2` will **always** return `true`.

  ## False Positives

  If an item was NOT added, `member?/2` might return `true` (false positive) with
  probability approximately equal to the configured false positive rate.

  ## Memory Usage

  For a 1% false positive rate, the filter uses approximately 9.6 bits per item.
  Examples:
  - 1,000 items @ 1% FPR: ~1.2 KB
  - 1,000,000 items @ 1% FPR: ~1.2 MB
  - 10,000,000 items @ 1% FPR: ~12 MB

  ## References

  - Bloom, B. H. (1970). "Space/time trade-offs in hash coding with allowable errors"
  - Kirsch, A. and Mitzenmacher, M. (2006). "Less Hashing, Same Performance: Building a Better Bloom Filter"
  """

  alias BloomFilter.Native

  defstruct [:resource, :size, :hash_count, :capacity, :false_positive_rate, :inserted_count]

  @type t :: %__MODULE__{
          resource: reference(),
          size: pos_integer(),
          hash_count: pos_integer(),
          capacity: pos_integer(),
          false_positive_rate: float(),
          inserted_count: non_neg_integer()
        }

  @doc """
  Creates a new Bloom filter optimized for the expected capacity and desired false positive rate.

  ## Parameters

  - `capacity`: Expected number of items to be inserted (n)
  - `false_positive_rate`: Desired false positive probability (p), between 0.0 and 1.0

  ## Returns

  A new Bloom filter struct with optimally calculated bit array size and hash count.

  ## Examples

      iex> bloom = BloomFilter.new(1000, 0.01)
      iex> bloom.size > 0
      true
      iex> bloom.hash_count > 0
      true
      iex> bloom.inserted_count
      0

      iex> bloom = BloomFilter.new(10_000, 0.001)
      iex> bloom.hash_count
      9

  """
  @spec new(pos_integer(), float()) :: t()
  def new(capacity, false_positive_rate)
      when is_integer(capacity) and capacity > 0 and
             is_float(false_positive_rate) and false_positive_rate > 0.0 and
             false_positive_rate < 1.0 do
    {:ok, resource} = Native.new(capacity, false_positive_rate)
    {:ok, {size, hash_count, fpr, inserted_count}} = Native.stats(resource)

    %__MODULE__{
      resource: resource,
      size: size,
      hash_count: hash_count,
      capacity: capacity,
      false_positive_rate: fpr,
      inserted_count: inserted_count
    }
  end

  @doc """
  Adds an item to the Bloom filter.

  This operation sets k bits in the bit array (where k is the hash_count).
  The item can be any Erlang term.

  ## Parameters

  - `bloom_filter`: The Bloom filter to add to
  - `item`: Any Erlang term to add

  ## Returns

  Updated Bloom filter with the item added.

  ## Examples

      iex> bloom = BloomFilter.new(100, 0.01)
      iex> bloom = BloomFilter.add(bloom, "test-item")
      iex> bloom.inserted_count
      1
      iex> BloomFilter.member?(bloom, "test-item")
      true

      iex> bloom = BloomFilter.new(100, 0.01)
      iex> bloom = bloom |> BloomFilter.add(1) |> BloomFilter.add(2)
      iex> bloom.inserted_count
      2

  """
  @spec add(t(), term()) :: t()
  def add(%__MODULE__{resource: resource} = bloom, item) do
    # Convert item to string for the NIF
    item_string = :erlang.term_to_binary(item) |> Base.encode64()
    {:ok, new_resource} = Native.add(resource, item_string)
    %{bloom | resource: new_resource, inserted_count: bloom.inserted_count + 1}
  end

  @doc """
  Checks if an item is possibly in the Bloom filter.

  ## Returns

  - `true`: The item was probably added (or is a false positive)
  - `false`: The item was definitely NOT added (no false negatives)

  ## Examples

      iex> bloom = BloomFilter.new(100, 0.01)
      iex> bloom = BloomFilter.add(bloom, "exists")
      iex> BloomFilter.member?(bloom, "exists")
      true
      iex> BloomFilter.member?(bloom, "does-not-exist")
      false

  """
  @spec member?(t(), term()) :: boolean()
  def member?(%__MODULE__{resource: resource}, item) do
    # Convert item to string for the NIF
    item_string = :erlang.term_to_binary(item) |> Base.encode64()
    {:ok, result} = Native.member(resource, item_string)
    result
  end

  @doc """
  Clears the Bloom filter, resetting it to empty state.

  ## Examples

      iex> bloom = BloomFilter.new(100, 0.01)
      iex> bloom = BloomFilter.add(bloom, "test")
      iex> bloom.inserted_count
      1
      iex> bloom = BloomFilter.clear(bloom)
      iex> bloom.inserted_count
      0
      iex> BloomFilter.member?(bloom, "test")
      false

  """
  @spec clear(t()) :: t()
  def clear(%__MODULE__{resource: resource} = bloom) do
    {:ok, new_resource} = Native.clear(resource)
    %{bloom | resource: new_resource, inserted_count: 0}
  end

  @doc """
  Returns statistics about the Bloom filter.

  ## Returns

  A map containing:
  - `size`: Total number of bits in the filter
  - `hash_count`: Number of hash functions used
  - `capacity`: Expected capacity
  - `false_positive_rate`: Target false positive rate
  - `inserted_count`: Number of items inserted
  - `saturation`: Percentage of bits set (0.0 to 100.0)
  - `estimated_fpr`: Estimated actual false positive rate based on saturation

  ## Examples

      iex> bloom = BloomFilter.new(100, 0.01)
      iex> stats = BloomFilter.stats(bloom)
      iex> stats.capacity
      100
      iex> stats.saturation
      0.0

  """
  @spec stats(t()) :: map()
  def stats(%__MODULE__{resource: resource, capacity: capacity}) do
    {:ok, {size, hash_count, false_positive_rate, inserted_count}} =
      Native.stats(resource)

    # For now, we don't have bits_set from the Rust side
    # Calculate estimated saturation based on inserted items
    # Expected saturation: (1 - e^(-k*n/m))
    # where k = hash_count, n = inserted_count, m = size
    expected_saturation =
      if inserted_count > 0 do
        (1 - :math.exp(-hash_count * inserted_count / size)) * 100.0
      else
        0.0
      end

    # Estimated FPR based on saturation: (1 - e^(-k*n/m))^k
    estimated_fpr = :math.pow(expected_saturation / 100.0, hash_count)

    %{
      size: size,
      hash_count: hash_count,
      capacity: capacity,
      false_positive_rate: false_positive_rate,
      inserted_count: inserted_count,
      saturation: expected_saturation,
      estimated_fpr: estimated_fpr,
      bits_set: round(expected_saturation * size / 100.0)
    }
  end
end
