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
#import "NSDateAdditions.h"

@implementation NSDate (AEAdditions)

+ (NSString *)AE_localizedStringFromTimeInterval:(NSTimeInterval)interval
{
	unsigned const hours = floor(interval / (60 * 60));
	if(hours) return 1 == hours ? NSLocalizedString(@"1 hour", nil) : [NSString stringWithFormat:NSLocalizedString(@"%u hours", nil), hours];
	unsigned const minutes = floor(((unsigned)interval % (60 * 60)) / 60.0);
	if(minutes) return 1 == minutes ? NSLocalizedString(@"1 minute", nil) : [NSString stringWithFormat:NSLocalizedString(@"%u minutes", nil), minutes];
	unsigned const seconds = (unsigned)ceil(interval) % 60;
	return 1 == seconds ? NSLocalizedString(@"1 second", nil) : [NSString stringWithFormat:NSLocalizedString(@"%u seconds", nil), seconds];
}
- (NSString *)AE_localizedStringWithDateStyle:(CFDateFormatterStyle)dateStyle
              timeStyle:(CFDateFormatterStyle)timeStyle
{
	static CFDateFormatterRef f = nil;
	if(!f || CFDateFormatterGetDateStyle(f) != dateStyle || CFDateFormatterGetTimeStyle(f) != timeStyle) {
		if(f) {
			CFRelease(CFDateFormatterGetLocale(f));
			CFRelease(f);
		}
		f = CFDateFormatterCreate(kCFAllocatorDefault, CFLocaleCopyCurrent(), dateStyle, timeStyle);
	}
	return [(NSString *)CFDateFormatterCreateStringWithDate(kCFAllocatorDefault, f, (CFDateRef)self) autorelease];
}

@end