# nginx

Nginx (engine-x) is commonly used as a

- reverse proxy
- load balancer (with proxy protocol support)
- TLS termination

sometimes you may need to do `curl -H "Host: something.domain.tld"
http://localhost:80` to get the nginx to respond to requests depending on the
config (e.g. `server_name domain.tld www.domain.tld` will not respond unless
the client sends the Host header of who it wishes to reach, whereas `listen 80
default; server_name _` will fallback and work.
