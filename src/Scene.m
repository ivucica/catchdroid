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

  self.playerX = 16*8 + 3;
  self.playerY = 16*8 + 4;

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
  if(![[self pageForMapX: self.playerX mapY: self.playerY - 1] isTilePassableAtX: (self.playerX) % PAGE_WIDTH y: (self.playerY - 1) % PAGE_HEIGHT])
    return;
  self.playerY--;
}
- (void) movePlayerRight
{
  if(_player.progress < 1) return;
  [_player setDirection: 1];
  if(![[self pageForMapX: self.playerX + 1 mapY: self.playerY] isTilePassableAtX: (self.playerX + 1) % PAGE_WIDTH y: (self.playerY) % PAGE_HEIGHT])
    return;
  self.playerX++;
}
- (void) movePlayerDown
{
  if(_player.progress < 1) return;
  [_player setDirection: 2];
  if(![[self pageForMapX: self.playerX mapY: self.playerY + 1] isTilePassableAtX: (self.playerX) % PAGE_WIDTH y: (self.playerY + 1) % PAGE_HEIGHT])
    return;
  self.playerY++;
}
- (void) movePlayerLeft
{
  if(_player.progress < 1) return;
  [_player setDirection: 3];
  if(![[self pageForMapX: self.playerX - 1 mapY: self.playerY] isTilePassableAtX: (self.playerX - 1) % PAGE_WIDTH y: (self.playerY) % PAGE_HEIGHT])
    return;
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
      Page * page = [self pageForPageX: currentPageX
                                 pageY: currentPageY];
      if(!page)
        continue;

      glPushMatrix();
      glTranslatef(i * PAGE_WIDTH, (-j-1) * PAGE_HEIGHT + 1, 0);
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
- (Page *) playerPage
{
  return [self pageForMapX: _playerX
                      mapY: _playerY];
}
- (Page *) pageForMapX: (int)mapX
                  mapY: (int)mapY
{
  int pageX = mapX / PAGE_WIDTH;
  int pageY = mapY / PAGE_HEIGHT;
  return [self pageForPageX: pageX
                      pageY: pageY];
}
- (Page *) pageForPageX: (int)pageX
                  pageY: (int)pageY
{
  NSString * currentPage = [NSString stringWithFormat: @"%d-%d", pageX, pageY];
  Page * page = [_pages objectForKey: currentPage];
  if (!page)
  {
    page = [[[Page alloc] initWithPageX: pageX
                                  pageY: pageY] autorelease];
    if(!page)
      return nil;
    [_pages setObject: page forKey: currentPage];
    if(![_pages objectForKey: currentPage])
      LOGI("Caching the page failed?!");
   }
   return page;
}
@end

