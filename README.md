# docker-iipsrv

IIPImage server

## How to use

### Get the docker image

Pull a prebuilt image from GitHub Container Registry:
```
$ docker pull ghcr.io/dfukagaw28/iipsrv:latest
```

Or build it yourself:
```
$ docker build . -t ghcr.io/dfukagaw28/iipsrv:latest
```

### How to run

Prepare some image file(s) in a directory.
Images must be tiled pyramid TIFF or JPEG2000, and readable by the `www-data` user (uid 33) in the container.

For example, a tiled pyramid TIFF can be created with [libvips](https://www.libvips.org/):
```
$ vips tiffsave input.jpg /path/to/images/example.tif --tile --pyramid --compression jpeg --tile-width 256 --tile-height 256
```

Start & run a container:
```
$ docker run --rm -it -p 3000:80 -v /path/to/images/:/data/images/:ro ghcr.io/dfukagaw28/iipsrv:latest
```

Logs of lighttpd and iipsrv go to the container's stderr (`docker logs`); a TTY (`-t`) is not required.

Images are served as IIIF at `/iiif/<file>/...` (e.g. `/iiif/example.tif/info.json`).
The query string form `/?IIIF=<file>/...` also works, but it does not support `HEAD` requests.

### Configuration

iipsrv is configured with environment variables (`-e NAME=value`).
Any [iipsrv variable](https://iipimage.sourceforge.io/documentation/server/) can be set; the image sets these defaults:

| Variable | Default | Description |
|---|---|---|
| `FILESYSTEM_PREFIX` | `/data/images/` | Directory of the images inside the container |
| `URI_MAP` | `iiif=>IIIF` | Serve IIIF at `/iiif/...` |
| `IIIF_VERSION` | `3` | IIIF Image API version |
| `BASE_URL` | (unset) | Public URL prefix for `id` in `info.json`, e.g. `https://example.org/iiif/`. Set it behind a reverse proxy (otherwise `id` is built from the `Host` header with `http://`) |
| `CORS` | `*` | `Access-Control-Allow-Origin` |
| `MAX_IMAGE_CACHE_SIZE` | `10` | Image cache size (MB) |
| `JPEG_QUALITY` | `75` | JPEG quality |
| `PNG_QUALITY` | `1` | PNG compression level |
| `WEBP_QUALITY` | `50` | WebP quality |
| `MAX_CVT` | `3000` | Maximum output width/height (px) |
| `LOGFILE` | `/var/log/iipsrv.log` | Linked to the container's stderr |
| `VERBOSITY` | (unset: 1) | Log level (0-6) |

Example behind a reverse proxy that maps `https://example.org/iiif/` to the container:
```
$ docker run -d -p 127.0.0.1:3000:80 -v /path/to/images/:/data/images/:ro \
    -e BASE_URL=https://example.org/iiif/ ghcr.io/dfukagaw28/iipsrv:latest
```

### How to test

```
$ curl -si http://127.0.0.1:3000/iiif/example.tif/info.json
HTTP/1.1 200 OK
Server: iipsrv/1.3
X-Powered-By: IIPImage
Content-Type: application/ld+json;profile="http://iiif.io/api/image/3/context.json"
Last-Modified: Wed, 28 Oct 2026 20:30:39 GMT
Cache-Control: max-age=86400
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Accept, Content-Type, X-Requested-With, If-Modified-Since
Access-Control-Max-Age: 86400
Accept-Ranges: bytes
Content-Length: 907
Date: Wed, 28 Oct 2026 21:17:19 GMT

{
  "@context" : "http://iiif.io/api/image/3/context.json",
  "protocol" : "http://iiif.io/api/image",
  "width" : 1000,
  "height" : 1000,
  "sizes" : [
     { "width" : 250, "height" : 250 },
     { "width" : 500, "height" : 500 }
  ],
  "tiles" : [
     { "width" : 256, "height" : 256, "scaleFactors" : [ 1, 2, 4 ] }
  ],
  "id" : "http://127.0.0.1:3000/iiif/example.tif",
  "type": "ImageService3",
  "profile" : "level2",
  "maxWidth" : 3000,
  "maxHeight" : 3000,
  "extraQualities": ["color","gray","bitonal"],
  "extraFormats": ["tif","webp","avif"],
  "extraFeatures": ["regionByPct","sizeByPct","sizeByConfinedWh","sizeUpscaling","rotationBy90s","mirroring"],
  "service": [
    {
      "@context": "http://iiif.io/api/annex/services/physdim/1/context.json",
      "profile": "http://iiif.io/api/annex/services/physdim",
      "physicalScale": 0.0393701,
      "physicalUnits": "in"
    }
  ]

}
```

### Run the tests

`test/test.sh` builds a test image with libvips, runs the container and checks the responses
(requires docker or podman, curl, jq and vips):
```
$ docker build . -t iipsrv:test
$ test/test.sh iipsrv:test
```

## GitHub Container registry

The image is built, tested and pushed to `ghcr.io/dfukagaw28/iipsrv` by GitHub Actions
(`.github/workflows/docker.yml`) on every push to `main` and weekly, so that Debian security updates are picked up.
It is tagged with the iipsrv version (`IIPSRV_VERSION` in `Dockerfile`) and `latest`.

To push manually:
```
$ docker build . -t ghcr.io/dfukagaw28/iipsrv:1.3 -t ghcr.io/dfukagaw28/iipsrv:latest
$ export CR_PAT=PERSONAL_ACCESS_TOKEN
$ echo $CR_PAT | docker login ghcr.io -u dfukagaw28 --password-stdin
$ docker push ghcr.io/dfukagaw28/iipsrv:1.3
$ docker push ghcr.io/dfukagaw28/iipsrv:latest
```
