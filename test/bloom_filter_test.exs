defmodule BloomFilterTest do
  use ExUnit.Case
  doctest BloomFilter

  test "basic bloom filter operations" do
    bloom = BloomFilter.new(1000, 0.01)
    assert bloom.capacity == 1000
    assert_in_delta bloom.false_positive_rate, 0.01, 0.0001
    assert bloom.inserted_count == 0

    bloom = BloomFilter.add(bloom, "test_item")
    assert BloomFilter.member?(bloom, "test_item") == true
    assert BloomFilter.member?(bloom, "not_in_filter") == false

    bloom = BloomFilter.clear(bloom)
    assert bloom.inserted_count == 0
    assert BloomFilter.member?(bloom, "test_item") == false
  end
end
