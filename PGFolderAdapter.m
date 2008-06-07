/* Copyright © 2007-2008 Ben Trask. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal with the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:
1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimers.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimers in the
   documentation and/or other materials provided with the distribution.
3. The names of its contributors may not be used to endorse or promote
   products derived from this Software without specific prior written
   permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
THE CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS WITH THE SOFTWARE. */
#import "PGFolderAdapter.h"
#import <sys/event.h>

// Models
#import "PGNode.h"
#import "PGResourceIdentifier.h"

// Categories
#import "NSStringAdditions.h"

@implementation PGFolderAdapter

#pragma mark PGResourceAdapter

- (void)readWithURLResponse:(NSURLResponse *)response
{
	NSParameterAssert(!response);
	NSParameterAssert([self shouldRead:YES]);
	NSParameterAssert(![self canGetData]);
	NSMutableArray *const oldPages = [[[self unsortedChildren] mutableCopy] autorelease];
	NSMutableArray *const newPages = [NSMutableArray array];
	NSURL *const URL = [[self identifier] URLByFollowingAliases:YES];
	LSItemInfoRecord info;
	if(LSCopyItemInfoForURL((CFURLRef)URL, kLSRequestBasicFlagsOnly, &info) != noErr || info.flags & kLSItemInfoIsPackage) return; // Don't go into packages.
	NSString *const path = [URL path];
	NSString *pathComponent;
	NSEnumerator *const pathComponentEnum = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];
	while((pathComponent = [pathComponentEnum nextObject])) {
		NSString *const pagePath = [path stringByAppendingPathComponent:pathComponent];
		static NSArray *ignoredPaths = nil;
		if(!ignoredPaths) ignoredPaths = [[NSArray alloc] initWithObjects:@"/net", @"/etc", @"/home", @"/tmp", @"/var", nil];
		if([ignoredPaths containsObject:pagePath]) continue;
		NSURL *const pageURL = [pagePath AE_fileURL];
		if(LSCopyItemInfoForURL((CFURLRef)pageURL, kLSRequestBasicFlagsOnly, &info) != noErr || info.flags & kLSItemInfoIsInvisible) continue;
		PGNode *node = [self childForURL:pageURL];
		if(node) [oldPages removeObjectIdenticalTo:node];
		else node = [[[PGNode alloc] initWithParentAdapter:self document:nil identifier:[PGResourceIdentifier resourceIdentifierWithURL:pageURL] adapterClass:nil dataSource:nil load:YES] autorelease];
		if(node) [newPages addObject:node];
	}
	[self setUnsortedChildren:newPages presortedOrder:PGUnsorted];
	if([self shouldReadContents]) [self readContents];
}
- (void)fileResourceDidChange:(unsigned)flags
{
	NSLog(@"folder did change flags %u", flags);
	if(flags & (NOTE_DELETE | NOTE_REVOKE)) return [[self node] removeFromDocument];
	if(flags & NOTE_WRITE && [self shouldRead:YES]) [self readWithURLResponse:nil];
	[super fileResourceDidChange:flags];
}

@end