output "active_key" {
    value = confluent_api_key.kafka-api-key[local.latest_key]
    description = "The current active API Key to be used for new logins"
}

output "all_keys" {
    value = [for d in local.sorted_dates : confluent_api_keykafka-api-key[lookup(local.dates_and_count, d)] ]
    description = "All API keys being maintained organized by creation date. With the current active API Key being the 1st in the collection."
}