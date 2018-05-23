[
  {
    "name": "fcrepo-app",
    "image": "nulib/fcrepo4:s3fix",
    "memoryReservation": 3000,
    "portMappings": [
      { "containerPort": 8080 }
    ],
    "environment": [
      {
        "name": "MODESHAPE_CONFIG",
        "value": "classpath:/config/jdbc-postgresql-s3/repository.json"
      },
      {
        "name": "JAVA_OPTIONS",
        "value": "-Dfcrepo.postgresql.host=${db_host} -Dfcrepo.postgresql.port=${db_port} -Dfcrepo.postgresql.username=${db_user} -Dfcrepo.postgresql.password=${db_password} -Daws.accessKeyId=${bucket_access_key_id} -Daws.secretKey=${bucket_access_key_secret} -Daws.bucket=${bucket_name}"
      }
    ]
  }
]
