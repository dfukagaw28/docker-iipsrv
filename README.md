# docker-iipsrv

IIPImage server

## How to build docker image

```
$ docker build . -t iipsrv:latest
```

## How to run

Prepare some image file(s)
```
$ file /files/tirdb/pyramids/67352ccc-d1b0-11e1-89ae-279075081939.tif
/files/tirdb/pyramids/67352ccc-d1b0-11e1-89ae-279075081939.tif: TIFF image data, little-endian, direntries=22, height=1000, bps=15556, compression=JPEG, PhotometricIntepretation=RGB, name=67352ccc-d1b0-11e1-89ae-279075081939.tif, orientation=upper-left, width=1000
```

Start & run a container:
```
$ docker run --rm -it -p 3000:80 -v /files/tirdb/pyramids/:/data/images/:ro iipsrv:latest
```

## How to test

```
$ curl -si http://127.0.0.1:3000/?IIIF=example.tif/info.json
HTTP/1.1 200 OK
Server: iipsrv/1.2
X-Powered-By: IIPImage
Content-Type: application/ld+json;profile="http://iiif.io/api/image/3/context.json"
Last-Modified: Tue, 21 Feb 2017 07:36:59 GMT
Cache-Control: max-age=86400
Accept-Ranges: bytes
Content-Length: 992
Date: Thu, 07 Sep 2023 14:21:44 GMT

{
  "@context" : "http://iiif.io/api/image/3/context.json",
  "protocol" : "http://iiif.io/api/image",
  "width" : 1000,
  "height" : 1000,
  "sizes" : [
     { "width" : 62, "height" : 62 },
     { "width" : 125, "height" : 125 },
     { "width" : 250, "height" : 250 },
     { "width" : 500, "height" : 500 }
  ],
  "tiles" : [
     { "width" : 256, "height" : 256, "scaleFactors" : [ 1, 2, 4, 8, 16 ] }
  ],
  "id" : "http://127.0.0.1:3000/?IIIF=example.tif",
  "type": "ImageService3",
  "profile" : "level2",
  "maxWidth" : 3000,
  "maxHeight" : 3000,
  "extraQualities": ["color","gray","bitonal"],
  "extraFormats": ["webp"],
  "extraFeatures": ["regionByPct","sizeByForcedWh","sizeByWh","sizeAboveFull","sizeUpscaling","rotationBy90s","mirroring"],
  "service": [
    {
      "@context": "http://iiif.io/api/annex/services/physdim/1/context.json",
      "profile": "http://iiif.io/api/annex/services/physdim",
      "physicalScale": 0.0138889,
      "physicalUnits": "cm"
    }
  ]

}
```
