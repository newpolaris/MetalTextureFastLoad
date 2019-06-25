RGB 5120 × 2880 jpg

# debug mode

2019-06-25 01:25:45.344302+0900 MetalTextureFastLoad[13442:733236] [image load] 545.398010 ms
2019-06-25 01:25:45.344388+0900 MetalTextureFastLoad[13442:733236] [texture create] 0.101000 ms
2019-06-25 01:25:45.379545+0900 MetalTextureFastLoad[13442:733236] [upload texture] 35.151001 ms

# release mode

2019-06-25 01:29:51.022665+0900 MetalTextureFastLoad[13538:736712] [image load] 175.738007 ms
2019-06-25 01:29:51.023269+0900 MetalTextureFastLoad[13538:736712] [texture create] 0.614000 ms
2019-06-25 01:29:51.056690+0900 MetalTextureFastLoad[13538:736712] [upload texture] 33.417999 ms

2019-06-25 01:30:50.877403+0900 MetalTextureFastLoad[13609:737635] [image load] 173.033997 ms
2019-06-25 01:30:50.877982+0900 MetalTextureFastLoad[13609:737635] [texture create] 0.589000 ms
2019-06-25 01:30:51.728657+0900 MetalTextureFastLoad[13609:737635] [upload texture] 850.700989 ms

https://github.com/bkaradzic/bgfx/blob/master/src/renderer_mtl.mm
