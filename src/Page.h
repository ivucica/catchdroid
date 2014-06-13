#import <Foundation/Foundation.h>
#import <GLES/gl.h>
@class Texture;

#define PAGE_WIDTH 8
#define PAGE_HEIGHT 8
@interface Page : NSObject
{
  Texture * _tileset;
  int _pageX, _pageY;

  int _tiles[PAGE_WIDTH*PAGE_HEIGHT];
  GLfloat _textureCoordinates[2 * 6 * PAGE_WIDTH * PAGE_HEIGHT];
}
@property (nonatomic, retain) Texture * tileset;
- (id) initWithPageX: (int)pageX 
               pageY: (int)pageY;
- (BOOL) loadFromFile: (NSString*) path;
- (void) draw;
- (BOOL) isTileTypePassable: (int) tileType;
- (BOOL) isTilePassableAtX: (int)x y: (int) y;
@end
