# Configure the Sumo Logic Provider
# export SUMOLOGIC_ACCESSID=$SUMO_ACCESS_ID
# export SUMOLOGIC_ACCESSKEY=$SUMO_ACCESS_KEY
# export SUMOLOGIC_ENVIRONMENT=au

terraform {
  required_providers {
    sumologic = {
      source = "SumoLogic/sumologic"
      version = "2.3.0"
    }
  }
}

#provider "sumologic" {
#    access_id   = "var.sumologic_access_id"
#    access_key  = "var.sumologic_access_key"
#    environment  = "au"
#}

# Create a collector
resource "sumologic_collector" "tfcollector" {
    name = "MyTerraformCollector"
    timezone = "Etc/UTC"
}

# Create a HTTP source
resource "sumologic_http_source" "tfhttp_source" {
    name         = "MyTerraformHTTPSource"
    category     = "my/source/category"
    collector_id = "${sumologic_collector.tfcollector.id}"
}

# test an impmort
# terraform import sumologic_collector.test 106838358
resource "sumologic_collector" "test" {
    name         = "test"
    timezone = "Etc/UTC"
}