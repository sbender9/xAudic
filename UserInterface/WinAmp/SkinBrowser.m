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
#import "SkinBrowser.h"
#import "Skin.h"
#import "Configure.h"

@implementation SkinBrowser

- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column
{
  if ( column == 0 )
    return [skinFileNames count]+1;
  return 0;
}

- (void)browser:(NSBrowser *)sender 
willDisplayCell:(id)cell 
	  atRow:(int)row 
	 column:(int)column
{
  NSString *val;
  
  if ( row == 0 )
    val = @"(none)";
  else {
    val = [skinFileNames objectAtIndex:row-1];
    val = [[val lastPathComponent] stringByDeletingPathExtension];
  }
    
  [cell setStringValue:val];
  [cell setLeaf:YES];
}

- (void)browserAction:sender
{
  NSString *fileName;
  int row;
  
  row = [browser selectedRowInColumn:0];
  
  if ( row == 0 )
    fileName = @"(none)";
  else
    fileName = [skinFileNames objectAtIndex:row-1];
  [Skin loadSkin:fileName];
  [WinAmpConfigure setSkinFileName:fileName];
}

- (BOOL) shouldAddSkinFilenameToSkins:(NSString*)filename
{
  // Returns NO if we start with a "." or filename
  // is CVS (this shows up when I'm running my debug
  // copy). This method should really take the path
  // of the filename too so it could check whether filename
  // is a directory or a plain file too.
  BOOL shouldAdd = YES;

  if (filename == nil ||
      [filename length] == 0 ||
      [filename hasPrefix:@"."] ||
      [filename isEqualToString:@"CVS"]) {
    shouldAdd = NO;
  }

  return shouldAdd;
}

- (void)listSkinsAtPath:(NSString *)path
{
  NSArray *skins;
  int i;
  
  skins = [[NSFileManager defaultManager] directoryContentsAtPath:path];

  for ( i = 0; i < [skins count]; i++ ) {
    NSString *skinFilename = [skins objectAtIndex:i];
    if ([self shouldAddSkinFilenameToSkins:skinFilename]) {
      NSString *skinPath = [path stringByAppendingPathComponent:skinFilename];
      [skinFileNames addObject:skinPath];
    }   
  }
}

- (void)listSkins
{
  NSArray *searchPath;
  int i;

  [skinFileNames release];
  skinFileNames = [[NSMutableArray array] retain];
  
  searchPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, 
						   NSAllDomainsMask, YES);

  [self listSkinsAtPath:[[[NSBundle mainBundle] resourcePath] 
	stringByAppendingPathComponent:@"Skins"]];

  for ( i = 0; i < [searchPath count]; i++ ) {
    [self listSkinsAtPath:[[[searchPath objectAtIndex:i] 
		       stringByAppendingPathComponent:getPackageName()]
		       stringByAppendingPathComponent:@"Skins"]];
  }
}


- (void)close:sender
{
  [window orderOut:sender];
}

- (void)show:sender
{
  [self listSkins];
  [super show:sender];
}

@end
