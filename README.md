[![Docker Pulls](https://img.shields.io/docker/pulls/pavelsor/autoclean-docker-registry.svg)](https://hub.docker.com/r/pavelsor/autoclean-docker-registry/)

# What is this? 
 
It is a container, which provides Docker Registry with an automatic cleaning feature.

Besides standard docker registry, the container contains cron job, which periodically cleans old tags. You can configure how much old tags is left for each docker image.

Garbage collection is handled automatically.
 
# Configuration 
 
Is done using environmental variables 
 
name|description 
--- | --- 
`REGISTRY_URL` | URL for accessing docker registry. Default: http://localhost:5000
`KEEP_TAGS` | How much old tags is kept for each image. Default: 3
`CLEANUP_CRON` | Cron style schedule for cleaning job. Default: `5 0 * * *`

Besides these, you can use Docker Registry environment variables
