[
  {
    "name": "cantaloupe-app",
    "image": "nulib/cantaloupe:latest",
    "essential": true,
    "memoryReservation": 3000,
    "portMappings": [
      { "containerPort": 8182 }
    ],
    "environment": [
      { "name": "TIFF_BUCKET",       "value": "${tiff_bucket}" }
    ],
    "readonlyRootFilesystem": false,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${namespace}",
        "awslogs-region": "${aws_region}",
        "awslogs-stream-prefix": "iiif"
      }
    }
  }
]
