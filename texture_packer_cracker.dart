#!/usr/bin/env dart --enable_type_checks --enable_asserts

#import('dart:io');
#import('lib/texture.dart');

const String _path = @"./html/canvas/art.plist";

main(){
  final path = new Path(_path);
  final textures = getTextures(path);
  print(textures);
}
