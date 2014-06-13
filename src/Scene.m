#import "Scene.h"
#import "Page.h"
#import "Character.h"

#include <android/log.h>
#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, "native-activity", __VA_ARGS__))
#define LOGW(...) ((void)__android_log_print(ANDROID_LOG_WARN, "native-activity", __VA_ARGS__))

@implementation Scene
@synthesize pages=_pages;
@synthesize player=_player;
@synthesize playerX=_playerX;
@synthesize playerY=_playerY;
@synthesize direction=_direction;
- (id) init
{
  self = [super init];
  if(!self) return nil;

  _pages = [NSMutableDictionary new];
  _player = [[Character alloc] initWithTexturePath: @"player.png"];

  self.playerX = 16*8;
  self.playerY = 16*8;

  return self;
}

- (void) dealloc
{
  [_player release];
  [_pages release];
  [super dealloc];
}

- (void) movePlayerUp
{
  if(_player.progress < 1) return;
  [_player setDirection: 0];
  self.playerY--;
}
- (void) movePlayerRight
{
  if(_player.progress < 1) return;
  [_player setDirection: 1];
  self.playerX++;
}
- (void) movePlayerDown
{
  if(_player.progress < 1) return;
  [_player setDirection: 2];
  self.playerY++;
}
- (void) movePlayerLeft
{
  if(_player.progress < 1) return;
  [_player setDirection: 3];
  self.playerX--;
}

- (void) setPlayerX: (int)playerX
{
  _playerX = playerX;
  _player.progress-=1.;
  if(_player.progress < 0) _player.progress = 0;
  _player.mapX = _playerX;
}
- (void) setPlayerY: (int)playerY
{
  _playerY = playerY;
  _player.progress-=1.;
  if(_player.progress < 0) _player.progress = 0;
  _player.mapY = _playerY;
}

#define PAGE_WIDTH 8
#define PAGE_HEIGHT 8
- (void) draw
{
  int playerPageX = _playerX / PAGE_WIDTH;
  int playerPageY = _playerY / PAGE_HEIGHT;

  glPushMatrix();
  [_player translateWithMultiplier: -1];
  glTranslatef(-(_playerX % PAGE_WIDTH),
               (_playerY % PAGE_HEIGHT),
               0);
  for(int i = -1; i <= 1; i++)
  {
    for(int j = -2; j <= 2; j++)
    {
      int currentPageX = playerPageX + i;
      int currentPageY = playerPageY + j;
      NSString * currentPage = [NSString stringWithFormat: @"%d-%d", currentPageX, currentPageY];
      Page * page = [_pages objectForKey: currentPage];
      if (!page)
      {
        page = [[[Page alloc] initWithPageX: currentPageX pageY: currentPageY] autorelease];
        if(!page)
          continue;
        [_pages setObject: page forKey: currentPage];
        if(![_pages objectForKey: currentPage])
          LOGI("Caching the page failed?!");
      }
      
      glPushMatrix();
      glTranslatef(i * PAGE_WIDTH, -j * PAGE_HEIGHT, 0);
      [page draw];
      glPopMatrix();
    }
  }
  glPopMatrix();
  // for player character, not doing translation
  // others would have: [ch translateWithMultiplier: 1];
  // (to apply 'progress' animation)
  [_player draw];
}

- (void) update: (double)dt
{
  [_player update: dt];
  if(_direction)
    [self performSelector: _direction];
}
@end

