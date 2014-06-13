#import <Foundation/Foundation.h>

@class Character;

@interface Scene : NSObject
{
  NSMutableDictionary * _pages;
  int _playerX, _playerY;
  Character * _player;

  SEL _direction;
}
@property (retain) NSMutableDictionary * pages;
@property (assign) int playerX;
@property (assign) int playerY;
@property (retain) Character * player;

@property (assign) SEL direction;
@end

