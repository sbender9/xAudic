/*  
 *  xAudic - an audio player for MacOS X
 *  Copyright (C) 1999-2001  Scott P. Bender (sbender@harmony-ds.com)
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; see the file COPYING if not, write to 
 *  the Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
 *  Boston, MA 02111-1307, USA.
*/
#import <MXA/Common.h>
#import <MXA/MXAConfig.h>
#import "Skin.h"

#import <AppKit/NSApplication.h>
#import <string.h>
#import <sys/stat.h>
#import <MXA/Common.h>

NSString *SkinChangedNotification = @"SkinChangedNotification";

Skin *currentSkin = 0;
Skin *defaultSkin = 0;


NSString *find_file_recursively(NSString *dirname, NSString *file);


static int skin_default_viscolor[24][3]=
{
  { 0,0,0 },
  { 24,33,41 }, 
  { 239,49,16 },
  { 206,41,16 },
  { 214,90,0 }, 
  { 214,102,0 },
  { 214,115,0 },
  { 198,123,8 },
  { 222,165,24 },
  { 214,181,33 },
  { 189,222,41 },
  { 148,222,33 },
  { 41,206,16 },
  { 50,190,16 },
  { 57,181,16 },
  { 49,156,8 },
  { 41,148,0 },
  { 24,132,8 },
  { 255,255,255 },
  { 214,214,222 },
  { 181,189,189 },
  { 160,170,175 },  
  { 148,156,165 },  
  { 150, 150, 150 }
};

NSImage *process_image(NSImage *image)
{
  NSImage *res;
  NSImageRep *rep;
  NSSize size;

  rep = [image bestRepresentationForDevice:nil];
  size = NSMakeSize([rep pixelsWide], [rep pixelsHigh]);
  [rep setSize:size];
  res = [[NSImage alloc] initWithSize:size];
  [res lockFocus];
  [rep drawAtPoint:NSMakePoint(0, 0)];
  [res unlockFocus];
  return res;
}

static NSImage *load_skin_image(NSString *dir, NSString *name)
{
  NSString *path;
  NSImage *res = nil;
  
  path = find_file_recursively(dir, name);
  if (path)
    {
      res = [[NSImage alloc] initWithContentsOfFile:path];
      if ( res != nil )
	{
	  res = process_image(res);
	}
    }
  return res;
}

static NSImage *rload_skin_image(NSString *name)
{
  NSString *path;
  NSImage *res = nil;

  path = [[NSBundle mainBundle] 
	   pathForResource:[name stringByDeletingPathExtension] 
		    ofType:[name pathExtension]];
  if ( path != nil )
    {
      res = [[NSImage alloc] initWithContentsOfFile:path];
      if ( [res isValid] == NO )
	{
	  NSLog(@"Invalid bitmap: %@", path);
	  return nil;
	}

      res = process_image(res);
    }
  
  return res;
}


NSColor *load_skin_color(NSString *dir, NSString *name, const char *section,
			 const char *key)
{
  NSString *filename;
  char *value, *ptr;
  NSColor *color = nil;
  int r, g, b;
  float fr, fg, fb;

  filename = find_file_recursively(dir, name);
  if ( filename ) {
    value=read_ini_string([filename fileSystemRepresentation], section, key);
    if ( value != 0 ) {
      ptr = value;
      if(value[0]=='#')
	ptr++;

      sscanf(ptr,"%2x%2x%2x",&r, &g, &b);

      fr = r / 255.0;
      fg = g / 255.0;
      fb = b / 255.0;
      
      color = [NSColor colorWithCalibratedRed:fr
					green:fg
					 blue:fb
					alpha:1];
      free(value);
    }
  }
  
  return [color retain];
}		

NSColor *rload_skin_color(NSString *name, const char *section, const char *key)
{
  NSString *path;

  path = [[NSBundle mainBundle] 
	   pathForResource:[name stringByDeletingPathExtension] 
		    ofType:[name pathExtension]];
  
  return load_skin_color([path stringByDeletingLastPathComponent], name, 
			 section, key);
}

@implementation Skin

+ (void)loadSkin:(NSString *)pathName
{
  Skin *skin = nil;

  if ( defaultSkin == nil )
    defaultSkin = [[Skin alloc] initDefault];

  if ( [pathName isEqualToString:@"(none)"] == NO ) 
    {
      NSString *w = @"$(APP_WRAPPER)";
      if ( [pathName hasPrefix:w] )
	{
	  NSString *appPath = [[NSBundle mainBundle] bundlePath];
	  pathName = [appPath stringByAppendingPathComponent:[pathName substringFromIndex:[w length]]];
	}


      skin = [[Skin alloc] initWithFile:pathName];
      if ( skin != nil ) {
	[currentSkin release];
	currentSkin = skin;
    } 
    }
  if ( skin == nil ) 
    {
      [currentSkin release];
      currentSkin = [defaultSkin retain];
    }
  
  [[NSNotificationCenter defaultCenter]
    postNotificationName:SkinChangedNotification object:nil];
}

