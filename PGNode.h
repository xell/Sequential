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
#import <Cocoa/Cocoa.h>
#import "PGResourceAdapting.h"

// Models
@class PGDocument;
@class PGResourceAdapter;
@class PGContainerAdapter;
@class PGResourceIdentifier;

extern NSString *const PGNodeLoadingDidProgressNotification;
extern NSString *const PGNodeReadyForViewingNotification;

extern NSString *const PGImageKey;
extern NSString *const PGErrorKey;

extern NSString *const PGNodeErrorDomain;
enum {
	PGGenericError  = 1,
	PGPasswordError = 2,
	PGEncodingError = 3
};

@interface PGNode : NSObject
{
	@private
	BOOL                  _loaded;
	PGContainerAdapter   *_parentAdapter;
	PGDocument           *_document;
	PGResourceIdentifier *_identifier;
	id                    _dataSource;
	NSMenuItem           *_menuItem;
	BOOL                  _isViewable;
	NSString             *_lastPassword;
	BOOL                  _expectsReturnedImage;
	PGResourceAdapter    *_resourceAdapter;
	NSDate               *_dateModified;
	NSDate               *_dateCreated;
	NSNumber             *_dataLength;
}

- (id)initWithParentAdapter:(PGContainerAdapter *)parent document:(PGDocument *)doc identifier:(PGResourceIdentifier *)ident adapterClass:(Class)class dataSource:(id)source load:(BOOL)flag;

- (unsigned)depth;
- (BOOL)isRooted;
- (NSMenuItem *)menuItem;
- (void)setIsViewable:(BOOL)flag;
- (void)becomeViewed;
- (void)becomeViewedWithPassword:(NSString *)pass;

- (PGResourceAdapter *)resourceAdapter;
- (PGResourceAdapter *)setResourceAdapter:(PGResourceAdapter *)adapter; // If it changes, returns -resourceAdapter, otherwise nil.
- (PGResourceAdapter *)setResourceAdapterClass:(Class)aClass;

- (void)removeFromDocument;

- (void)setDateModified:(NSDate *)aDate;
- (void)setDateCreated:(NSDate *)aDate;
- (void)setDataLength:(NSNumber *)aNumber;
- (NSComparisonResult)compare:(PGNode *)node; // Uses the document's sort mode.

- (void)identifierDidChange:(NSNotification *)aNotif;
- (void)fileEventDidOccur:(NSNotification *)aNotif;

@end

@interface PGNode (PGResourceAdapterProxy) <PGResourceAdapting>
@end