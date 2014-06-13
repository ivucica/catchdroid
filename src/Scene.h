#import <Foundation/Foundation.h>

@class Character;
@class Page;

@interface Scene : NSObject
{
  NSMutableDictionary * _pages;
  int _playerX, _playerY;
  Character * _player;

  SEL _direction;

  float _fadeProgress;
}
@property (retain) NSMutableDictionary * pages;
@property (assign, nonatomic) int playerX;
@property (assign, nonatomic) int playerY;
@property (retain) Character * player;

@property (assign) SEL direction;

- (void) draw;
- (void) update: (double)dt;
- (void) movePlayerUp;
- (void) movePlayerDown;
- (void) movePlayerLeft;
- (void) movePlayerRight;

- (Page *) playerPage;
- (Page *) pageForMapX: (int)mapX
                  mapY: (int)mapY;
- (Page *) pageForPageX: (int)pageX
                  pageY: (int)pageY;
@end

