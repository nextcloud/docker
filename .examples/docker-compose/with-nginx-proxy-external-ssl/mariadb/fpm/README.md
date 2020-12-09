You need to have an SSL certificate for your domain. You could generate it with [Certbot](https://certbot.eff.org/).

Fill in the `db.env` and `ssl.env` files and the `MYSQL_ROOT_PASSWORD` environment variable in `docker-compose.yml` file. The `CERT_PATH` needs to contain the

- `.crt` file
- `.key` file

If you generated your certificate with Certbot you can create symbolic links:

```shell
cd /path/to/certs
ln -s /path/to/certs/fullchain1.pem mydomain.crt
ln -s /path/to/certs/privkey1.pem mydomain.key
```

Replace `mydomain` with the domain covered by your certificate and used to access your Nextcloud instance.
