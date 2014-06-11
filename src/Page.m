#import "Page.h"
#import "Texture.h"
#import "Asset.h"

#include <android/log.h>

#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, "native-activity", __VA_ARGS__))
#define LOGW(...) ((void)__android_log_print(ANDROID_LOG_WARN, "native-activity", __VA_ARGS__))

#define TILESET_WIDTH 8
#define TILESET_HEIGHT 8

static GLfloat gridVertices[(2) * // x,y
                            (6) * // 6 vertices per quad
                            PAGE_WIDTH * PAGE_HEIGHT
                           ];

@implementation Page
@synthesize tileset=_tileset;

+ (void) load
{
  [super load];

  for(int j = 0; j < PAGE_HEIGHT; j++)
  {
    for(int i = 0; i < PAGE_WIDTH; i++)
    {
      static const GLfloat vertices[] = {
        -0.5, -0.5,
         0.5, -0.5,
         0.5, 0.5,

         0.5, 0.5,
        -0.5, 0.5,
        -0.5, -0.5,
      };

      for(int k = 0; k < 6; k++)
      {
        gridVertices[2 * 6 * PAGE_WIDTH * j +
                     2 * 6 * i +
                     2 * k + 0] = (i + vertices[2 * k + 0]);
        gridVertices[2 * 6 * PAGE_WIDTH * j +
                     2 * 6 * i +
                     2 * k + 1] = (j + vertices[2 * k + 1]);
      }
    }
  }

}
- (id) initWithPageX: (int)pageX 
               pageY: (int)pageY
{
  self = [super init];
  if (!self) return nil;

  BOOL success = [self loadFromFile: [NSString stringWithFormat: @"pages/%d-%d", pageX, pageY]];
  if (!success)
  {
    [self release];
    return nil;
  }
  LOGI("%g %g - %g %g - %g %g - %g %g", 
      gridVertices[0], gridVertices[1],
      gridVertices[2], gridVertices[3],
      gridVertices[4], gridVertices[5],
      gridVertices[6], gridVertices[7]);

  return self;
}
- (void) dealloc
{
  [_tileset release];
  [super dealloc];
}

- (BOOL) loadFromFile: (NSString*) path
{

  Asset * asset = [Asset assetWithPath: path];
  if (!asset)
  {
    LOGW("Could not load asset %s", [path UTF8String]);
    return NO;
  }

  NSString * s = [[asset string] stringByReplacingOccurrencesOfString: @"\n" withString: @" "];
  NSArray * tiles = [s componentsSeparatedByString: @" "];
  int i = 0;
  for(NSString * tile in tiles)
  {
    if(sscanf([tile UTF8String], "%d", &_tiles[i]) != 1)
      break;

    int x = i % PAGE_WIDTH;
    int y = PAGE_HEIGHT-1 - i / PAGE_WIDTH;

    static const GLfloat textures[] = {
      0, 1,
      1, 1,
      1, 0,

      1, 0,
      0, 0,
      0, 1
    };
    for(int k = 0; k < 6; k++)
    {
      int a = (2 * 6 * PAGE_WIDTH * y) +
              (2 * 6 * x) + 
              (2 * k + 0);
      int b = (2 * 6 * PAGE_WIDTH * y) +
              (2 * 6 * x) + 
              (2 * k + 1);
      _textureCoordinates[a] = (_tiles[i] % (TILESET_WIDTH) + textures[2*k + 0]) / ((GLfloat)TILESET_WIDTH);
      _textureCoordinates[b] = (_tiles[i] / (TILESET_WIDTH) + textures[2*k + 1]) / ((GLfloat)TILESET_HEIGHT); 

      LOGI("%d,%d - vertex %d: into %d,%d go %g,%g", x, y, k, a, b, _textureCoordinates[a], _textureCoordinates[b]);
    }

    i++;
    if(i >= 16*16) break;
  }
  [self setTileset: [Texture textureWithPath: @"tiles1.png"]]; 
  return YES;
}
- (void) draw
{
    glEnable(GL_TEXTURE_2D);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  
    glBindTexture(GL_TEXTURE_2D, [_tileset textureId]);
    glVertexPointer(2, GL_FLOAT, 0, gridVertices);
    glTexCoordPointer(2, GL_FLOAT, 0, _textureCoordinates);
    glDrawArrays(GL_TRIANGLES, 0, 6 * (PAGE_WIDTH * PAGE_HEIGHT));
    glBindTexture(GL_TEXTURE_2D, 0);
    
    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisable(GL_TEXTURE_2D);
}
@end