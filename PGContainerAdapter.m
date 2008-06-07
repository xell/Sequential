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
#import "PGContainerAdapter.h"

// Models
#import "PGDocument.h"
#import "PGNode.h"
#import "PGResourceIdentifier.h"

NSString *const PGMaxDepthKey = @"PGMaxDepth";

@interface PGContainerAdapter (Private)

- (PGNode *)_nodeForSelectorOrSelfIfViewable:(SEL)sel forward:(BOOL)flag;

@end

@implementation PGContainerAdapter

#pragma mark PGResourceAdapter

+ (BOOL)alwaysReads
{
	return NO;
}

#pragma mark Instance Methods

- (NSArray *)sortedChildren
{
	if(!_sortedChildren) {
		PGSortOrder const order = [[self document] sortOrder];
		_sortedChildren = [(order == _unsortedOrder ? _unsortedChildren : [_unsortedChildren sortedArrayUsingSelector:@selector(compare:)]) retain];
	}
	return [[_sortedChildren retain] autorelease];
}
- (NSArray *)unsortedChildren
{
	return [[_unsortedChildren retain] autorelease];
}
- (void)setUnsortedChildren:(NSArray *)anArray
        presortedOrder:(PGSortOrder)anOrder
{
	if(anArray == _unsortedChildren) return;
	[_unsortedChildren release];
	_unsortedChildren = [anArray copy];
	_unsortedOrder = anOrder;
	NSArray *const oldSortedChildren = [self sortedChildren];
	[_sortedChildren release];
	_sortedChildren = nil;
	[[[self node] menuItem] setSubmenu:([[self unsortedChildren] count] ? [[[NSMenu alloc] init] autorelease] : nil)];
	[[self document] noteSortedChildrenOfNodeDidChange:[self node] oldSortedChildren:oldSortedChildren];
}
- (void)removeChild:(PGNode *)node
{
	NSMutableArray *const unsortedChildren = [[_unsortedChildren mutableCopy] autorelease];
	[unsortedChildren removeObjectIdenticalTo:node];
	[self setUnsortedChildren:unsortedChildren presortedOrder:_unsortedOrder];
}

#pragma mark -

- (PGNode *)childForURL:(NSURL *)aURL
{
	PGNode *child;
	NSEnumerator *const childEnum = [_unsortedChildren objectEnumerator];
	while((child = [childEnum nextObject])) if([aURL isEqual:[[child identifier] URLByFollowingAliases:YES]]) return child;
	return nil;
}
- (unsigned)viewableIndexOfChild:(PGNode *)aNode
{
	unsigned index = 0;
	id child;
	NSEnumerator *const childEnum = [[self sortedChildren] objectEnumerator];
	while((child = [childEnum nextObject])) {
		if(child == aNode) return index + [[self parentAdapter] viewableIndexOfChild:[self node]];
		index += [child viewableNodeCount];
	}
	return 0;
}
- (PGNode *)outwardSearchForward:(BOOL)flag
            fromChild:(PGNode *)start
            withSelector:(SEL)sel
            context:(id)context
{
	NSArray *const children = [self sortedChildren];
	int i = [children indexOfObjectIdenticalTo:start];
	NSParameterAssert(NSNotFound != i);
	int const max = [children count], increment = flag ? 1 : -1;
	for(i += increment; i >= 0 && i < max; i += increment) {
		PGNode *const child = [children objectAtIndex:i];
		PGNode *const node = [child methodForSelector:sel](child, sel, flag, context);
		if(node) return node;
	}
	return [[self parentAdapter] outwardSearchForward:flag fromChild:[self node] withSelector:sel context:context];
}
- (void)noteChild:(PGNode *)child
        didChangeForSortOrder:(PGSortOrder)order
{
	if([_unsortedChildren indexOfObjectIdenticalTo:child] == NSNotFound) return;
	if((PGSortOrderMask & order) != (PGSortOrderMask & [[self document] sortOrder])) return;
	[_sortedChildren release];
	_sortedChildren = nil;
	[[self document] noteSortedChildrenOfNodeDidChange:[self node] oldSortedChildren:nil];
}

#pragma mark PGResourceAdapting Protocol

- (PGContainerAdapter *)containerAdapter
{
	return self;
}
- (PGContainerAdapter *)rootContainerAdapter
{
	return [self parentAdapter] ? [[self parentAdapter] rootContainerAdapter] : self;
}

#pragma mark -

- (BOOL)isContainer
{
	return YES;
}
- (void)setNode:(PGNode *)aNode
{
	[[[self node] menuItem] setSubmenu:nil];
	[super setNode:aNode];
	[[[self node] menuItem] setSubmenu:([[self unsortedChildren] count] ? [[[NSMenu alloc] init] autorelease] : nil)];
}

#pragma mark -

