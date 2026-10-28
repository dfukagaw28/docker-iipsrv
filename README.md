# docker-iipsrv

IIPImage server

## How to use

### build docker image

```
$ docker build . -t iipsrv:latest
```

### How to run

Prepare some image file(s)
```
$ file /files/tirdb/pyramids/67352ccc-d1b0-11e1-89ae-279075081939.tif
/files/tirdb/pyramids/67352ccc-d1b0-11e1-89ae-279075081939.tif: TIFF image data, little-endian, direntries=22, height=1000, bps=15556, compression=JPEG, PhotometricIntepretation=RGB, name=67352ccc-d1b0-11e1-89ae-279075081939.tif, orientation=upper-left, width=1000
```

Start & run a container:
```
$ docker run --rm -it -p 3000:80 -v /files/tirdb/pyramids/:/data/images/:ro iipsrv:latest
```

### How to test

```
$ curl -si http://127.0.0.1:3000/?IIIF=example.tif/info.json
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
Content-Length: 900
Date: Wed, 28 Oct 2026 20:30:40 GMT

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
  "id" : "http://127.0.0.1:3000/?IIIF=example.tif",
  "type": "ImageService3",
  "profile" : "level2",
  "maxWidth" : 3000,
  "maxHeight" : 3000,
  "extraQualities": ["color","gray","bitonal"],
  "extraFormats": ["tif","webp"],
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

## GitHub Container registry

```
$ docker build . -t ghcr.io/dfukagaw28/iipsrv:1.3
```

```
$ export CR_PAT=PERSONAL_ACCESS_TOKEN
$ echo $CR_PAT | docker login ghcr.io -u dfukagaw28 --password-stdin
$ docker push ghcr.io/dfukagaw28/iipsrv:1.3
```
