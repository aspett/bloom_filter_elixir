use rustler::{Env, Resource, ResourceArc};
use fastbloom::BloomFilter;
use std::sync::RwLock;

// Hold the bloom filter in memory through Rust rather than Elixir.
pub struct BloomFilterResource {
    filter: RwLock<BloomFilter>,
    capacity: usize,
    false_positive_rate: f32,
    inserted_count: RwLock<usize>
}

impl Resource for BloomFilterResource {}

impl BloomFilterResource {
    fn new(capacity: usize, false_positive_rate: f32) -> Self {
        let filter = BloomFilter::with_false_pos(false_positive_rate as f64)
            .expected_items(capacity);

        BloomFilterResource {
            filter: RwLock::new(filter),
            capacity,
            false_positive_rate,
            inserted_count: RwLock::new(0),
        }
    }
}

fn on_load(env: Env, _info: rustler::Term) -> bool {
    env.register::<BloomFilterResource>().is_ok()
}

#[rustler::nif]
fn new(capacity: usize, false_positive_rate: f32) -> Result<ResourceArc<BloomFilterResource>, String> {
    if capacity == 0 {
        return Err("Capacity must be greater than 0".to_string());
    }
    if false_positive_rate <= 0.0 || false_positive_rate >= 1.0 {
        return Err("False positive rate must be between 0.0 and 1.0".to_string());
    }

    Ok(ResourceArc::new(BloomFilterResource::new(capacity, false_positive_rate)))
}

#[rustler::nif]
fn add(resource: ResourceArc<BloomFilterResource>, item: String) -> Result<ResourceArc<BloomFilterResource>, String> {
    {
        let mut filter = resource.filter.write().map_err(|e| format!("Lock error: {}", e))?;
        let mut count = resource.inserted_count.write().map_err(|e| format!("Lock error: {}", e))?;

        filter.insert(&item);
        *count += 1;
    } // Locks are dropped here

    Ok(resource)
}

#[rustler::nif]
fn member(resource: ResourceArc<BloomFilterResource>, item: String) -> Result<bool, String> {
    let filter = resource.filter.read().map_err(|e| format!("Lock error: {}", e))?;
    Ok(filter.contains(&item))
}

#[rustler::nif]
fn clear(resource: ResourceArc<BloomFilterResource>) -> Result<ResourceArc<BloomFilterResource>, String> {
    {
        let mut filter = resource.filter.write().map_err(|e| format!("Lock error: {}", e))?;
        let mut count = resource.inserted_count.write().map_err(|e| format!("Lock error: {}", e))?;

        *filter = BloomFilter::with_false_pos(resource.false_positive_rate as f64)
            .expected_items(resource.capacity);
        *count = 0;
    } // Locks are dropped here

    Ok(resource)
}

#[rustler::nif]
fn stats(resource: ResourceArc<BloomFilterResource>) -> Result<(usize, usize, f32, usize), String> {
    let filter = resource.filter.read().map_err(|e| format!("Lock error: {}", e))?;
    let count = resource.inserted_count.read().map_err(|e| format!("Lock error: {}", e))?;
    Ok((filter.num_bits(), filter.num_hashes() as usize, resource.false_positive_rate, *count))
}

rustler::init!("Elixir.BloomFilter.Native", load = on_load);
