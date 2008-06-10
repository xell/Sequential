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
@class PGNode;

enum {
	PGReadToMaxDepth = 0,
	PGReadAll        = 1,
	PGReadNone       = 2
};
typedef int PGReadingPolicy;

@interface PGResourceAdapter : NSObject <PGResourceAdapting>
{
	@private
	PGNode   *_node;
	unsigned  _determiningTypeCount;
	BOOL      _isImage;
	BOOL      _needsPassword;
	BOOL      _needsEncoding;
	NSData   *_data;
	BOOL      _hasReadContents;
}

+ (BOOL)alwaysReads;

- (PGNode *)node;
- (void)setNode:(PGNode *)aNode;

- (BOOL)isDeterminingType;
- (BOOL)isImage;
- (BOOL)needsPassword;
- (BOOL)needsEncoding;
- (void)setIsDeterminingType:(BOOL)flag;
- (void)setIsImage:(BOOL)flag;
- (void)setNeedsPassword:(BOOL)flag;
- (void)setNeedsEncoding:(BOOL)flag;
- (void)noteIsViewableDidChange;

- (void)setData:(NSData *)data;
- (void)loadFromData:(NSData *)data URLResponse:(NSURLResponse *)response;
- (Class)classWithURLResponse:(NSURLResponse *)response;
- (void)replacedWithAdapter:(PGResourceAdapter *)newAdapter;
- (PGReadingPolicy)descendentReadingPolicy; // Return MAX(prefferedValue, [self readingPolicy]).
- (PGReadingPolicy)readingPolicy; // Returns the parent adapter's or the default.
- (BOOL)shouldRead:(BOOL)asAlways; // If 'asAlways', returns YES immediately if the class -alwaysReads. Otherwise looks at the -readingPolicy.
- (void)readWithURLResponse:(NSURLResponse *)response; // Abstract method. Perform an initial read. PGContainerAdapters should create any child nodes here if possible. This gets called for every node created when the document is first opened, so defer anything slow to -readContents. -lastPassword won't be set yet.

- (BOOL)shouldReadContents;
- (void)setHasReadContents;
- (void)readContents; // Abstract method. Sent by -becomeViewed and -becomeViewedWithPassword:. -lastPassword may be set--you can send -readFromData:URLResponse: if you need to defer loading until a password is set. If -[node expectsReturnedImage], should send -setHasReadContents and then -returnImage:error must be sent sometime thereafter.

- (void)noteDateModifiedDidChange;
- (void)noteDateCreatedDidChange;
- (void)noteDataLengthDidChange;

- (void)noteResourceDidChange;

@end

@interface NSObject (PGResourceAdapterDataSource)

- (NSDate *)dateModifiedForResourceAdapter:(PGResourceAdapter *)sender;
- (NSDate *)dateCreatedForResourceAdapter:(PGResourceAdapter *)sender;
- (NSNumber *)dataLengthForResourceAdapter:(PGResourceAdapter *)sender;
- (NSData *)dataForResourceAdapter:(PGResourceAdapter *)sender; // If a password is required, sends -lastPassword, then sends -setNeedsPassword: with whether the password worked.

@end
