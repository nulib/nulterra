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
      { "name": "TIFF_BUCKET",       "value": "${tiff_bucket}" },
      { "name": "AWS_REGION",        "value": "${aws_region}" },
      { "name": "AWS_ACCESS_KEY_ID", "value": "${aws_access_key_id}" },
      { "name": "AWS_SECRET_KEY",    "value": "${aws_secret_key}" }
    ],
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
