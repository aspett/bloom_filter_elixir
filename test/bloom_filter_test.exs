defmodule BloomFilterExTest do
  use ExUnit.Case
  doctest BloomFilterEx

  test "basic bloom filter operations" do
    bloom = BloomFilterEx.new(1000, 0.01)
    assert bloom.capacity == 1000
    assert_in_delta bloom.false_positive_rate, 0.01, 0.0001
    assert bloom.inserted_count == 0

    bloom = BloomFilterEx.add(bloom, "test_item")
    assert BloomFilterEx.member?(bloom, "test_item") == true
    assert BloomFilterEx.member?(bloom, "not_in_filter") == false

    bloom = BloomFilterEx.clear(bloom)
    assert bloom.inserted_count == 0
    assert BloomFilterEx.member?(bloom, "test_item") == false
  end
end