- (void)dealloc
{
  [skinPath release];
  [main release];
  [cbuttons release];
  [titlebar release];
  [shufrep release];
  [text release];
  [volume release];
  [balance release];
  [monostereo release];
  [playpause release];
  [numbers release];
  [posbar release];
  [pledit release];
  [eqmain release];
  [eq_ex release];
  [pledit_normal release];
  [pledit_current release];
  [pledit_normalbg release];
  [pledit_selectedbg release];
  [def_mask release];
  [mask_main release];
  [mask_main_ds release];
  [mask_eq release];
  [mask_eq_ds release];
  [mask_shade release];
  [mask_shade_ds release];
  [super dealloc];
}

- initDefault
{
  int i;
  
  main = rload_skin_image(@"main.bmp");
  cbuttons = rload_skin_image(@"cbuttons.bmp");
  titlebar = rload_skin_image(@"titlebar.bmp");
  shufrep = rload_skin_image(@"shufrep.bmp");
  text = rload_skin_image(@"text.bmp");
  volume = rload_skin_image(@"volume.bmp");
  balance = rload_skin_image(@"balance.bmp");
  monostereo = rload_skin_image(@"monoster.bmp");
  playpause = rload_skin_image(@"playpaus.bmp");
  numbers = rload_skin_image(@"nums_ex.bmp");
  if( numbers == 0 ) 
    numbers = rload_skin_image(@"numbers.bmp");
  posbar = rload_skin_image(@"posbar.bmp");
  pledit = rload_skin_image(@"pledit.bmp");
  eqmain = rload_skin_image(@"eqmain.bmp");
  eq_ex = rload_skin_image(@"eq_ex.bmp");

  pledit_normal = rload_skin_color(@"pledit.txt", "text", "normal");
  pledit_current = rload_skin_color(@"pledit.txt","text","current");
  pledit_normalbg = rload_skin_color(@"pledit.txt","text","normalbg");
  pledit_selectedbg = rload_skin_color(@"pledit.txt","text", "selectedbg");

  /*
  pledit_normal = [NSColor colorWithCalibratedRed:0 
  green:1
  blue:0
			       alpha:1];
			       [pledit_normal retain];

  pledit_current = [NSColor colorWithCalibratedRed:1
					     green:1
					      blue:1
					     alpha:1];
  [pledit_current retain];
  pledit_normalbg = [NSColor colorWithCalibratedRed:0 
					      green:0
					       blue:0
					      alpha:1];
  [pledit_normalbg retain];
  
  pledit_selectedbg = [NSColor colorWithCalibratedRed:0.5
						green:0.5
						 blue:1
						alpha:1];
  [pledit_selectedbg retain];
  */

  {
    NSString *path;
    
    path = [[NSBundle mainBundle] 
	     pathForResource:@"viscolor" 
	     ofType:@"txt"];
  
    if ( [self load_skin_viscolor:[path stringByDeletingLastPathComponent]
	       :@"viscolor.txt"] == NO )
      {
	for(i=0;i<24;i++)
	  {
	    vis_color[i][0] = skin_default_viscolor[i][0];
	    vis_color[i][1] = skin_default_viscolor[i][1];
	    vis_color[i][2] = skin_default_viscolor[i][2];
	  }
      }
  }

  return [self init];
}

- init
{
  return [super init];
}



