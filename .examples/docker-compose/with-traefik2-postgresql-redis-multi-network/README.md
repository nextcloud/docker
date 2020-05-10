## Trafik Multi Network Deployment

1. Create Traefik network

` # docker network  create --driver=bridge --attachable --internal=false traefik `

2. Edit `traefik2/docker-compose.yml`
    - Change ACME email
    - Change --providers.docker.network=traefik value if you created different network then `traefik`

3. Deploy traefik

 `docker-compose -f traefik2/docker-compose.yml up -d`

4. Edit `nextcloud/docker-compose.yml`
    - Change traefik.http.routers.nextcloud.rule Host
    - Remove `traefik.http.middlewares.nextcloud.headers.customFrameOptionsValue` and `contentSecurityPolicy`
      if you dont need to iframe access from your external website
    - Change PostgreSQL environments
    - Edit `TRUSTED_PROXIES` with your traefik network address
5. Deploy nextcloud

 `docker-compose -f nextcloud/docker-compose.yml up -d`
