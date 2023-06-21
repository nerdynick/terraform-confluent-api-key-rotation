variable "roll_ttl_days" {
    type = number
    default = 1
    description = "How many days should we rotate the API Key"
}

variable "num_keys_to_retain" {
    type = number
    default = 2
    description = "Counting the current active key. How many keys should be retained for historical sake and to allow applications to pickup new keys."
}

variable "key_display_name" {
    type = string
    default = "Service Account API Key - Managed by Terraform"
    description = "A discriptive name for the API key. If you put `{date}` in the string. The Date of API Key creation will be replace into the string at that location."
}

variable "owner" {
    type = object({
        id = string
        api_version = string
        kind = string
    })
    description = "API Key Owner. See [Confluent API Key Docs](https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_api_key#argument-reference) for more details"
}

variable "resource" {
    type = object({
        id = string
        api_version = string
        kind = string
        environment = object({
            id = string
        })
    })
    description = "Resource the API Key is associated with. See [Confluent API Key Docs](https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_api_key#argument-reference) for more details"
}