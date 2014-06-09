#import <Foundation/Foundation.h>
#import <GLES/gl.h>
@class Texture;

#define PAGE_WIDTH 8
#define PAGE_HEIGHT 8
@interface Page : NSObject
{
  Texture * _tileset;
  int _pageX, _pageY;

  int _tiles[16*16];
  GLfloat _textureCoordinates[2 * 6 * 16 * 16];
}
@property (nonatomic, retain) Texture * tileset;
- (id) initWithPageX: (int)pageX 
               pageY: (int)pageY;
- (BOOL) loadFromFile: (NSString*) path;
- (void) draw;
@end
