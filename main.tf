terraform {
    required_providers {
        confluent = {
            source  = "confluentinc/confluent"
            version = "1.34.0"
        }
    }
}

provider "confluent" {
}

locals {
    now = timestamp()
    ttl_in_hours = var.roll_ttl_days*24

    sorted_dates = sort(time_rotating.api_key_rotations.*.rfc3339)
    dates_and_count = zipmap(time_rotating.api_key_rotations.*.rfc3339, range(var.num_keys_to_retain))
    latest_key = lookup(local.dates_and_count, local.sorted_dates[0])
}

# This controls each key's rotations
resource "time_rotating" "api_key_rotations" {
    count = var.num_keys_to_retain
    rotation_days = var.roll_ttl_days*var.num_keys_to_retain

    rfc3339 = timeadd(local.now, format("-%sh", (count.index+1)*local.ttl_in_hours))
}

# We stash the value in a static store in order to trigger a `replace_triggered_by` on the API Key
# See: https://github.com/hashicorp/terraform-provider-time/issues/118
resource "time_static" "api_key_rotations" {
    count = var.num_keys_to_retain
    rfc3339 = time_rotating.api_key_rotations[count.index].rfc3339
}

####
# Here's where we get into the real details for the example.
# We need to 1st have an Account to Create API Credentials for.
# In this case we are going to leverage a Service Account.
####
resource "confluent_api_key" "kafka-api-key" {
    count = var.num_keys_to_retain
    display_name = replace(var.key_display_name, "{date}", time_static.api_key_rotations[count.index])
    description  = "API Key managed by Terraform using Confluent API Key Rotation Module"

    owner {
        id          = var.owner.id
        api_version = var.owner.api_version
        kind        = var.owner.kind
    }

    managed_resource {
        id          = var.resource.id
        api_version = var.resource.api_version
        kind        = var.resource.kind

        environment {
            id = var.resource.environment.id
        }
    }

    lifecycle {
        replace_triggered_by = [time_static.api_key_rotations[count.index]]
    }
}