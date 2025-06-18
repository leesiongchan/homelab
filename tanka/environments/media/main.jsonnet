local bazarr = import 'bazarr.libsonnet';
local crossSeed = import 'cross-seed/main.libsonnet';
local recyclarr = import 'recyclarr/main.libsonnet';
local unpackerr = import 'unpackerr/main.libsonnet';

{
  bazarr: bazarr,
  crossSeed: crossSeed,
  recyclarr: recyclarr,
  rtorrent: import 'rtorrent.libsonnet',
  unpackerr: unpackerr,
}
