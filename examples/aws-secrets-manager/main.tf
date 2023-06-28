# Define out 2 Providers Involved
terraform {
    required_providers {
        confluent = {
            source  = "confluentinc/confluent"
            version = "1.34.0"
        }
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.0"
        }
    }
}

provider "aws" {
    region = "us-east-1"
    profile = "confluent-csid"
}

####
# Lets build out our ENV & Cluster.
# We'll keep it simple, fast, and cheap and create a Single Zone BASIC cluster for this Example.
# You can however create Multi-Zone and/or STANDARD and DEDICATED cluster types instead.
####
resource "confluent_environment" "prod" {
    display_name = "secrets-example"
}

resource "confluent_kafka_cluster" "basic" {
    display_name = "secrets-aws-example-cluster-1"
    availability = "SINGLE_ZONE"
    cloud        = "AWS"
    region       = "us-west-2"
    basic {}

    environment {
        id = confluent_environment.prod.id
    }
}

####
# Next up we need to define out Service Acount that we are going to be using for this example
####
resource "confluent_service_account" "example-sa" {
    display_name = "secrets-aws-example-sa"
    description  = "Service Account for AWS Secrets Example"
}

####
# Now lets get our key rotation going.
# This will create our keys, rotate them in accordance to a time schedule, and provide to us the current active one we should be using.
#
# In this case we are creating a basic API Key to associate and allow a Service Account to login to a Kafka Cluster.
####
module "api-key-rotation" {
    source  = "nerdynick/api-key-rotation/confluent"
    version = "0.0.1"

    #Required Inputs
    owner = {
        id          = confluent_service_account.example-sa.id
        api_version = confluent_service_account.example-sa.api_version
        kind        = confluent_service_account.example-sa.kind
    }

    resource = {
        id          = confluent_kafka_cluster.basic.id
        api_version = confluent_kafka_cluster.basic.api_version
        kind        = confluent_kafka_cluster.basic.kind

        environment = {
            id = confluent_environment.prod.id
        }
    }

    #Optional Inputs
    key_display_name = "Service Account API Key - {date} - Managed by Terraform"
    num_keys_to_retain = 2
    roll_ttl_days = 1
}

####
# Lets store our connection details as a secret.
# This makes configuring our clients even easier.
# These are the Bootstrap Address and the REST Endpoint Address for the Kafka Cluster
####
resource "aws_secretsmanager_secret" "secrets-aws-example-cluster-1-bootstrap" {
    name = "cluster-1-bootstrap"
}

resource "aws_secretsmanager_secret_version" "secrets-aws-example-cluster-1-bootstrap" {
    secret_id     = aws_secretsmanager_secret.secrets-aws-example-cluster-1-bootstrap.id
    secret_string = confluent_kafka_cluster.basic.bootstrap_endpoint
}

resource "aws_secretsmanager_secret" "secrets-aws-example-cluster-1-rest-endpoint" {
    name = "cluster-1-rest-endpoint"
}

resource "aws_secretsmanager_secret_version" "secrets-aws-example-cluster-1-rest-endpoint" {
    secret_id     = aws_secretsmanager_secret.secrets-aws-example-cluster-1-rest-endpoint.id
    secret_string = confluent_kafka_cluster.basic.rest_endpoint
}

####
# Lets store the newly crate Keys in our AWS Secrets Manager.
# We'll store both a JSON version and a JAAS version.
# The JSON version is useful for Non-Java Clients.
# The JAAS version is useful for leveraging the CSID Secrets Accelerator to provide credentials
####
resource "aws_secretsmanager_secret" "example-sa-apikey-json" {
    name = "example-sa-apikey-json"
}

resource "aws_secretsmanager_secret_version" "example-sa-apikey-json" {
    secret_id     = aws_secretsmanager_secret.example-sa-apikey-json.id
    secret_string = jsonencode(module.api-key-rotation.active_key)
}

resource "aws_secretsmanager_secret" "example-sa-apikey-jaas" {
    name = "example-sa-apikey-jaas"
}

resource "aws_secretsmanager_secret_version" "example-sa-apikey-jaas" {
    secret_id     = aws_secretsmanager_secret.example-sa-apikey-jaas.id
    secret_string = "org.apache.kafka.common.security.plain.PlainLoginModule required username='${module.api-key-rotation.active_key.id}' password='${module.api-key-rotation.active_key.secret}';"
}