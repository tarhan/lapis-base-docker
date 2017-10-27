# Description

This simple base Docker image containing Lapis web-framework allowing
simplify creating child Docker images for project.

# Usage

Your parent Docker image should be like this.

```
FROM tarhan/lapis:latest
```

In your project root where ```Dockerfile``` located create **app.yml** manifest
structure according as in following example:

```yaml
name: "yourproject"

dependencies:
  alpine:
    runtime:
      - openssl
    buildtime:
      - openssl-dev
  luarocks:    
    - luasec
```

Here in the example **luasec** package will be installed package **luarocks**.
Luarocks tries to build package from source code so it need its headers files.  
In this case **luasec** packages requires **openssl** headers files located inside **openssl-dev** Alpine OS package so we've specified it under **dependencies.alpine.buildtime** key.  
Since **luasec** depends on **openssl** at runtime so we've also specified it under
**dependencies.alpine.runtime** key.  
All OS packages were been specified under **dependencies.alpine.buildtime** key
will be removed after building your container.

# Usage after building

After your container created you can use it as you used **lapis** command
inside your project root.

## Docker run

```sh
docker run --rm -it -p 8080:8080 tarhan/lapis:latest server
```

Result will be similar to executing following command from your
project root:  

```sh
lapis server
```

## Docker Compose

Using Docker Compose you can create **docker-compose.yml**
similar to following:  

```yaml
version: "2"
services:
  web:
    build: .
    command: server development
    volumes:
      - .:/app/src
      - ./logs:/usr/local/openresty/nginx/logs
    ports:
      - "8080:8080"
```

Mounting project folder to **/app/src/** inside container provide
live-reload feature during development. So you can change
your code and see result without re-building project's container.