- (BOOL)hasViewableNodes
{
	if([self isViewable]) return YES;
	PGNode *child;
	NSEnumerator *const childEnum = [[self unsortedChildren] objectEnumerator];
	while((child = [childEnum nextObject])) if([[child resourceAdapter] hasViewableNodes]) return YES;
	return NO;
}
- (BOOL)hasDataNodes
{
	if([self canGetData]) return YES;
	PGNode *child;
	NSEnumerator *const childEnum = [[self unsortedChildren] objectEnumerator];
	while((child = [childEnum nextObject])) if([[child resourceAdapter] hasDataNodes]) return YES;
	return NO;
}
- (unsigned)viewableNodeCount
{
	if([self isViewable]) return 1;
	unsigned count = 0;
	PGNode *child;
	NSEnumerator *const childEnum = [[self unsortedChildren] objectEnumerator];
	while((child = [childEnum nextObject])) count += [[child resourceAdapter] viewableNodeCount];
	return count;
}

#pragma mark -

- (PGNode *)sortedViewableNodeFirst:(BOOL)flag
            stopAtNode:(PGNode *)descendent
{
	if(descendent == [self node]) return nil;
	PGNode *child = flag ? [super sortedViewableNodeFirst:YES stopAtNode:descendent] : nil;
	if(child) return child;
	NSArray *const children = [self sortedChildren];
	NSEnumerator *const childEnum = flag ? [children objectEnumerator] : [children reverseObjectEnumerator];
	while((child = [childEnum nextObject])) {
		PGNode *const node = [child sortedViewableNodeFirst:flag stopAtNode:descendent];
		if(node) return node;
		if([descendent ancestorThatIsChildOfNode:[self node]] == child) return nil;
	}
	return flag ? nil : [super sortedViewableNodeFirst:NO stopAtNode:descendent];
}
- (PGNode *)sortedFirstViewableNodeInFolderFirst:(BOOL)flag
{
	if(flag) return [self sortedViewableNodeFirst:YES];
	PGNode *child;
	NSArray *const children = [self sortedChildren];
	NSEnumerator *childEnum = [children reverseObjectEnumerator];
	while((child = [childEnum nextObject])) {
		PGNode *const node = [child sortedFirstViewableNodeInFolderFirst:flag];
		if(node) return node;
	}
	childEnum = [children objectEnumerator];
	while((child = [childEnum nextObject])) if([child isViewable]) return child;
	return nil;
}
- (PGNode *)sortedViewableNodeFirst:(BOOL)flag
            matchSearchTerms:(NSArray *)terms
            stopAtNode:(PGNode *)descendent
{
	if(descendent == [self node]) return nil;
	PGNode *child = flag ? [super sortedViewableNodeFirst:YES matchSearchTerms:terms stopAtNode:descendent] : nil;
	if(child) return child;
	NSArray *const children = [self sortedChildren];
	NSEnumerator *const childEnum = flag ? [children objectEnumerator] : [children reverseObjectEnumerator];
	while((child = [childEnum nextObject])) {
		PGNode *const node = [child sortedViewableNodeFirst:flag matchSearchTerms:terms stopAtNode:descendent];
		if(node) return node;
		if([descendent ancestorThatIsChildOfNode:[self node]] == child) return nil;
	}
	return flag ? nil : [super sortedViewableNodeFirst:NO matchSearchTerms:terms stopAtNode:descendent];
}

#pragma mark -

- (PGNode *)nodeForIdentifier:(PGResourceIdentifier *)ident
{
	if(!ident) return nil;
	PGNode *child;
	NSEnumerator *const childEnum = [_unsortedChildren objectEnumerator];
	while((child = [childEnum nextObject])) {
		PGNode *const node = [[child resourceAdapter] nodeForIdentifier:ident];
		if(node) return node;
	}
	return [super nodeForIdentifier:ident];
}
- (void)addMenuItemsToMenu:(NSMenu *)aMenu
{
	NSMenu *menu;
	if([self parentNode]) {
		[super addMenuItemsToMenu:aMenu];
		menu = [[[self node] menuItem] submenu];
	} else {
		menu = aMenu;
	}
	PGNode *child;
	NSEnumerator *const childEnum = [[self sortedChildren] objectEnumerator];
	while((child = [childEnum nextObject])) [child addMenuItemsToMenu:menu];
}
- (void)sortOrderDidChange
{
	[_sortedChildren release];
	_sortedChildren = nil;
	PGNode *child;
	NSEnumerator *childEnum = [_unsortedChildren objectEnumerator];
	while((child = [childEnum nextObject])) [child sortOrderDidChange];
}

#pragma mark PGResourceAdapter

- (void)readContents
{
	[self setHasReadContents];
	if([self needsPassword]) [self readWithURLResponse:nil];
	NSError *error = nil;
	if([self needsPassword]) error = [NSError errorWithDomain:PGNodeErrorDomain code:PGPasswordError userInfo:nil];
	else if([self needsEncoding]) error = [NSError errorWithDomain:PGNodeErrorDomain code:PGEncodingError userInfo:nil];
	[self returnImage:nil error:error];
}

#pragma mark NSObject

- (void)dealloc
{
	[_sortedChildren release];
	[_unsortedChildren release];
	[super dealloc];
}

@end