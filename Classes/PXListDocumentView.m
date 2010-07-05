//
//  PXListDocumentView.m
//  PXListView
//
//  Created by Alex Rozanski on 29/05/2010.
//  Copyright 2010 Alex Rozanski. http://perspx.com. All rights reserved.
//

#import "PXListDocumentView.h"

#import "PXListView.h"

@implementation PXListDocumentView

@synthesize listView;

- (BOOL)isFlipped
{
	return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[[self listView] deselectRows];
}

@end
