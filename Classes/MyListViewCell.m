//
//  MyListViewCell.m
//  PXListView
//
//  Created by Alex Rozanski on 29/05/2010.
//  Copyright 2010 Alex Rozanski. http://perspx.com. All rights reserved.
//

#import "MyListViewCell.h"


@implementation MyListViewCell

#pragma mark -
#pragma mark Init/Dealloc

- (id)initWithReusableIdentifier:(NSString*)identifier
{
	if(self = [super initWithReusableIdentifier:identifier]) {
		titleLabel = [[NSTextField alloc] initWithFrame:[self frame]];
		[titleLabel setStringValue:@"Hello"];
		[titleLabel setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
		[self addSubview:titleLabel];
		[titleLabel release];
	}
	
	return self;
}

- (void)dealloc
{
	[titleLabel removeFromSuperview];
	[super dealloc];
}

@end