- initWithFile:(NSString *)fileName 
{
  NSString *tempdir = nil;

  if ( defaultSkin == nil )
    defaultSkin = [[Skin alloc] initDefault];

  skinPath = [fileName retain];
	
  if( fileName ) {
    NSString *ext = [fileName pathExtension];

    if ( ext && [ext length]  ) {
      NSString *unzip, *tar, *command = nil;
      NSMutableArray *args = [NSMutableArray array];
      NSTask *task;

      tempdir = NSTemporaryDirectory();

      //FIXME: need a better tmp dir
      tempdir = [tempdir stringByAppendingPathComponent:getPackageName()];
      [[NSFileManager defaultManager] 
	createDirectoryAtPath:tempdir attributes:nil];

      unzip = [[NSUserDefaults standardUserDefaults] 
		stringForKey:@"Unzipcmd"];
      if( unzip == 0 )
	unzip = @"unzip";

      tar = [[NSUserDefaults standardUserDefaults]
	      stringForKey:@"Tarcmd"];
      if( tar == 0 ) 
	tar = @"tar";

	
      
      ext = [ext lowercaseString];
      
      if ([ext caseInsensitiveCompare:@".zip"] 
	  || [ext caseInsensitiveCompare:@".wsz"] )
	{
	  command = [NSString stringWithFormat:@"%@ -o -j %@ -d %@",
			      unzip, fileName, tempdir];
	}
      

      if ( [ext isEqualToString:@".tgz"] || [ext isEqualToString:@".gz"] ) {
	command = [NSString stringWithFormat:@"%@ xzf %@ -C %@",
		    tar, fileName, tempdir];
      }
      
      if ( [ext isEqualToString:@".bz2"] ) {
	command = [NSString stringWithFormat:@"%@ xIf %@ -C %@",
		    tar, fileName, tempdir];
      }

      if ( [ext isEqualToString:@".tar"] ) {
	command = [NSString stringWithFormat:@"%@ xf %@ -C %@",
		    tar, fileName, tempdir];
      }

      if ( command == nil ) {
	NSLog(@"unknown skin package");
	return nil;
      }

      command = [command stringByAppendingString:@" > /dev/null"];

      command = [@"/usr/bin" stringByAppendingPathComponent:command];
      [args addObject:@"-c"];
      [args addObject:command];
      task = [NSTask launchedTaskWithLaunchPath:@"/bin/sh" 
				      arguments:args];
      [task waitUntilExit];

      if ( [task terminationStatus] != 0 ) {
	NSLog(@"'%@' failed", command);
	return nil;
      }

      fileName = tempdir;
    }
  
    main = load_skin_image(fileName, @"main.bmp");
    cbuttons = load_skin_image(fileName, @"cbuttons.bmp");
    titlebar = load_skin_image(fileName, @"titlebar.bmp");
    shufrep = load_skin_image(fileName, @"shufrep.bmp");
    text = load_skin_image(fileName, @"text.bmp");
    volume = load_skin_image(fileName, @"volume.bmp");
    balance = load_skin_image(fileName, @"balance.bmp");
    monostereo = load_skin_image(fileName, @"monoster.bmp");
    playpause = load_skin_image(fileName, @"playpaus.bmp");
    numbers = load_skin_image(fileName, @"nums_ex.bmp");
    if( numbers == 0 ) 
      numbers = load_skin_image(fileName, @"numbers.bmp");
    posbar = load_skin_image(fileName, @"posbar.bmp");
    pledit = load_skin_image(fileName, @"pledit.bmp");
    eqmain = load_skin_image(fileName, @"eqmain.bmp");
    eq_ex = load_skin_image(fileName, @"eq_ex.bmp");
    pledit_normal = load_skin_color(fileName, @"pledit.txt", "text", "normal");
    pledit_current = load_skin_color(fileName, @"pledit.txt","text","current");
    pledit_normalbg = load_skin_color(fileName,@"pledit.txt","text","normalbg");
    pledit_selectedbg = load_skin_color(fileName,@"pledit.txt","text",
					"selectedbg");

#if 0
    mask_main = skin_create_transparent_mask(fileName,"region.txt","Normal",mainwin->window,275,116,FALSE);
    mask_main_ds=skin_create_transparent_mask(fileName,"region.txt","Normal",mainwin->window,550,232,TRUE);
    skin->mask_eq=skin_create_transparent_mask(fileName,"region.txt","Equalizer",equalizerwin->window,275,116,FALSE);
    skin->mask_eq_ds=skin_create_transparent_mask(fileName,"region.txt","Equalizer",equalizerwin->window,550,232,TRUE);
    skin->mask_shade=skin_create_transparent_mask(fileName,"region.txt","WindowShade",mainwin->window,275,14,FALSE);
    skin->mask_shade_ds=skin_create_transparent_mask(fileName,"region.txt","WindowShade",mainwin->window,550,28,TRUE);
#endif

    if ( [self load_skin_viscolor:fileName :@"viscolor.txt"] == NO )
      [self load_skin_viscolor:fileName :@"VISCOLOR.TXT"];

    if ( tempdir ) {
      NSArray *rmargs;
      NSTask *task;
      NSString *rmcom;
      rmcom = [NSString stringWithFormat:@"rm -rf %@", tempdir];
      rmargs = [NSArray arrayWithObjects:@"-c", rmcom, nil];
      task = [NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:rmargs];
      [task waitUntilExit];

      if ( [task terminationStatus] != 0 ) {
	NSLog(@"could not remove temp dir: %@", tempdir);
      }
    }
  }
  
  return [self init];
}


