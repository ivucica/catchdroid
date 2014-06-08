#import <Foundation/Foundation.h>
#import <GLES/gl.h>

@class Asset;

@interface Texture : NSObject
{
  GLuint _id;
  Asset * _asset;
  NSString * _path;
}
@property (nonatomic, retain) Asset * asset;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, assign) GLuint textureId;
+ (Texture *) textureWithPath: (NSString *)path;
- (id) initWithPath: (NSString *)path;
@end
