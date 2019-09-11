resource "aws_cloudwatch_dashboard" "nul_metrics" {
  lifecycle {
    ignore_changes = ["dashboard_body"]
  }

  dashboard_name = "${local.namespace}-nul-metrics"

  dashboard_body = <<__EOF__
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 15,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "NUL",
            "DockerDataUsedPct",
            "Environment",
            "${local.namespace}-arch-ui-worker",
            {
              "label": "arch-ui-worker",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-arch-webapp",
            {
              "label": "arch-webapp",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-avr-batch-worker",
            {
              "label": "avr-batch-worker",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-avr-ui-worker",
            {
              "label": "avr-ui-worker",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-avr-webapp",
            {
              "label": "avr-webapp",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-donut-batch-worker",
            {
              "label": "donut-batch-worker",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-donut-ui-worker",
            {
              "label": "donut-ui-worker",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-donut-webapp",
            {
              "label": "donut-webapp",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-fcrepo",
            {
              "label": "fcrepo",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-solr",
            {
              "label": "solr",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-zookeeper",
            {
              "label": "zookeeper",
              "stat": "Maximum"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "title": "Docker Data Used %",
        "period": 300,
        "yAxis": {
          "left": {
            "min": 0,
            "max": 100
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 6,
      "width": 15,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "NUL",
            "RootDeviceUsedPct",
            "Environment",
            "${local.namespace}-arch-ui-worker",
            {
              "label": "arch-ui-worker",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-arch-webapp",
            {
              "label": "arch-webapp",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-avr-batch-worker",
            {
              "label": "avr-batch-worker",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-avr-ui-worker",
            {
              "label": "avr-ui-worker",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-avr-webapp",
            {
              "label": "avr-webapp",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-donut-batch-worker",
            {
              "label": "donut-batch-worker",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-donut-ui-worker",
            {
              "label": "donut-ui-worker",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-donut-webapp",
            {
              "label": "donut-webapp",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-fcrepo",
            {
              "label": "fcrepo",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-solr",
            {
              "label": "solr",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-zookeeper",
            {
              "label": "zookeeper",
              "stat": "Maximum"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "title": "Root Device Used %",
        "period": 300,
        "yAxis": {
          "left": {
            "min": 0,
            "max": 100
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 12,
      "width": 15,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "NUL",
            "MemoryBytesUsed",
            "Environment",
            "${local.namespace}-arch-ui-worker",
            {
              "label": "arch-ui-worker",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-arch-webapp",
            {
              "label": "arch-webapp",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-avr-batch-worker",
            {
              "label": "avr-batch-worker",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-avr-ui-worker",
            {
              "label": "avr-ui-worker",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-avr-webapp",
            {
              "label": "avr-webapp",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-donut-batch-worker",
            {
              "label": "donut-batch-worker",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-donut-ui-worker",
            {
              "label": "donut-ui-worker",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-donut-webapp",
            {
              "label": "donut-webapp",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-fcrepo",
            {
              "label": "fcrepo",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-solr",
            {
              "label": "solr",
              "stat": "Maximum"
            }
          ],
          [
            "...",
            "${local.namespace}-zookeeper",
            {
              "label": "zookeeper",
              "stat": "Maximum"
            }
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
      "x": 21,
      "y": 0,
      "width": 3,
      "height": 18,
      "properties": {
        "metrics": [
          [
            "NUL/Solr",
            "DocumentCount",
            "Collection",
            "avr",
            {
              "label": "Total Documents"
            }
          ],
          [
            ".",
            ".",
            "Model",
            "Admin::Collection",
            "Collection",
            "avr",
            {
              "label": "Collections"
            }
          ],
          [
            "...",
            "MediaObject",
            ".",
            ".",
            {
              "label": "MediaObjects"
            }
          ],
          [
            "...",
            "MasterFile",
            ".",
            ".",
            {
              "label": "MasterFiles"
            }
          ],
          [
            "...",
            "Derivative",
            ".",
            ".",
            {
              "label": "Derivatives"
            }
          ],
          [
            ".",
            "ActiveReplicaCount",
            "Collection",
            "avr",
            "Shard",
            "shard1",
            {
              "label": "Active Replicas"
            }
          ]
        ],
        "view": "singleValue",
        "region": "us-east-1",
        "title": "AVR",
        "period": 300
      }
    },
    {
      "type": "metric",
      "x": 18,
      "y": 0,
      "width": 3,
      "height": 18,
      "properties": {
        "metrics": [
          [
            "NUL/Solr",
            "DocumentCount",
            "Collection",
            "donut",
            {
              "label": "Total Documents"
            }
          ],
          [
            ".",
            ".",
            "Model",
            "AdminSet",
            "Collection",
            "donut",
            {
              "label": "Admin Sets"
            }
          ],
          [
            "...",
            "Collection",
            ".",
            ".",
            {
              "label": "Collections"
            }
          ],
          [
            "...",
            "Image",
            ".",
            ".",
            {
              "label": "Images"
            }
          ],
          [
            "...",
            "FileSet",
            ".",
            ".",
            {
              "label": "FileSets"
            }
          ],
          [
            ".",
            "ActiveReplicaCount",
            "Collection",
            "donut",
            "Shard",
            "shard1",
            {
              "label": "Active Replicas"
            }
          ]
        ],
        "view": "singleValue",
        "region": "us-east-1",
        "title": "Donut",
        "period": 300
      }
    },
    {
      "type": "metric",
      "x": 15,
      "y": 0,
      "width": 3,
      "height": 18,
      "properties": {
        "metrics": [
          [
            "NUL/Solr",
            "DocumentCount",
            "Collection",
            "arch",
            {
              "label": "Total Documents"
            }
          ],
          [
            ".",
            ".",
            "Model",
            "AdminSet",
            "Collection",
            "arch",
            {
              "label": "Admin Sets"
            }
          ],
          [
            "...",
            "Collection",
            ".",
            ".",
            {
              "label": "Collections"
            }
          ],
          [
            "...",
            "GenericWork",
            ".",
            ".",
            {
              "label": "Works"
            }
          ],
          [
            "...",
            "FileSet",
            ".",
            ".",
            {
              "label": "FileSets"
            }
          ],
          [
            ".",
            "ActiveReplicaCount",
            "Collection",
            "arch",
            "Shard",
            "shard1",
            {
              "label": "Active Replicas"
            }
          ]
        ],
        "view": "singleValue",
        "region": "us-east-1",
        "title": "Arch",
        "period": 300
      }
    }
  ]
}
  __EOF__
}