- (BOOL)load_skin_viscolor:(NSString *)path  :(NSString *)file
{
  FILE *f;
  int i;
  char line[256];
  NSString *filename;
	
  for(i=0;i<24;i++)
    {
      vis_color[i][0] = skin_default_viscolor[i][0];
      vis_color[i][1] = skin_default_viscolor[i][1];
      vis_color[i][2] = skin_default_viscolor[i][2];
    }
	
  filename = [path stringByAppendingPathComponent:file];
  if ( [[NSFileManager defaultManager] fileExistsAtPath:filename] ) {
    if(f=fopen([filename fileSystemRepresentation],"r")) {
      for( i = 0; i < 24; i++ ) {
	if(fgets(line,255,f)) {
	  int r, g, b;
	  sscanf(line, "%d,%d,%d", &r, &g, &b);

	  vis_color[i][0] = r;
	  vis_color[i][1] = g;
	  vis_color[i][2] = b;
	}
	else
	  break;				
      }
      fclose(f);
      return YES;
    }
  }
  return NO;
}
 

- (NSImage *)main
{
  if ( main == nil && self != defaultSkin )
    return [defaultSkin main];
  return main;
}

- (NSImage *)cbuttons
{
  if ( cbuttons == nil && self != defaultSkin )
    return [defaultSkin cbuttons];
  return cbuttons;
}

- (NSImage *)titlebar
{
  if ( titlebar == nil && self != defaultSkin )
    return [defaultSkin titlebar];
  return titlebar;
}

- (NSImage *)shufrep
{
  if ( shufrep == nil && self != defaultSkin )
    return [defaultSkin shufrep];
  return shufrep;
}

- (NSImage *)text
{
  if ( text == nil && self != defaultSkin )
    return [defaultSkin text];
  return text;
}

- (NSImage *)volume
{
  if ( volume == nil && self != defaultSkin )
    return [defaultSkin volume];
  return volume;
}

- (NSImage *)balance
{
  if ( balance == nil ) 
    {
      if ( skinPath == nil && self != defaultSkin )
	return [defaultSkin balance];
      return [self volume];
    }
  return balance;
}

- (NSImage *)monostereo
{
  if ( monostereo == nil && self != defaultSkin )
    return [defaultSkin monostereo];
  return monostereo;
}

- (NSImage *)playpause
{
  if ( playpause == nil && self != defaultSkin )
    return [defaultSkin playpause];
  return playpause;
}

- (NSImage *)numbers
{
  if ( numbers == nil && self != defaultSkin )
    return [defaultSkin numbers];
  return numbers;
}

- (NSImage *)posbar
{
  if ( posbar == nil && self != defaultSkin )
    return [defaultSkin posbar];
  return posbar;
}

- (NSImage *)pledit
{
  if ( pledit == nil && self != defaultSkin )
    return [defaultSkin pledit];
  return pledit;
}

- (NSImage *)eqmain
{
  if ( eqmain == nil && self != defaultSkin )
    return [defaultSkin eqmain];
  return eqmain;
}

- (NSImage *)eq_ex
{
  if ( eq_ex == nil && self != defaultSkin )
    return [defaultSkin eq_ex];
  return eq_ex;
}

- (NSColor *)pledit_normal
{
  if ( pledit_normal == nil && self != defaultSkin )
    return [defaultSkin pledit_normal];
  return pledit_normal;
}

- (NSColor *)pledit_current
{
  if ( pledit_current == nil && self != defaultSkin )
    return [defaultSkin pledit_current];
  return pledit_current;
}

- (NSColor *)pledit_normalbg
{
  if ( pledit_normalbg == nil && self != defaultSkin )
    return [defaultSkin pledit_normalbg];
  return pledit_normalbg;
}

- (NSColor *)pledit_selectedbg
{
  if ( pledit_selectedbg == nil && self != defaultSkin )
    return [defaultSkin pledit_selectedbg];
  return pledit_selectedbg;
}

@end

NSString *find_file_recursively(NSString *dirname, NSString *file) 
{
  NSString *result;
  NSDirectoryEnumerator *de;
  NSString *entry;
  NSDictionary *attrs;

  de = [[NSFileManager defaultManager] enumeratorAtPath:dirname];
  
  while ( entry = [de nextObject] ) {
    attrs = [de fileAttributes];
    if ( [attrs fileType] == NSFileTypeDirectory ) {
      result = find_file_recursively([dirname stringByAppendingPathComponent:
				       entry], file);
      if(result != nil) 
	return result;
    } else if ( [entry caseInsensitiveCompare:file] == NSOrderedSame ) 
      return [dirname stringByAppendingPathComponent:entry];
  }
  
  return nil;
}
 
 
