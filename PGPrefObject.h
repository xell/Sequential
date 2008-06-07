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

extern NSString *const PGPrefObjectShowsOnScreenDisplayDidChangeNotification;
extern NSString *const PGPrefObjectReadingDirectionDidChangeNotification;
extern NSString *const PGPrefObjectImageScaleDidChangeNotification;
extern NSString *const PGPrefObjectUpscalesToFitScreenDidChangeNotification;
extern NSString *const PGPrefObjectSortOrderDidChangeNotification;

enum {
	PGNoPattern           = 0,
	PGCheckerboardPattern = 1
};
typedef int PGPatternType;

enum {
	PGReadingDirectionLeftToRight = 0,
	PGReadingDirectionRightToLeft = 1
};
typedef int PGReadingDirection;

enum {
	PGConstantFactorScaling        = 0, // Formerly known as PGNoScaling.
	PGAutomaticScaling             = 1,
	PGDeprecatedVerticalFitScaling = 2, // Deprecated after 1.0.3.
	PGViewFitScaling               = 3  // Fits the entire image inside the screen/window.
};
typedef int PGImageScalingMode;

enum {
	PGDownscale   = -1,
	PGScaleFreely = 0,
	PGUpscale     = 1
};
typedef int PGImageScalingConstraint;

enum {
	PGUnsorted           = 0,
	PGSortOrderMask      = 0x0000FFFF,
	PGSortByName         = 1,
	PGSortByDateModified = 2,
	PGSortByDateCreated  = 3,
	PGSortBySize         = 4,
	PGSortShuffle        = 100,
	PGSortOptionsMask    = 0x7FFF0000,
	PGSortDescendingMask = 1 << 16,
	PGSortRepeatMask     = 1 << 17,
};
typedef int PGSortOrder;

#define PGValueOrDefault(val, default) ({ __typeof__(val) __val = (val); __val ? __val : (default); })
#define PGValueWithSelectorOrDefault(val, msg, default) ({ id __val = (val); __val ? [__val msg] : (default); })

@interface PGPrefObject : NSObject
{
	@private
	BOOL                     _showsOnScreenDisplay;
	PGReadingDirection       _readingDirection;
	PGImageScalingMode       _imageScalingMode;
	float                    _imageScaleFactor;
	PGImageScalingConstraint _imageScalingConstraint;
	PGSortOrder              _sortOrder;
}

+ (id)globalPrefObject;

- (BOOL)showsOnScreenDisplay;
- (void)setShowsOnScreenDisplay:(BOOL)flag;

- (PGReadingDirection)readingDirection;
- (void)setReadingDirection:(PGReadingDirection)aDirection;

- (PGImageScalingMode)imageScalingMode;
- (void)setImageScalingMode:(PGImageScalingMode)aMode;
- (float)imageScaleFactor;
- (void)setImageScaleFactor:(float)aFloat;
- (PGImageScalingConstraint)imageScalingConstraint;
- (void)setImageScalingConstraint:(PGImageScalingConstraint)flag;

- (PGSortOrder)sortOrder;
- (void)setSortOrder:(PGSortOrder)anOrder;

@end