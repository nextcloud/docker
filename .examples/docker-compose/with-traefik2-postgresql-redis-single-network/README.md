## Trafik Single Network Deployment

1. Create a  network

` # docker network  create  nextcloud `

4. Edit `docker-compose.yml`
    -  Change ACME Email Address
    - Change traefik.http.routers.nextcloud.rule Host
    - Remove `traefik.http.middlewares.nextcloud.headers.customFrameOptionsValue` and `contentSecurityPolicy`
      if you dont need to iframe access from your external website
    - Change PostgreSQL environments
    - Edit `TRUSTED_PROXIES` with your nextcloud network address
5. Deploy nextcloud

 `docker-compose docker-compose.yml up -d`
