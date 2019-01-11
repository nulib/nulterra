data "external" "ecs_domain_client" {
  program = ["external/es_domain_client"]

  query = {
    domain_name = "${aws_elasticsearch_domain.elasticsearch.domain_name}"
  }
}

resource "aws_cloudwatch_dashboard" "nul_metrics" {
  dashboard_name = "${local.namespace}-nul-metrics"
  dashboard_body = <<__EOF__
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "NUL",
            "DockerDataUsedPct",
            "Environment",
            "${local.namespace}-arch-ui-worker",
            { "label": "arch-ui-worker", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-arch-webapp",
            { "label": "arch-webapp", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-avr-batch-worker",
            { "label": "avr-batch-worker", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-avr-ui-worker",
            { "label": "avr-ui-worker", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-avr-webapp",
            { "label": "avr-webapp", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-donut-batch-worker",
            { "label": "donut-batch-worker", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-donut-ui-worker",
            { "label": "donut-ui-worker", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-donut-webapp",
            { "label": "donut-webapp", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-fcrepo",
            { "label": "fcrepo", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-solr",
            { "label": "solr", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-zookeeper",
            { "label": "zookeeper", "stat": "Maximum" }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "title": "Docker Data Used %",
        "period": 300
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "NUL",
            "RootDeviceUsedPct",
            "Environment",
            "${local.namespace}-arch-ui-worker",
            { "label": "arch-ui-worker", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-arch-webapp",
            { "label": "arch-webapp", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-avr-batch-worker",
            { "label": "avr-batch-worker", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-avr-ui-worker",
            { "label": "avr-ui-worker", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-avr-webapp",
            { "label": "avr-webapp", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-donut-batch-worker",
            { "label": "donut-batch-worker", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-donut-ui-worker",
            { "label": "donut-ui-worker", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-donut-webapp",
            { "label": "donut-webapp", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-fcrepo",
            { "label": "fcrepo", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-solr",
            { "label": "solr", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-zookeeper",
            { "label": "zookeeper", "stat": "Maximum" }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "title": "Root Device Used %",
        "period": 300
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 6,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "NUL",
            "MemoryBytesUsed",
            "Environment",
            "${local.namespace}-arch-ui-worker",
            { "label": "arch-ui-worker", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-arch-webapp",
            { "label": "arch-webapp", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-avr-batch-worker",
            { "label": "avr-batch-worker", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-avr-ui-worker",
            { "label": "avr-ui-worker", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-avr-webapp",
            { "label": "avr-webapp", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-donut-batch-worker",
            { "label": "donut-batch-worker", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-donut-ui-worker",
            { "label": "donut-ui-worker", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-donut-webapp",
            { "label": "donut-webapp", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-fcrepo",
            { "label": "fcrepo", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-solr",
            { "label": "solr", "stat": "Maximum" }
          ],
          [
            "...",
            "${local.namespace}-zookeeper",
            { "label": "zookeeper", "stat": "Maximum" }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "title": "Memory in Use",
        "period": 300
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 6,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "NUL/Solr",
            "DocumentCount",
            "Collection",
            "arch",
            { "label": "arch" }
          ],
          [
            "...",
            "avr",
            { "label": "avr" }
          ],
          [
            "...",
            "donut",
            { "label": "donut" }
          ],
          [
            "AWS/ES",
            "SearchableDocuments",
            "DomainName",
            "${aws_elasticsearch_domain.elasticsearch.domain_name}",
            "ClientId",
            "${data.external.ecs_domain_client.result.client_id}",
            { "label": "common index" }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "title": "Indexed Documents",
        "period": 300
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 15,
      "width": 24,
      "height": 3,
      "properties": {
        "metrics": [
          [
            "NUL/Solr",
            "DocumentCount",
            "Model",
            "Admin::Collection",
            "Collection",
            "avr",
            { "label": "Collections" }
          ],
          [
            "...",
            "MediaObject",
            ".",
            ".",
            { "label": "MediaObjects" }
          ],
          [
            "...",
            "MasterFile",
            ".",
            ".",
            { "label": "MasterFiles" }
          ],
          [
            "...",
            "Derivative",
            ".",
            ".",
            { "label": "Derivatives" }
          ],
          [
            ".",
            "ActiveReplicaCount",
            "Collection",
            "avr",
            "Shard",
            "shard1",
            { "label": "Active Replicas" }
          ]
        ],
        "view": "singleValue",
        "region": "us-east-1",
        "title": "AVR Data",
        "period": 300
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 18,
      "width": 24,
      "height": 3,
      "properties": {
        "metrics": [
          [
            "NUL/Solr",
            "DocumentCount",
            "Model",
            "AdminSet",
            "Collection",
            "donut",
            { "label": "Admin Sets" }
          ],
          [
            "...",
            "Collection",
            ".",
            ".",
            { "label": "Collections" }
          ],
          [
            "...",
            "Image",
            ".",
            ".",
            { "label": "Images" }
          ],
          [
            "...",
            "FileSet",
            ".",
            ".",
            { "label": "FileSets" }
          ],
          [
            ".",
            "ActiveReplicaCount",
            "Collection",
            "donut",
            "Shard",
            "shard1",
            { "label": "Active Replicas" }
          ]
        ],
        "view": "singleValue",
        "region": "us-east-1",
        "title": "Donut Data",
        "period": 300
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 12,
      "width": 24,
      "height": 3,
      "properties": {
        "metrics": [
          [
            "NUL/Solr",
            "DocumentCount",
            "Model",
            "AdminSet",
            "Collection",
            "arch",
            { "label": "Admin Sets" }
          ],
          [
            "...",
            "Collection",
            ".",
            ".",
            { "label": "Collections" }
          ],
          [
            "...",
            "GenericWork",
            ".",
            ".",
            { "label": "Works" }
          ],
          [
            "...",
            "FileSet",
            ".",
            ".",
            { "label": "FileSets" }
          ],
          [
            ".",
            "ActiveReplicaCount",
            "Collection",
            "arch",
            "Shard",
            "shard1",
            { "label": "Active Replicas" }
          ]
        ],
        "view": "singleValue",
        "region": "us-east-1",
        "title": "Arch Data",
        "period": 300
      }
    }
  ]
}
  __EOF__
}
