//
//  PXListDocumentView.m
//  PXListView
//
//  Created by Alex Rozanski on 29/05/2010.
//  Copyright 2010 Alex Rozanski. http://perspx.com. All rights reserved.
//

#import "PXListDocumentView.h"

#import "PXListView.h"
#import "PXListView+Private.h"

@implementation PXListDocumentView

@synthesize listView = _listView;
@synthesize showsDropHighlight = _showsDropHighlight;

- (BOOL)isFlipped
{
	return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[[self listView] handleMouseDownOutsideCells: theEvent];
}


-(void)	drawRect: (NSRect)dirtyRect
{
#pragma unused(dirtyRect)
	if( _showsDropHighlight )
	{
		CGFloat		lineWidth = 2.0f;
		CGFloat		lineWidthHalf = lineWidth / 2.0f;
		
		[[NSColor selectedControlColor] set];
		[NSBezierPath setDefaultLineWidth: lineWidth];
		[NSBezierPath strokeRect: NSInsetRect([self visibleRect], lineWidthHalf, lineWidthHalf)];
	}
}

-(void)	setShowsDropHighlight:(BOOL)inState
{
	_showsDropHighlight = inState;
	[self setNeedsDisplayInRect: [self visibleRect]];
}

@end
