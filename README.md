# BloomFilter

A high-performance Elixir implementation of Bloom filters using the blazingly fast [fastbloom](https://github.com/tomtomwombat/fastbloom) Rust library via Rustler NIFs.

## Features

- **Blazingly Fast**: Uses the fastbloom Rust library, which is 2-400x faster than other implementations
- **High Accuracy**: No compromises on accuracy - implements optimal hash functions and sizing
- **Space Efficient**: Probabilistic data structure using minimal memory
- **Thread Safe**: Built with Rust's thread-safe primitives
- **Simple API**: Easy-to-use Elixir interface

## What is a Bloom Filter?

A Bloom filter is a space-efficient probabilistic data structure for membership testing:
- **No false negatives**: If an item was added, `member?/2` will always return `true`
- **Possible false positives**: If an item wasn't added, `member?/2` might return `true` with a probability approximately equal to the configured false positive rate
- **Fixed size**: Memory usage doesn't grow with the number of items (within expected capacity)

## Quick Start

```elixir
# Create a Bloom filter for 1M items with 1% false positive rate
bloom = BloomFilter.new(1_000_000, 0.01)

# Add items
bloom = BloomFilter.add(bloom, "user@example.com")
bloom = BloomFilter.add(bloom, "192.168.1.1")

# Check membership
BloomFilter.member?(bloom, "user@example.com")  # => true
BloomFilter.member?(bloom, "not-added@example.com")  # => false

# Get statistics
stats = BloomFilter.stats(bloom)
# => %{capacity: 1000000, false_positive_rate: 0.01, ...}
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bloom_filter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bloom_filter, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/bloom_filter>.

